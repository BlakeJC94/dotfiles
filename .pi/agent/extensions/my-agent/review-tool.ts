import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { join } from "node:path";
import { promisify } from "node:util";
import { Type } from "typebox";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI, ExtensionToolContext } from "@earendil-works/pi-coding-agent";

import { SPAWNED_WORKER_ENV, parseRoleSettings, readOptionalTextFile } from "./roles.ts";
import { buildReviewPrompt, getReviewState, hasCompletedMarker, type ReviewModelSettings, type ReviewState } from "./review-state.ts";

const REVIEWER_ROLE = "my-reviewer";
const ACTIVATION_TIMEOUT_MS = 30_000;
const REVIEW_TIMEOUT_MS = 120_000;
const WORK_STATE = "working";

const execFileAsync = promisify(execFile);
const REVIEW_PARAMS = Type.Object({
  action: Type.Union([Type.Literal("start"), Type.Literal("follow_up"), Type.Literal("resume")]),
  goal: Type.Optional(Type.String()),
  planSection: Type.Optional(Type.String()),
  diffScope: Type.Optional(Type.String()),
  decisions: Type.Optional(Type.String()),
  constraints: Type.Optional(Type.String()),
  checkResults: Type.Optional(Type.String()),
  revision: Type.Optional(Type.String()),
  updates: Type.Optional(Type.String()),
});

interface ReviewParams {
  action: "start" | "follow_up" | "resume";
  goal?: string;
  planSection?: string;
  diffScope?: string;
  decisions?: string;
  constraints?: string;
  checkResults?: string;
  revision?: string;
  updates?: string;
}

export function registerReviewTool(pi: ExtensionAPI): void {
  pi.registerTool({
    name: "my_agent_review",
    label: "My Agent Review",
    description:
      "Start a separate read-only reviewer agent by activating /agent reviewer, continue the same reviewer for another round, or safely resume a pending review without resending its review prompt.",
    promptSnippet: "request or resume a separate reviewer role through Herdr",
    promptGuidelines: [
      "Use my_agent_review at review boundaries with the goal, approved plan section (field-note path plus exact `##` heading), exact diff scope, decisions, constraints, and check results. The tool activates /agent reviewer before sending the review request.",
      "Use action=start for a new cycle, follow_up after fixes, and resume after an interrupted or blocked request. Never repeat a pending prompt.",
      "Stop after round 3 and report any fixes made after that review as unconfirmed.",
    ],
    parameters: REVIEW_PARAMS,
    defaultActive: false,
    async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionToolContext) {
      const input = params as ReviewParams;
      const branch = ctx.sessionManager.getBranch();
      const current = getReviewState(branch);

      if (input.action === "start") {
        if (current && current.status !== "completed") {
          return errorResult("A review cycle is already pending. Use action=resume; do not start another reviewer.", current);
        }
        const required = [
          ["goal", input.goal],
          ["planSection", input.planSection],
          ["diffScope", input.diffScope],
          ["decisions", input.decisions],
          ["constraints", input.constraints],
          ["checkResults", input.checkResults],
          ["revision", input.revision],
        ] as const;
        const missing = required.find(([, value]) => !value?.trim());
        if (missing) return errorResult(`action=start requires ${missing[0]}.`);

        const reviewerModel = await getReviewerModel(pi, ctx);
        if (!reviewerModel.ok) return errorResult(reviewerModel.error);
        const id = randomUUID();
        const state: ReviewState = {
          id,
          reviewerModel: reviewerModel.value,
          name: `my-reviewer-${id.slice(0, 8)}`,
          round: 1,
          status: "starting",
          goal: input.goal!,
          planSection: input.planSection!,
          diffScope: input.diffScope!,
          decisions: input.decisions!,
          constraints: input.constraints!,
          checkResults: input.checkResults!,
          revision: input.revision!,
          marker: completionMarker(id, 1),
        };
        persist(pi, state);
        return await startReview(pi, state, ctx);
      }

      if (!current) return errorResult("No review cycle exists on this session branch.");
      if (input.action === "resume") return await resumeReview(pi, current, ctx);
      if (current.status !== "completed") {
        return errorResult("The current round is not complete. Use action=resume; do not send another prompt.", current);
      }
      if (current.round >= 3) return errorResult("This review cycle has reached its three-round limit.", current);
      if (!input.updates?.trim() || !input.checkResults?.trim() || !input.revision?.trim()) {
        return errorResult("action=follow_up requires updates, checkResults, and revision.", current);
      }

      const next: ReviewState = {
        ...current,
        round: current.round + 1,
        status: "waiting",
        updates: input.updates,
        checkResults: input.checkResults,
        revision: input.revision,
        marker: completionMarker(current.id, current.round + 1),
        feedback: undefined,
      };
      persist(pi, next);
      return await sendReviewPrompt(pi, next);
    },
  });
}

