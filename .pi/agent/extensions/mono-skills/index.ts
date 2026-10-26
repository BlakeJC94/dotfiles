import type { ExtensionAPI, ExtensionToolContext, AgentToolResult } from "@earendil-works/pi-coding-agent";
import { cp, mkdir, readdir, readFile, rename, rm, stat, writeFile, realpath } from "node:fs/promises";
import { createHash } from "node:crypto";
import { join, relative, isAbsolute, resolve, sep } from "node:path";

const STORE_ROOT = join(
  process.env.PI_MONO_SKILLS_DIR ?? process.env.HOME ?? "/tmp",
  process.env.PI_MONO_SKILLS_DIR ? "" : ".pi/agent/mono-skills",
);
const MANIFEST_FILE = "manifest.json";

const EXCLUDED_DIRS = new Set([
  "node_modules", ".git", ".venv", "venv", ".env", ".tox", "__pycache__",
  ".pytest_cache", "dist", "build", ".next", ".turbo", "target", ".cache",
  ".bundle", ".dart_tool", "coverage",
]);

type Manifest = {
  version: 1 | 2;
  scope: string;
  refreshedAt: string;
  skillPaths: string[];
  // Version 2 catalog: doc locations relative to `root`, read live from the
  // repo. They are never copied into the store because, unlike skills, they
  // need no session reload to be useful.
  root?: string;
  agentsDirs?: string[];
  agentsMd?: string[];
};

// One tree walk yields both the skill dirs to copy and the docs to catalogue.
type AgentsTree = {
  skillsDirs: string[];
  agentsDirs: string[];
  agentsMd: string[];
};

function scopeId(scope: string): string {
  return createHash("sha256").update(scope).digest("hex");
}

function scopeDir(scope: string): string {
  return join(STORE_ROOT, scopeId(scope));
}

function toPosix(path: string): string {
  return sep === "/" ? path : path.split(sep).join("/");
}

async function canonicalPath(path: string): Promise<string> {
  try {
    return await realpath(path);
  } catch {
    return path;
  }
}

async function gitCommonDir(gitMarker: string, parentDir: string): Promise<string> {
  let gitDir = gitMarker;
  try {
    if (!(await stat(gitMarker)).isDirectory()) {
      const reference = (await readFile(gitMarker, "utf8")).match(/^gitdir:\s*(.+)\s*$/m)?.[1];
      if (reference) gitDir = resolve(parentDir, reference);
    }
  } catch {
    return canonicalPath(gitMarker);
  }

  try {
    const commonDir = (await readFile(join(gitDir, "commondir"), "utf8")).trim();
    if (commonDir) return canonicalPath(resolve(gitDir, commonDir));
  } catch {
    // A normal checkout has no commondir file.
  }
  return canonicalPath(gitDir);
}

async function cacheScope(cwd: string): Promise<string> {
  const canonicalCwd = await canonicalPath(cwd);
  let directory = canonicalCwd;

  while (true) {
    const gitMarker = join(directory, ".git");
    try {
      await stat(gitMarker);
      return gitCommonDir(gitMarker, directory);
    } catch {
      // Keep walking to the filesystem root.
    }

    const parent = join(directory, "..");
    if (parent === directory) return canonicalCwd;
    directory = parent;
  }
}

async function scanAgentsTree(root: string): Promise<AgentsTree> {
  const tree: AgentsTree = { skillsDirs: [], agentsDirs: [], agentsMd: [] };

  async function walk(dir: string): Promise<void> {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }

    for (const entry of entries) {
      if (entry.name === ".agents" && entry.isDirectory()) {
        const agentsDir = join(dir, entry.name);
        tree.agentsDirs.push(toPosix(relative(root, agentsDir)));
        const skills = join(agentsDir, "skills");
        try {
          if ((await stat(skills)).isDirectory()) tree.skillsDirs.push(skills);
        } catch {
          // An .agents dir without a skills subdir is still catalogued.
        }
        continue;
      }
      if (entry.isFile() && entry.name === "AGENTS.md") {
        tree.agentsMd.push(toPosix(relative(root, join(dir, entry.name))));
        continue;
      }
      if (!entry.isDirectory()) continue;
      if (EXCLUDED_DIRS.has(entry.name)) continue;
      if (entry.name.startsWith(".")) continue;
      await walk(join(dir, entry.name));
    }
  }

  await walk(root);
  tree.agentsDirs.sort();
  tree.agentsMd.sort();
  return tree;
}

