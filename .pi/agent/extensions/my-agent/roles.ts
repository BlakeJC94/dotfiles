export const ROLE_NAMES = ["my-planner", "my-coder", "my-reviewer", "my-monkey"] as const;

export type RoleName = (typeof ROLE_NAMES)[number];
export type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

export interface RoleSettings {
  provider: string;
  model: string;
  thinkingLevel: ThinkingLevel;
}

export interface RoleBaseline {
  provider?: string;
  model?: string;
  thinkingLevel: ThinkingLevel;
}

export interface RoleSessionState {
  skillName: RoleName;
  baseline: RoleBaseline;
}

export interface LoadedSkill {
  name: RoleName;
  sourceFile: string;
  sourceDirectory: string;
  body: string;
}

export type ParseResult<T> = { ok: true; value: T } | { ok: false; error: string };

const THINKING_LEVELS = new Set<ThinkingLevel>(["off", "minimal", "low", "medium", "high", "xhigh", "max"]);

export function parseRoleSettings(json: string, roleName: RoleName): ParseResult<RoleSettings> {
  let config: unknown;
  try {
    config = JSON.parse(json);
  } catch (error) {
    return { ok: false, error: `Invalid JSON: ${error instanceof Error ? error.message : String(error)}` };
  }

  if (!isRecord(config)) return { ok: false, error: "Configuration must be a JSON object." };
  const raw = config[roleName];
  if (!isRecord(raw)) return { ok: false, error: `Missing configuration for ${roleName}.` };
  if (typeof raw.provider !== "string" || !raw.provider.trim()) {
    return { ok: false, error: `${roleName}.provider must be a non-empty string.` };
  }
  if (typeof raw.model !== "string" || !raw.model.trim()) {
    return { ok: false, error: `${roleName}.model must be a non-empty string.` };
  }
  if (typeof raw.thinkingLevel !== "string" || !THINKING_LEVELS.has(raw.thinkingLevel as ThinkingLevel)) {
    return { ok: false, error: `${roleName}.thinkingLevel must be an exact supported thinking level.` };
  }

  return {
    ok: true,
    value: {
      provider: raw.provider,
      model: raw.model,
      thinkingLevel: raw.thinkingLevel as ThinkingLevel,
    },
  };
}

export function parseSkill(name: RoleName, sourceFile: string, source: string): ParseResult<LoadedSkill> {
  const frontmatter = source.match(/^---\r?\n[\s\S]*?^---[ \t]*(?:\r?\n|$)/m);
  const body = frontmatter ? source.slice(frontmatter[0].length) : source;
  if (!body.trim()) return { ok: false, error: `Skill file is empty: ${sourceFile}` };

  const separator = Math.max(sourceFile.lastIndexOf("/"), sourceFile.lastIndexOf("\\"));
  return {
    ok: true,
    value: {
      name,
      sourceFile,
      sourceDirectory: separator < 0 ? "." : sourceFile.slice(0, separator),
      body,
    },
  };
}

export function getRoleState(branch: readonly unknown[]): RoleSessionState | undefined {
  const entry = [...branch].reverse().find((candidate) => {
    return isRecord(candidate) && candidate.type === "custom" && candidate.customType === "my-agent-role";
  });
  if (!isRecord(entry) || !isRecord(entry.data)) return undefined;
  const { skillName, baseline } = entry.data;
  if (!isRoleName(skillName) || !isRecord(baseline)) return undefined;
  if (typeof baseline.thinkingLevel !== "string" || !THINKING_LEVELS.has(baseline.thinkingLevel as ThinkingLevel)) {
    return undefined;
  }
  if (baseline.provider !== undefined && typeof baseline.provider !== "string") return undefined;
  if (baseline.model !== undefined && typeof baseline.model !== "string") return undefined;
  return {
    skillName,
    baseline: {
      provider: baseline.provider as string | undefined,
      model: baseline.model as string | undefined,
      thinkingLevel: baseline.thinkingLevel as ThinkingLevel,
    },
  };
}

export function isRoleName(value: unknown): value is RoleName {
  return typeof value === "string" && ROLE_NAMES.includes(value as RoleName);
}

export function parseRoleCommandArg(value: string): RoleName | undefined {
  const name = value.startsWith("my-") ? value : `my-${value}`;
  return isRoleName(name) ? name : undefined;
}

export function renderRoleSection(skill: LoadedSkill): string {
  return [
    `Active skill: ${skill.name}`,
    `Source file: ${skill.sourceFile}`,
    `Source directory: ${skill.sourceDirectory}`,
    "Resolve relative references from the source directory.",
    "",
    skill.body,
  ].join("\n");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
