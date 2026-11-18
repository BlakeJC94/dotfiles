import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import { readFileSync } from "node:fs";
import { promisify } from "node:util";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

import { registerCommunicationTool } from "./communication-tool.ts";
import { registerReviewTool } from "./review-tool.ts";
import {
  getRoleState,
  parseRoleCommandArg,
  parseRoleSettings,
  parseSkill,
  readOptionalTextFile,
  renderRoleSection,
  type LoadedSkill,
  type RoleBaseline,
  type RoleName,
  type RoleSessionState,
  type RoleSettings,
} from "./roles.ts";

const execFileAsync = promisify(execFile);
const COMMUNICATION_TOOL = "my_agent_communicate";
const REVIEW_TOOL = "my_agent_review";
const ROLE_ENTRY = "my-agent-role";
let inactiveLogged = false;

interface ActiveRole {
  skill: LoadedSkill;
  settings?: RoleSettings;
  state: RoleSessionState;
  orgContext: string;
}

export default function myAgentExtension(pi: ExtensionAPI): void {
  if (!hasManagedEnvironment()) {
    logInactive("HERDR_ENV, HERDR_SOCKET_PATH, and HERDR_PANE_ID are required.");
    return;
  }

  let herdrReady = false;
  let activeRole: ActiveRole | undefined;
  registerCommunicationTool(pi);
  registerReviewTool(pi);

  const roleCommand = {
    description: "Activate a configured skill role: /agent <planner|coder|reviewer|monkey>",
    handler: async (args: string, ctx: ExtensionContext) => {
      const name = parseRoleCommandArg(args.trim());
      if (!name) {
        ctx.ui.notify(`Usage: /agent <planner|coder|reviewer|monkey>. ${activeDescription(activeRole)}`, "warning");
        return;
      }
      if (!herdrReady) {
        ctx.ui.notify("my-agent is inactive because Herdr is not ready in this session.", "error");
        return;
      }

      await ctx.waitForIdle();
      const result = await activateRole(pi, name, ctx, activeRole?.state.baseline);
      if (!result.ok) {
        ctx.ui.notify(result.error, "error");
        return;
      }
      activeRole = result.role;
      persistRole(pi, activeRole.state);
      syncRoleTools(pi, activeRole.skill.name);
      updateStatus(ctx, activeRole);
      ctx.ui.notify(`Activated ${name} on ${modelLabel(activeRole)}.`, "info");
    },
  };
  pi.registerCommand("agent", roleCommand);

  pi.on("session_start", async (_event, ctx) => {
    const readiness = await checkHerdrReadiness(ctx.mode);
    herdrReady = readiness.ready;
    if (!herdrReady) {
      activeRole = undefined;
      syncRoleTools(pi, undefined);
      updateStatus(ctx, undefined);
      logInactive(readiness.reason);
      return;
    }

    const saved = getRoleState(ctx.sessionManager.getBranch());
    if (!saved) {
      const baseline = activeRole?.state.baseline;
      activeRole = undefined;
      await restoreBaseline(pi, ctx, baseline);
      syncRoleTools(pi, undefined);
      updateStatus(ctx, undefined);
      return;
    }

    const result = await activateRole(pi, saved.skillName, ctx, saved.baseline);
    if (!result.ok) {
      activeRole = undefined;
      await restoreBaseline(pi, ctx, saved.baseline);
      syncRoleTools(pi, undefined);
      updateStatus(ctx, undefined);
      ctx.ui.notify(`Could not restore ${saved.skillName}: ${result.error}`, "error");
      return;
    }

    activeRole = result.role;
    syncRoleTools(pi, activeRole.skill.name);
    updateStatus(ctx, activeRole);
  });

  pi.on("session_tree", async (_event, ctx) => {
    if (!herdrReady) return;
    const saved = getRoleState(ctx.sessionManager.getBranch());
    if (!saved) {
      const baseline = activeRole?.state.baseline;
      activeRole = undefined;
      await restoreBaseline(pi, ctx, baseline);
      syncRoleTools(pi, undefined);
      updateStatus(ctx, undefined);
      return;
    }

    const result = await activateRole(pi, saved.skillName, ctx, saved.baseline);
    if (!result.ok) {
      activeRole = undefined;
      await restoreBaseline(pi, ctx, saved.baseline);
      syncRoleTools(pi, undefined);
      updateStatus(ctx, undefined);
      ctx.ui.notify(`Could not restore ${saved.skillName}: ${result.error}`, "error");
      return;
    }

    activeRole = result.role;
    syncRoleTools(pi, activeRole.skill.name);
    updateStatus(ctx, activeRole);
  });

  pi.on("before_agent_start", async (event) => {
    const sections = event.systemPromptOptions.sections;
    delete sections["my-agent-org"];
    delete sections["my-agent-role"];
    if (activeRole) {
      sections["my-agent-org"] = activeRole.orgContext;
      sections["my-agent-role"] = renderRoleSection(activeRole.skill);
    }
  });
}

