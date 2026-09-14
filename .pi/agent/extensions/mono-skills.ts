import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readdir, stat } from "node:fs/promises";
import { join, basename } from "node:path";

// Directories to skip when walking the project tree.
// These are excluded at the top level of the walk and within subdirectories.
const EXCLUDED_DIRS = new Set([
  "node_modules",
  ".git",
  ".venv",
  "venv",
  ".env",
  ".tox",
  "__pycache__",
  ".pytest_cache",
  "dist",
  "build",
  ".next",
  ".turbo",
  "target",        // Rust/cargo build output
  ".cache",
  ".bundle",
  ".dart_tool",
  "coverage",
]);

/**
 * Recursively walk from `root` downward, collecting every `.agents/skills`
 * directory while skipping common build artifacts and dependency trees.
 */
async function findAgentsSkillsDirs(root: string): Promise<string[]> {
  const results: string[] = [];

  async function walk(dir: string) {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return; // permission denied or deleted during walk
    }

    // Check for `.agents/skills` at this level
    const agentsSkills = join(dir, ".agents", "skills");
    try {
      const s = await stat(agentsSkills);
      if (s.isDirectory()) {
        results.push(agentsSkills);
      }
    } catch {
      // doesn't exist — fine
    }

    // Recurse into subdirectories, skipping excluded dirs and hidden dirs
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;

      const name = entry.name;

      // Skip excluded directories
      if (EXCLUDED_DIRS.has(name)) continue;

      // Skip hidden directories at root level (e.g. .config, .cache),
      // but not `.agents` itself — that's the target we're looking for.
      if (name.startsWith(".") && name !== ".agents") continue;

      await walk(join(dir, name));
    }
  }

  await walk(root);
  return results;
}

export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", async (_event, ctx) => {
    const skillDirs = await findAgentsSkillsDirs(ctx.cwd);

    if (skillDirs.length > 0) {
      return { skillPaths: skillDirs };
    }
  });
}