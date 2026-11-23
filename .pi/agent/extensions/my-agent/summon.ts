import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { statSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import { setTimeout } from "node:timers/promises";
import { promisify } from "node:util";

import { parseRoleCommandArg, type RoleName, type RoleSettings } from "./roles.ts";

const execFileAsync = promisify(execFile);
export const SUMMON_COMMANDS = ["summon-tab", "summon-workspace", "summon-pane"] as const;
export const DEFAULT_MESSAGES: Record<RoleName, string> = {
  "my-planner": "Plan the current task. If the task is not specified, ask for it. Do not implement.",
  "my-coder": "Implement the approved plan for this directory, respecting unresolved decisions and approval gates. If no approved plan is identifiable, ask before editing. Do not commit or push without explicit authorization.",
  "my-reviewer": "Review the current changes read-only. Report actionable findings, or 'No further notes.'",
  "my-monkey": "Probe the current changes read-only for likely bugs and uncovered edge cases. Report evidence; do not edit code or tests.",
};

export interface SummonRequest {
  command: (typeof SUMMON_COMMANDS)[number];
  role: RoleName;
  cwd: string;
  direction: "right" | "down";
  message?: string;
}

export interface SummonToolParams {
  layout: "tab" | "workspace" | "pane";
  role: "planner" | "coder" | "reviewer" | "monkey";
  directory?: string;
  direction?: "right" | "down";
  message?: string;
}

interface SummonOptions {
  signal?: AbortSignal;
  workspaceId: string;
  paneId: string;
  agentDir: string;
  model: RoleSettings;
  run?: (args: string[]) => Promise<string>;
  pause?: () => Promise<unknown>;
  attempts?: number;
}

export interface SummonedAgent {
  name: string;
  workspaceId: string;
  paneId: string;
  tabId?: string;
}

export function parseSummonArgs(args: string, cwd: string): SummonRequest {
  let [command, rest] = takeToken(args);
  if (!SUMMON_COMMANDS.includes(command as SummonRequest["command"])) throw new Error("Unknown summon command.");
  let direction: SummonRequest["direction"] = "right";
  let token: string;
  [token, rest] = takeToken(rest);
  if (token === "-v" && command === "summon-pane") {
    direction = "down";
    [token, rest] = takeToken(rest);
  }
  const role = parseRoleCommandArg(token);
  if (!role) throw new Error("Specify planner, coder, reviewer or monkey after the summon command.");

  let directory = cwd;
  if (rest.startsWith("--dir") && /^--dir(?:\s|$)/.test(rest)) {
    if (command !== "summon-workspace") throw new Error("--dir is only supported by summon-workspace.");
    let path: string;
    [path, rest] = takeToken(rest.slice(5));
    if (!path || path.startsWith("--")) throw new Error("--dir requires a directory.");
    directory = resolveDirectory(path, cwd);
  }
  if (rest === "-v" || rest.startsWith("-v ")) throw new Error("Place -v before the role: summon-pane -v <role>.");
  if (rest.startsWith("--") && rest !== "--" && !rest.startsWith("-- ")) {
    throw new Error("Unknown summon option. Put -- before a message that starts with --.");
  }
  const message = (rest === "--" ? "" : rest.startsWith("-- ") ? rest.slice(3) : rest).trim();
  return { command: command as SummonRequest["command"], role, cwd: directory, direction, ...(message ? { message } : {}) };
}

export function canSummonAgents(role: RoleName | undefined): boolean {
  return role === "my-planner" || role === "my-coder";
}

export function parseSummonToolParams(params: SummonToolParams, cwd: string, callerRole?: RoleName): SummonRequest {
  if (!canSummonAgents(callerRole)) throw new Error("Only planner and coder roles can use my_agent_summon.");
  const role = parseRoleCommandArg(params.role);
  if (!role) throw new Error("Specify planner, coder, reviewer or monkey as the child role.");
  if (!["tab", "workspace", "pane"].includes(params.layout)) throw new Error("Specify tab, workspace or pane as the layout.");
  if (params.directory !== undefined && params.layout !== "workspace") throw new Error("directory is only supported by workspace layout.");
  if (params.directory !== undefined && !params.directory.trim()) throw new Error("directory must not be empty.");
  if (params.direction !== undefined && params.layout !== "pane") throw new Error("direction is only supported by pane layout.");
  if (params.direction !== undefined && !["right", "down"].includes(params.direction)) throw new Error("direction must be right or down.");
  const message = params.message?.trim();
  return {
    command: `summon-${params.layout}`,
    role,
    cwd: params.directory === undefined ? cwd : resolveDirectory(params.directory, cwd),
    direction: params.direction ?? "right",
    ...(message ? { message } : {}),
  };
}

export async function summonAgent(request: SummonRequest, options: SummonOptions): Promise<SummonedAgent> {
  options.signal?.throwIfAborted();
  if (!statSync(request.cwd).isDirectory()) throw new Error(`Not a directory: ${request.cwd}`);
  const run = (args: string[]) => {
    options.signal?.throwIfAborted();
    return options.run ? options.run(args) : runHerdr(args, options.signal);
  };
  const pause = options.pause ?? (() => setTimeout(500, undefined, { signal: options.signal }));
  const attempts = options.attempts ?? 60;
  const name = `${request.role}-${randomUUID().slice(0, 8)}`;
  const modelArgs = ["--provider", options.model.provider, "--model", options.model.model, "--thinking", options.model.thinkingLevel];
  let child: SummonedAgent | undefined;

  async function json(args: string[]): Promise<Record<string, unknown>> {
    const envelope: unknown = JSON.parse(await run(args));
    if (!isRecord(envelope) || !isRecord(envelope.result)) throw new Error("Unexpected Herdr response.");
    return envelope.result;
  }

  async function waitForReadyPane(): Promise<void> {
    for (let attempt = 0; attempt < attempts; attempt++) {
      const result = await json(["pane", "get", child!.paneId]);
      const pane = result.pane;
      if (!isRecord(pane)) throw new Error("Herdr did not return the child pane.");
      if (pane.agent_status === "blocked") throw new Error("Child Pi needs user input; no approval was answered.");
      if (pane.agent === "pi" && ["idle", "done"].includes(String(pane.agent_status))) return;
      await pause();
    }
    throw new Error("Child Pi did not become ready; inspect it before retrying.");
  }

  try {
    const locationArgs = ["--cwd", request.cwd, "--env", `PI_CODING_AGENT_DIR=${options.agentDir}`, "--no-focus"];
    const created = await json(request.command === "summon-workspace"
      ? ["workspace", "create", "--label", name, ...locationArgs]
      : request.command === "summon-tab"
        ? ["tab", "create", "--workspace", options.workspaceId, "--label", name, ...locationArgs]
        : ["pane", "split", "--pane", options.paneId, "--direction", request.direction, ...locationArgs]);
    const pane = created.root_pane ?? created.pane;
    if (!isRecord(pane) || typeof pane.pane_id !== "string" || typeof pane.workspace_id !== "string") {
      throw new Error("Herdr created a location without returning its pane/workspace ids; inspect the layout before retrying.");
    }
    child = { name, paneId: pane.pane_id, workspaceId: pane.workspace_id, ...(typeof pane.tab_id === "string" ? { tabId: pane.tab_id } : {}) };

    try {
      await json(["agent", "start", name, "--kind", "pi", "--pane", child.paneId, "--timeout", "30000", "--", ...modelArgs]);
    } catch (error) {
      if (herdrErrorCode(error) !== "agent_pane_busy") throw error;
      const inspected = await json(["pane", "process-info", "--pane", child.paneId]);
      if (!isIdleShell(inspected.process_info)) throw new Error("Child pane is not an idle shell; no fallback launch was attempted.");
      // Herdr can reject a fresh shell before shell integration has reported readiness.
      await run(["pane", "run", child.paneId, ["pi", ...modelArgs].map(shellQuote).join(" ")]);
      await waitForReadyPane();
      await json(["agent", "rename", child.paneId, name]);
    }

    await waitForReadyPane();
    const shortRole = request.role.slice(3);
    // Role commands are synchronous and need not produce Herdr's working-state transition.
    await json(["agent", "prompt", name, `/agent ${shortRole}`]);
    let activated = false;
    for (let attempt = 0; attempt < attempts; attempt++) {
      const output = await run(["agent", "read", name, "--source", "visible", "--lines", "60"]);
      const result = await json(["agent", "get", name]);
      const agent = result.agent;
      if (!isRecord(agent)) throw new Error("Herdr did not return the child agent.");
      if (agent.agent_status === "blocked") throw new Error("Role activation needs user input; no task was sent.");
      if (output.includes(`Activated ${request.role} on `) && ["idle", "done"].includes(String(agent.agent_status))) {
        activated = true;
        break;
      }
      await pause();
    }
    if (!activated) throw new Error("Role activation was not confirmed; no task was sent. Inspect the child before retrying.");

    const message = request.message ?? options.model.defaultMessage ?? DEFAULT_MESSAGES[request.role];
    await json(["agent", "prompt", name, message, "--wait", "--until", "working", "--until", "blocked", "--timeout", "10000"]);
    return child;
  } catch (error) {
    const location = child ? ` Child: ${child.name}, pane ${child.paneId}, workspace ${child.workspaceId}.` : "";
    throw new Error(`${errorMessage(error)}${location} No automatic retry or cleanup was performed.`, { cause: error });
  }
}

function takeToken(value: string): [string, string] {
  const source = value.trimStart();
  let token = "";
  let quote = "";
  let index = 0;
  for (; index < source.length; index++) {
    const character = source[index];
    if (!quote && /\s/.test(character)) break;
    if (character === quote) quote = "";
    else if (!quote && (character === '"' || character === "'")) quote = character;
    else if (character === "\\" && quote !== "'") {
      if (++index >= source.length) throw new Error("Incomplete escape in summon arguments.");
      token += source[index];
    } else token += character;
  }
  if (quote) throw new Error("Unclosed quote in summon arguments.");
  return [token, source.slice(index).trimStart()];
}

function isIdleShell(value: unknown): boolean {
  if (!isRecord(value) || !Array.isArray(value.foreground_processes) || value.foreground_processes.length !== 1) return false;
  const process = value.foreground_processes[0];
  return isRecord(process) && process.pid === value.shell_pid && ["sh", "bash", "zsh", "fish", "dash", "ksh"].includes(String(process.name));
}

function shellQuote(value: string): string {
  return `'${value.replaceAll("'", "'\\''")}'`;
}

function resolveDirectory(path: string, cwd: string): string {
  return resolve(cwd, path === "~" ? homedir() : path.startsWith("~/") ? resolve(homedir(), path.slice(2)) : path);
}

async function runHerdr(args: string[], signal?: AbortSignal): Promise<string> {
  const { stdout } = await execFileAsync("herdr", args, { signal, timeout: 45000, maxBuffer: 1024 * 1024 });
  return stdout.trim();
}

function herdrErrorCode(error: unknown): string | undefined {
  if (!isRecord(error) || typeof error.stderr !== "string") return undefined;
  try {
    const envelope: unknown = JSON.parse(error.stderr);
    return isRecord(envelope) && isRecord(envelope.error) && typeof envelope.error.code === "string" ? envelope.error.code : undefined;
  } catch {
    return undefined;
  }
}

function errorMessage(error: unknown): string {
  if (!(error instanceof Error)) return String(error);
  const stderr = "stderr" in error && typeof error.stderr === "string" ? error.stderr.trim() : "";
  return [error.message, stderr].filter(Boolean).join(": ");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