async function activateRole(
  pi: ExtensionAPI,
  name: RoleName,
  ctx: ExtensionContext,
  baselineOverride?: RoleBaseline,
): Promise<{ ok: true; role: ActiveRole } | { ok: false; error: string }> {
  const configPath = join(getAgentDir(), "my-agent.json");
  const skillPath = join(homedir(), ".agents", "skills", name, "SKILL.md");
  const orgContextPath = join(homedir(), ".agents", "skills", "my-workflow", "ORG_CONTEXT.md");

  // The config file is optional. Without it, the role activates on the current model.
  const configText = readOptionalTextFile(configPath);
  if (!configText.ok) return configText;

  let skillText: string;
  let orgContext: string;
  try {
    skillText = readFileSync(skillPath, "utf8");
  } catch (error) {
    return { ok: false, error: `Cannot read ${skillPath}: ${errorMessage(error)}` };
  }
  try {
    orgContext = readFileSync(orgContextPath, "utf8");
  } catch (error) {
    return { ok: false, error: `Cannot read ${orgContextPath}: ${errorMessage(error)}` };
  }

  let settings: RoleSettings | undefined;
  if (configText.value !== undefined) {
    const parsedSettings = parseRoleSettings(configText.value, name);
    if (!parsedSettings.ok) return parsedSettings;
    settings = parsedSettings.value;
  }
  const parsedSkill = parseSkill(name, skillPath, skillText);
  if (!parsedSkill.ok) return parsedSkill;

  const baseline = baselineOverride ?? {
    provider: ctx.model?.provider,
    model: ctx.model?.id,
    thinkingLevel: ctx.thinkingLevel ?? pi.getThinkingLevel(),
  };

  if (settings) {
    const model = ctx.modelRegistry.find(settings.provider, settings.model);
    if (!model) return { ok: false, error: `Model ${settings.provider}/${settings.model} is not available.` };
    if (!ctx.modelRegistry.hasConfiguredAuth(model)) {
      return { ok: false, error: `No configured authentication for ${settings.provider}.` };
    }
    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok) return { ok: false, error: `Authentication failed for ${settings.provider}: ${auth.error}` };

    const applied = await pi.setModel(model);
    if (!applied) return { ok: false, error: `Pi could not apply ${settings.provider}/${settings.model}.` };
    pi.setThinkingLevel(settings.thinkingLevel);
  }

  return {
    ok: true,
    role: {
      skill: parsedSkill.value,
      settings,
      state: { skillName: name, baseline },
      orgContext,
    },
  };
}

async function restoreBaseline(pi: ExtensionAPI, ctx: ExtensionContext, baseline?: RoleBaseline): Promise<void> {
  if (!baseline) return;
  pi.setThinkingLevel(baseline.thinkingLevel);
  if (!baseline.provider || !baseline.model) return;
  const model = ctx.modelRegistry.find(baseline.provider, baseline.model);
  if (!model || !ctx.modelRegistry.hasConfiguredAuth(model)) return;
  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (auth.ok) await pi.setModel(model);
}

function persistRole(pi: ExtensionAPI, state: RoleSessionState): void {
  pi.appendEntry(ROLE_ENTRY, state);
}

function syncRoleTools(pi: ExtensionAPI, skillName: RoleName | undefined): void {
  const current = pi.getActiveTools();
  const next = new Set(current);
  if (skillName) next.add(COMMUNICATION_TOOL);
  else next.delete(COMMUNICATION_TOOL);
  if (skillName === "my-coder") next.add(REVIEW_TOOL);
  else next.delete(REVIEW_TOOL);
  if (next.size !== current.length || [...next].some((name, index) => name !== current[index])) {
    pi.setActiveTools([...next]);
  }
}

function updateStatus(ctx: ExtensionContext, role: ActiveRole | undefined): void {
  if (!role) {
    ctx.ui.setStatus("my-agent", undefined);
    return;
  }
  const label = `my-agent:${role.skill.name} (${modelLabel(role)})`;
  ctx.ui.setStatus("my-agent", ctx.ui.theme.fg("accent", label));
}

function modelLabel(role: ActiveRole): string {
  return role.settings ? `${role.settings.provider}/${role.settings.model}` : "current model";
}

function activeDescription(role: ActiveRole | undefined): string {
  return role ? `Active: ${role.skill.name} (${modelLabel(role)}).` : "No role is active.";
}

function hasManagedEnvironment(): boolean {
  return process.env.HERDR_ENV === "1" && !!process.env.HERDR_SOCKET_PATH && !!process.env.HERDR_PANE_ID;
}

async function checkHerdrReadiness(mode: ExtensionContext["mode"]): Promise<{ ready: true } | { ready: false; reason: string }> {
  if (mode !== "tui") return { ready: false, reason: "my-agent requires a Herdr-managed Pi TUI session." };
  try {
    const { stdout } = await execFileAsync("herdr", ["status"], { timeout: 5000, maxBuffer: 16384 });
    if (!/^server:\s*\n\s+status: running\s*$/m.test(stdout)) {
      return { ready: false, reason: "Herdr server is not running or its status could not be verified." };
    }
    return { ready: true };
  } catch (error) {
    return { ready: false, reason: `Herdr readiness check failed: ${errorMessage(error)}` };
  }
}

function logInactive(reason: string): void {
  if (inactiveLogged) return;
  inactiveLogged = true;
  console.warn(`my-agent inactive: ${reason}`);
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
