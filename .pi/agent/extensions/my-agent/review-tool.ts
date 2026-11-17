import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { promisify } from "node:util";
import { Type } from "typebox";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI, ExtensionToolContext } from "@earendil-works/pi-coding-agent";

import { parseRoleSettings } from "./roles.ts";
import { buildReviewPrompt, getReviewState, hasCompletedMarker, type ReviewModelSettings, type ReviewState } from "./review-state.ts";

const execFileAsync = promisify(execFile);
const REVIEW_PARAMS = Type.Object({
  action: Type.Union([Type.Literal("start"), Type.Literal("follow_up"), Type.Literal("resume")]),
  goal: Type.Optional(Type.String()),
  planPath: Type.Optional(Type.String()),
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
  planPath?: string;
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
      "Use my_agent_review at review boundaries with the goal, approved plan path, exact diff scope, decisions, constraints, and check results. The tool activates /agent reviewer before sending the review request.",
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
          ["planPath", input.planPath],
          ["diffScope", input.diffScope],
          ["decisions", input.decisions],
          ["constraints", input.constraints],
          ["checkResults", input.checkResults],
          ["revision", input.revision],
        ] as const;
        const missing = required.find(([, value]) => !value?.trim());
        if (missing) return errorResult(`action=start requires ${missing[0]}.`);

        const reviewerModel = await getReviewerModel(ctx);
        if (!reviewerModel.ok) return errorResult(reviewerModel.error);
        const id = randomUUID();
        const state: ReviewState = {
          id,
          reviewerModel: reviewerModel.value,
          name: `my-reviewer-${id.slice(0, 8)}`,
          round: 1,
          status: "starting",
          goal: input.goal!,
          planPath: input.planPath!,
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
  ctx: ExtensionToolContext,
): Promise<{ ok: true; value: ReviewModelSettings } | { ok: false; error: string }> {
  let config: string;
  const path = join(getAgentDir(), "my-agent.json");
  try {
    config = readFileSync(path, "utf8");
  } catch (error) {
    return { ok: false, error: `Cannot read ${path}: ${errorMessage(error)}` };
  }
  const parsed = parseRoleSettings(config, "my-reviewer");
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
    await herdrJson(["agent", "prompt", state.name, "/agent reviewer", "--wait", "--timeout", "120000"]);
  } catch (error) {
    return errorResult(`Reviewer role activation failed. Resume to retry activation before review: ${errorMessage(error)}`, state);
  }

  state.status = "prompting";
  persist(pi, state);
  return await sendReviewPrompt(pi, state);
}

async function sendReviewPrompt(pi: ExtensionAPI, state: ReviewState) {
  try {
    await herdrJson([
      "agent",
      "prompt",
      state.name,
      buildReviewPrompt(state),
      "--wait",
      "--timeout",
      "120000",
    ]);
    return await collectFeedback(pi, state);
  } catch (error) {
    return block(pi, state, `Reviewer prompt/wait failed. Resume to inspect its state; the prompt will not be resent: ${errorMessage(error)}`);
  }
}

async function resumeReview(pi: ExtensionAPI, state: ReviewState, ctx: ExtensionToolContext) {
  if (state.status === "completed") return successResult(state, state.feedback ?? "Completed feedback is unavailable.");

  if (state.status === "starting") {
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

  try {
    const agent = await herdrJson(["agent", "get", state.name]);
    const status = findAgentStatus(agent);
    if (status === "working") {
      await herdrJson(["agent", "wait", state.name, "--timeout", "120000"]);
    }
    if (state.status === "activating") return await activateReviewer(pi, state);
    return await collectFeedback(pi, state);
  } catch (error) {
    const message = `Could not resume reviewer ${state.name}: ${errorMessage(error)}`;
    return state.status === "activating" ? errorResult(message, state) : block(pi, state, message);
  }
}

async function collectFeedback(pi: ExtensionAPI, state: ReviewState) {
  try {
    const agent = await herdrJson(["agent", "get", state.name]);
    const status = findAgentStatus(agent);
    const output = await herdrText(["agent", "read", state.name, "--source", "recent-unwrapped", "--lines", "200"]);
    if (status === "blocked") return block(pi, state, `Reviewer is blocked and needs user input. No feedback was treated as complete.\n${output}`);
    if (status !== "idle" && status !== "done") {
      return block(pi, state, `Reviewer did not settle (${status ?? "unknown"}). No feedback was treated as complete.\n${output}`);
    }
    if (!state.marker || !hasCompletedMarker(output, state.marker)) {
      return block(pi, state, `Reviewer settled without its completion marker. Feedback is unconfirmed; inspect before continuing.\n${output}`);
    }

    state.status = "completed";
    state.feedback = output;
    persist(pi, state);
    return successResult(state, output);
  } catch (error) {
    return block(pi, state, `Reviewer output could not be read; review remains unconfirmed: ${errorMessage(error)}`);
  }
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