async function getReviewerModel(
  pi: ExtensionAPI,
  ctx: ExtensionToolContext,
): Promise<{ ok: true; value: ReviewModelSettings } | { ok: false; error: string }> {
  const path = join(getAgentDir(), "my-agent.json");
  const configText = readOptionalTextFile(path);
  if (!configText.ok) return configText;

  // Without a config file, review with the active model instead of failing.
  if (configText.value === undefined) {
    const model = ctx.model;
    if (!model) return { ok: false, error: "No reviewer configuration file and no active model to review with." };
    return {
      ok: true,
      value: { provider: model.provider, model: model.id, thinkingLevel: ctx.thinkingLevel ?? pi.getThinkingLevel() },
    };
  }

  const parsed = parseRoleSettings(configText.value, "my-reviewer");
  if (!parsed.ok) return parsed;
  const model = ctx.modelRegistry.find(parsed.value.provider, parsed.value.model);
  if (!model) return { ok: false, error: `Reviewer model ${parsed.value.provider}/${parsed.value.model} is unavailable.` };
  if (!ctx.modelRegistry.hasConfiguredAuth(model)) {
    return { ok: false, error: `No configured authentication for reviewer provider ${parsed.value.provider}.` };
  }
  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok) return { ok: false, error: `Reviewer authentication failed: ${auth.error}` };
  return { ok: true, value: parsed.value };
}

async function startReview(pi: ExtensionAPI, state: ReviewState, ctx: ExtensionToolContext) {
  const callerPane = process.env.HERDR_PANE_ID;
  if (!callerPane) return startupFailure(state, "Herdr caller pane is unavailable; no reviewer was started.");

  try {
    const agents = await herdrJson(["agent", "list"]);
    if (containsAgentName(agents, state.name)) {
      return startupFailure(state, `Reviewer name ${state.name} already exists; inspect it before continuing.`);
    }
    const layout = await herdrJson(["pane", "layout", "--pane", callerPane]);
    const area = findRecord(layout, "area");
    if (typeof area?.width !== "number" || typeof area.height !== "number") {
      return startupFailure(state, "Could not determine caller pane geometry; no reviewer was started.");
    }
    const direction = area.width >= area.height ? "right" : "down";
    const split = await herdrJson([
      "pane",
      "split",
      "--pane",
      callerPane,
      "--direction",
      direction,
      "--cwd",
      ctx.cwd,
      "--no-focus",
      "--env",
      `${SPAWNED_WORKER_ENV}=${REVIEWER_ROLE}`,
    ]);
    const pane = findRecord(split, "pane");
    const paneId = pane?.pane_id;
    if (typeof paneId !== "string") return startupFailure(state, "Herdr did not return a reviewer pane id.");

    state.paneId = paneId;
    persist(pi, state);
    await herdrJson([
      "agent",
      "start",
      state.name,
      "--kind",
      "pi",
      "--pane",
      paneId,
      "--timeout",
      "30000",
      "--",
      "--model",
      `${state.reviewerModel.provider}/${state.reviewerModel.model}`,
      "--thinking",
      state.reviewerModel.thinkingLevel,
      "--tools",
      "read,grep,find,ls",
    ]);
    state.status = "activating";
    persist(pi, state);
    return await activateReviewer(pi, state);
  } catch (error) {
    return startupFailure(state, `Reviewer startup failed. Resume to reconcile before retrying: ${errorMessage(error)}`);
  }
}

async function activateReviewer(pi: ExtensionAPI, state: ReviewState) {
  try {
    // A spawned worker reports itself as working and never settles to idle, so
    // `--wait` would hang. Wait for the worker's working report instead; the role
    // command sends it after activation, which is what gates the review prompt.
    await herdrJson(["agent", "prompt", state.name, "/agent reviewer"]);
  } catch (error) {
    return errorResult(`Reviewer role activation failed. Resume to retry activation before review: ${errorMessage(error)}`, state);
  }

  const ready = await waitForReviewerWorking(state);
  if (!ready.ok) return block(pi, state, ready.error);

  state.status = "prompting";
  persist(pi, state);
  return await sendReviewPrompt(pi, state);
}

async function sendReviewPrompt(pi: ExtensionAPI, state: ReviewState) {
  try {
    await herdrJson(["agent", "prompt", state.name, buildReviewPrompt(state)]);
  } catch (error) {
    return block(pi, state, `Reviewer prompt submission failed. Resume to inspect its state; the prompt will not be resent: ${errorMessage(error)}`);
  }
  return await collectFeedback(pi, state);
}

async function resumeReview(pi: ExtensionAPI, state: ReviewState, ctx: ExtensionToolContext) {
  if (state.status === "completed") return successResult(state, state.feedback ?? "Completed feedback is unavailable.");

  if (state.status === "starting" || state.status === "activating") {
    if (!state.paneId) return block(pi, state, "Reviewer start was interrupted before its pane id was saved. Inspect Herdr manually; no second pane will be created.");
    try {
      const agents = await herdrJson(["agent", "list"]);
      if (!containsAgentName(agents, state.name)) {
        return block(pi, state, `No live reviewer named ${state.name} was found. Inspect pane ${state.paneId} before any manual recovery.`);
      }
      state.status = "activating";
      persist(pi, state);
      return await activateReviewer(pi, state);
    } catch (error) {
      return block(pi, state, `Could not reconcile reviewer startup: ${errorMessage(error)}`);
    }
  }

  // The prompt was already submitted; wait for its completion marker without resending.
  return await collectFeedback(pi, state);
}