async function loadManifest(scope: string): Promise<Manifest | undefined> {
  let manifest: Manifest;
  try {
    manifest = JSON.parse(await readFile(join(scopeDir(scope), MANIFEST_FILE), "utf8")) as Manifest;
  } catch {
    return undefined;
  }

  if (manifest.scope !== scope || !Array.isArray(manifest.skillPaths)) return undefined;
  if (manifest.version !== 1 && manifest.version !== 2) return undefined;

  if (
    manifest.version === 2 &&
    (typeof manifest.root !== "string" || !Array.isArray(manifest.agentsDirs) || !Array.isArray(manifest.agentsMd))
  ) {
    // A corrupt catalog must not take the skills cache down with it.
    return { version: 1, scope: manifest.scope, refreshedAt: manifest.refreshedAt, skillPaths: manifest.skillPaths };
  }
  return manifest;
}

async function loadCachedSkillPaths(manifest: Manifest): Promise<string[]> {
  const dir = scopeDir(manifest.scope);
  const validPaths: string[] = [];

  for (const skillPath of manifest.skillPaths) {
    const pathWithinScope = relative(dir, skillPath);
    if (pathWithinScope.startsWith("..") || isAbsolute(pathWithinScope)) continue;
    try {
      if ((await stat(skillPath)).isDirectory()) validPaths.push(skillPath);
    } catch {
      // A partial or manually removed cache entry is ignored.
    }
  }
  return validPaths;
}

function findApplicableDocs(manifest: Manifest, queryPath: string): { agentsMd: string[]; agentsDirs: string[] } {
  const rel = relative(manifest.root!, queryPath);
  // Query is outside this catalog's tree.
  if (rel.startsWith("..") || isAbsolute(rel)) {
    return { agentsMd: [], agentsDirs: [] };
  }

  const agentsMd: string[] = [];
  const agentsDirs: string[] = [];

  // Normalize to posix for matching against catalogued posix paths.
  const queryPosix = toPosix(rel);
  const queryParts = queryPosix.split("/").filter(Boolean);

  // Find ancestors: for each prefix of the query path (including empty = root),
  // check if that dir has a catalogued AGENTS.md or .agents.
  for (let i = 0; i <= queryParts.length; i++) {
    const prefix = queryParts.slice(0, i).join("/");
    const agentsMdPath = prefix ? `${prefix}/AGENTS.md` : "AGENTS.md";
    const agentsDirPath = prefix ? `${prefix}/.agents` : ".agents";

    if (manifest.agentsMd?.includes(agentsMdPath)) agentsMd.unshift(agentsMdPath);
    if (manifest.agentsDirs?.includes(agentsDirPath)) agentsDirs.unshift(agentsDirPath);
  }

  return { agentsMd, agentsDirs };
}

function prefixedSkillName(root: string, skillsDir: string, original: string): string {
  const parts = relative(root, skillsDir).split(sep);
  const normalize = (value: string) => value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const first = parts[0] === ".agents" ? "root" : normalize(parts[0]);
  const parent = parts.length > 2 ? normalize(parts[parts.length - 3]) : first;
  const name = normalize(original);
  const prefixed = [first, ...(first === parent ? [] : [parent]), name].join("-");
  if (prefixed.length <= 64) return prefixed;
  const withoutFirst = `${parent}-${name}`;
  return withoutFirst.length <= 64 ? withoutFirst : name;
}

