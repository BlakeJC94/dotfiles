import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, isAbsolute, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SKILL_FILENAME = "SKILL.md";
const SKILL_SCAN_IGNORE_DIRS = new Set([
	".git",
	".hg",
	".svn",
	"node_modules",
	".venv",
	"venv",
	"bazel-bin",
	"bazel-out",
	"bazel-testlogs",
	"target",
	"dist",
]);
const SKILL_CACHE_PATH = resolve(homedir(), ".pi", "agent", "contextual-agents-skills.json");

type CachedSkill = {
	name: string;
	skillFile: string;
	skillDir: string;
};

type SkillCache = {
	version: 1;
	skills: CachedSkill[];
};

export default function skillfindExtension(pi: ExtensionAPI): void {
	const skillCache = loadSkillCache();
	const cachedSkillByFile = new Map<string, CachedSkill>(
		skillCache.skills.map((skill) => [skill.skillFile, skill]),
	);

	function addSkillsToCache(skillFiles: string[]): { found: number; added: number } {
		let added = 0;
		for (const skillFile of skillFiles) {
			if (cachedSkillByFile.has(skillFile)) continue;
			const skillName = parseSkillName(skillFile) ?? dirname(skillFile).split("/").pop() ?? "unknown";
			const cachedSkill: CachedSkill = {
				name: skillName,
				skillFile,
				skillDir: dirname(skillFile),
			};
			cachedSkillByFile.set(skillFile, cachedSkill);
			skillCache.skills.push(cachedSkill);
			added += 1;
		}
		if (added > 0) {
			saveSkillCache(skillCache);
		}
		return { found: skillFiles.length, added };
	}

	pi.registerCommand("skillfind", {
		description: "Scan a path for SKILL.md files, cache discovered skills, then offer reload",
		handler: async (args, ctx) => {
			const requestedPath = parseRequestedPath(args);
			const absoluteScanRoot = isAbsolute(requestedPath)
				? requestedPath
				: resolve(ctx.cwd, requestedPath);

			if (!existsSync(absoluteScanRoot)) {
				ctx.ui.notify(`Path does not exist: ${absoluteScanRoot}`, "error");
				return;
			}

			const skillFiles = discoverSkillFiles(absoluteScanRoot);
			const { found, added } = addSkillsToCache(skillFiles);
			ctx.ui.notify(`skillfind scanned ${found} skills, added ${added} new`, "info");

			if (!ctx.hasUI) return;
			const shouldReload = await ctx.ui.confirm(
				"Reload to register skills?",
				`Discovered ${found} skill file(s), added ${added} new. Reload now?`,
			);
			if (shouldReload) {
				await ctx.reload();
			}
		},
	});

	pi.on("resources_discover", async () => {
		const uniqueSkillDirs = Array.from(new Set(skillCache.skills.map((skill) => skill.skillDir)));
		return { skillPaths: uniqueSkillDirs };
	});
}

function parseRequestedPath(args: string): string {
	const trimmed = args.trim();
	if (!trimmed) return ".";
	if ((trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
		return trimmed.slice(1, -1);
	}
	return trimmed;
}

function parseSkillName(skillFilePath: string): string | null {
	const content = readFileSync(skillFilePath, "utf8");
	const match = content.match(/^---\n([\s\S]*?)\n---/);
	if (!match) return null;
	const frontmatter = match[1];
	for (const line of frontmatter.split("\n")) {
		const nameMatch = line.match(/^name:\s*(.+)\s*$/);
		if (!nameMatch) continue;
		return nameMatch[1].trim().replace(/^['"]|['"]$/g, "");
	}
	return null;
}

function discoverSkillFiles(scanRoot: string): string[] {
	const discovered: string[] = [];
	const pendingDirs: string[] = [resolve(scanRoot)];

	while (pendingDirs.length > 0) {
		const currentDir = pendingDirs.pop();
		if (!currentDir) continue;

		let entries: ReturnType<typeof readdirSync>;
		try {
			entries = readdirSync(currentDir, { withFileTypes: true });
		} catch {
			continue;
		}

		for (const entry of entries) {
			const absolutePath = resolve(currentDir, entry.name);
			if (entry.isDirectory()) {
				if (SKILL_SCAN_IGNORE_DIRS.has(entry.name)) continue;
				pendingDirs.push(absolutePath);
				continue;
			}
			if (entry.isFile() && entry.name === SKILL_FILENAME) {
				discovered.push(absolutePath);
			}
		}
	}

	return discovered;
}

function loadSkillCache(): SkillCache {
	try {
		const raw = readFileSync(SKILL_CACHE_PATH, "utf8");
		const parsed = JSON.parse(raw) as SkillCache;
		if (parsed.version !== 1 || !Array.isArray(parsed.skills)) {
			return { version: 1, skills: [] };
		}
		const validSkills = parsed.skills.filter(
			(skill) =>
				typeof skill?.name === "string" &&
				typeof skill?.skillFile === "string" &&
				typeof skill?.skillDir === "string",
		);
		return { version: 1, skills: validSkills };
	} catch {
		return { version: 1, skills: [] };
	}
}

function saveSkillCache(cache: SkillCache): void {
	mkdirSync(dirname(SKILL_CACHE_PATH), { recursive: true });
	writeFileSync(SKILL_CACHE_PATH, JSON.stringify(cache, null, 2));
}