async function collectFeedback(pi: ExtensionAPI, state: ReviewState) {
  const paneId = state.paneId;
  if (!paneId) return block(pi, state, "Reviewer pane id is unavailable; its output cannot be read.");
  const deadline = Date.now() + REVIEW_TIMEOUT_MS;
  let output = "";
  while (true) {
    try {
      // Read the pane, not the agent: a suppressed worker stays "working", and
      // agent reads refuse alternate-screen history until the agent is idle.
      output = await herdrText(["pane", "read", paneId, "--source", "recent-unwrapped", "--lines", "500"]);
    } catch (error) {
      return block(pi, state, `Reviewer output could not be read; review remains unconfirmed: ${errorMessage(error)}`);
    }
    if (state.marker && hasCompletedMarker(output, state.marker)) {
      state.status = "completed";
      state.feedback = output;
      persist(pi, state);
      return successResult(state, output);
    }
    if (Date.now() >= deadline) {
      return block(pi, state, `Reviewer did not produce its completion marker. Feedback is unconfirmed; inspect before continuing.\n${output}`);
    }
    await delay(1000);
  }
}

// A spawned worker never settles to idle, so wait for the working report the role
// command sends after activation instead of a settled-state read.
async function waitForReviewerWorking(state: ReviewState): Promise<{ ok: true } | { ok: false; error: string }> {
  const deadline = Date.now() + ACTIVATION_TIMEOUT_MS;
  let status: string | undefined;
  while (Date.now() < deadline) {
    try {
      const agent = await herdrJson(["agent", "get", state.name]);
      status = findAgentStatus(agent);
      if (status === WORK_STATE) return { ok: true };
    } catch (error) {
      return { ok: false, error: `Could not read reviewer status after activation: ${errorMessage(error)}` };
    }
    await delay(500);
  }
  return { ok: false, error: `Reviewer did not report ${WORK_STATE} after role activation (last status ${status ?? "unknown"}). Resume to retry.` };
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function herdrJson(args: string[]): Promise<unknown> {
  const { stdout } = await execFileAsync("herdr", args, { timeout: 130000, maxBuffer: 1024 * 1024 });
  const envelope: unknown = JSON.parse(stdout);
  if (!isRecord(envelope) || !("result" in envelope)) throw new Error("Herdr returned an unexpected response.");
  return envelope.result;
}

async function herdrText(args: string[]): Promise<string> {
  const { stdout } = await execFileAsync("herdr", args, { timeout: 15000, maxBuffer: 1024 * 1024 });
  return stdout.trim();
}

function persist(pi: ExtensionAPI, state: ReviewState): void {
  pi.appendEntry("my-agent-review", state);
}

function startupFailure(state: ReviewState, message: string) {
  return errorResult(message, state);
}

function block(pi: ExtensionAPI, state: ReviewState, message: string) {
  state.status = "blocked";
  persist(pi, state);
  return errorResult(message, state);
}

function successResult(state: ReviewState, feedback: string) {
  return {
    content: [{ type: "text" as const, text: `Review round ${state.round}/3 completed with ${state.name}.\n\n${feedback}` }],
    details: state,
  };
}

function errorResult(message: string, state?: ReviewState) {
  return {
    content: [{ type: "text" as const, text: message }],
    details: state,
    isError: true,
  };
}

function completionMarker(id: string, round: number): string {
  return `MY_AGENT_REVIEW_COMPLETE_${id}_${round}`;
}

function findRecord(value: unknown, key: string): Record<string, unknown> | undefined {
  if (!isRecord(value)) return undefined;
  if (isRecord(value[key])) return value[key] as Record<string, unknown>;
  for (const nested of Object.values(value)) {
    const found = findRecord(nested, key);
    if (found) return found;
  }
  return undefined;
}

function containsAgentName(value: unknown, name: string): boolean {
  if (Array.isArray(value)) return value.some((item) => containsAgentName(item, name));
  if (!isRecord(value)) return false;
  if (value.name === name) return true;
  return Object.values(value).some((nested) => containsAgentName(nested, name));
}

function findAgentStatus(value: unknown): string | undefined {
  if (!isRecord(value)) return undefined;
  if (typeof value.agent_status === "string") return value.agent_status;
  if (typeof value.state === "string" && ["working", "blocked", "idle", "done", "unknown"].includes(value.state)) {
    return value.state;
  }
  for (const nested of Object.values(value)) {
    const found = findAgentStatus(nested);
    if (found) return found;
  }
  return undefined;
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    const stderr = "stderr" in error && typeof error.stderr === "string" ? error.stderr.trim() : "";
    return [error.message, stderr].filter(Boolean).join(": ");
  }
  return String(error);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