async function prefixCopiedSkills(root: string, source: string, destination: string): Promise<void> {
  for (const entry of await readdir(destination, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillFile = join(destination, entry.name, "SKILL.md");
    let content: string;
    try {
      content = await readFile(skillFile, "utf8");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") continue;
      throw error;
    }

    const frontmatter = content.match(/^---\r?\n[\s\S]*?^---[ \t]*\r?\n/m)?.[0];
    const original = frontmatter?.match(/^name:\s*['"]?([^'"\r\n]+)['"]?\s*$/m)?.[1] ?? entry.name;
    const name = prefixedSkillName(root, source, original);
    if (frontmatter) {
      const updated = /^name:[^\r\n]*$/m.test(frontmatter)
        ? frontmatter.replace(/^name:[^\r\n]*$/m, `name: ${name}`)
        : frontmatter.replace(/^---\r?\n/, `---\nname: ${name}\n`);
      content = updated + content.slice(frontmatter.length);
    } else {
      content = `---\nname: ${name}\n---\n\n${content}`;
    }
    await writeFile(skillFile, content);
  }
}

async function refreshCache(cwd: string, scope: string): Promise<AgentsTree> {
  const tree = await scanAgentsTree(cwd);
  const target = scopeDir(scope);
  const temporary = `${target}.tmp-${process.pid}-${Date.now()}`;
  const backup = `${target}.old-${process.pid}-${Date.now()}`;

  await mkdir(STORE_ROOT, { recursive: true });
  await rm(temporary, { recursive: true, force: true });
  await mkdir(join(temporary, "skills"), { recursive: true });

  const skillPaths: string[] = [];
  for (const [index, source] of tree.skillsDirs.entries()) {
    const destination = join(temporary, "skills", String(index));
    await cp(source, destination, { recursive: true, force: true });
    await prefixCopiedSkills(cwd, source, destination);
    skillPaths.push(join(target, "skills", String(index)));
  }

  const manifest: Manifest = {
    version: 2,
    scope,
    refreshedAt: new Date().toISOString(),
    root: cwd,
    skillPaths,
    agentsDirs: tree.agentsDirs,
    agentsMd: tree.agentsMd,
  };
  await writeFile(join(temporary, MANIFEST_FILE), `${JSON.stringify(manifest, null, 2)}\n`);

  try {
    await rename(target, backup);
  } catch {
    // No previous cache exists.
  }

  try {
    await rename(temporary, target);
  } catch (error) {
    try {
      await rename(backup, target);
    } catch {
      // Preserve the original rename error when rollback also fails.
    }
    throw error;
  }

  await rm(backup, { recursive: true, force: true });
  return tree;
}

export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", async (_event, ctx) => {
    const manifest = await loadManifest(await cacheScope(ctx.cwd));
    if (!manifest) return undefined;
    const skillPaths = await loadCachedSkillPaths(manifest);
    return skillPaths.length > 0 ? { skillPaths } : undefined;
  });

  const AGENTS_DIRS_PARAMS = {
    type: "object",
    properties: {
      path: { type: "string", description: "Path to find applicable docs for (default: cwd)" },
    },
  };

  pi.registerTool({
    name: "agents_dirs",
    label: "Nested Agent Docs",
    description:
      "Look up nested AGENTS.md and .agents directories that apply to a path, using the cached catalog. " +
      "Use this instead of checking ancestor directories one by one. " +
      "Returns paths relative to repo root, ancestors first. Read them with the read tool.",
    promptSnippet: "look up applicable AGENTS.md and .agents dirs for a path from the catalog",
    promptGuidelines: [
      "Before editing a file, call agents_dirs(path) to find relevant AGENTS.md and .agents dirs.",
      "Do not check ancestor directories manually - the tool returns the same result faster.",
    ],
    parameters: AGENTS_DIRS_PARAMS,
    exposure: "deferred",
    async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionToolContext): Promise<AgentToolResult> {
      const scope = await cacheScope(ctx.cwd);
      const manifest = await loadManifest(scope);
      if (!manifest || manifest.version !== 2) {
        return {
          content: [{ type: "text", text: "No nested-docs catalog for this repo. Run /refreshskills first." }],
          details: undefined,
        };
      }

      const queryPath = await canonicalPath(params.path ?? ctx.cwd);
      const { agentsMd, agentsDirs } = findApplicableDocs(manifest, queryPath);

      if (!agentsMd.length && !agentsDirs.length) {
        const hint =
          queryPath === manifest.root
            ? "No AGENTS.md or .agents found anywhere."
            : `No applicable docs for ${queryPath} (catalog is for ${manifest.root}).`;
        return { content: [{ type: "text", text: hint }], details: undefined };
      }

      const lines: string[] = ["Applicable nested agent docs for " + queryPath + ":"];
      if (agentsMd.length) lines.push("", "AGENTS.md (nearest first):", ...agentsMd);
      if (agentsDirs.length) lines.push("", ".agents dirs (nearest first):", ...agentsDirs);
      lines.push(
        "",
        "Read them with the read tool. For .agents dirs, check for README.md or other guidance files inside."
      );
      return { content: [{ type: "text", text: lines.join("\n") }], details: { agentsMd, agentsDirs } };
    },
  });

  // Activate the tool when a v2 catalog exists.
  pi.on("resources_discover", async (_event, ctx) => {
    const manifest = await loadManifest(await cacheScope(ctx.cwd));
    if (!manifest || manifest.version !== 2) return undefined;
    if (!manifest.agentsMd?.length && !manifest.agentsDirs?.length) return undefined;
    const current = pi.getActiveTools();
    if (current.includes("agents_dirs")) return undefined;
    pi.setActiveTools([...current, "agents_dirs"]);
  });

  pi.registerCommand("refreshskills", {
    description: "Recursively refresh cached monorepo skills and the nested agent-docs catalog",
    handler: async (_args, ctx) => {
      const cwd = await canonicalPath(ctx.cwd);
      const scope = await cacheScope(cwd);
      const tree = await refreshCache(cwd, scope);
      ctx.ui.notify(
        `Cached ${tree.skillsDirs.length} skill directories (new session) and catalogued ` +
          `${tree.agentsMd.length} AGENTS.md files and ${tree.agentsDirs.length} .agents dirs (next response).`,
        "info",
      );
    },
  });

  pi.registerCommand("clearskills", {
    description: "Clear the skills cache and nested agent-docs catalog for the current Git repo",
    handler: async (_args, ctx) => {
      const scope = await cacheScope(ctx.cwd);
      await rm(scopeDir(scope), { recursive: true, force: true });
      ctx.ui.notify("Cleared this repo's skills cache and nested-docs catalog (new session).", "info");
    },
  });
}
