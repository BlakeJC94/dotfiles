import { existsSync, readFileSync, statSync } from "node:fs";
import { dirname, isAbsolute, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CONTEXT_FILENAMES = ["AGENTS.md", "CLAUDE.md"] as const;
const PATH_TOOLS = new Set(["read", "edit", "write"]);

export default function contextualAgentsExtension(pi: ExtensionAPI): void {
	const repoRoot = findRepoRoot(process.cwd());
	const defaultContextFiles = new Set<string>(discoverDefaultContextFiles(process.cwd()));
	const checkedDirs = new Set<string>();
	const discoveredFiles: string[] = [];
	const discoveredFileSet = new Set<string>();
	const discoveredContent = new Map<string, string>();
	let cachedPromptBlock = "";

	function refreshPromptBlock(): void {
		if (discoveredFiles.length === 0) {
			cachedPromptBlock = "";
			return;
		}
		const blocks = discoveredFiles
			.map((filePath) => {
				const body = discoveredContent.get(filePath) ?? "";
				return [`Path: ${filePath}`, "```markdown", body, "```"].join("\n");
			})
			.join("\n\n");
		cachedPromptBlock = [
			"Additional path-scoped context files discovered during this session:",
			blocks,
		].join("\n\n");
	}

	function maybeAddContextFile(filePath: string): void {
		if (defaultContextFiles.has(filePath)) return;
		if (discoveredFileSet.has(filePath)) return;
		if (!existsSync(filePath)) return;

		discoveredFileSet.add(filePath);
		discoveredFiles.push(filePath);
		discoveredContent.set(filePath, readFileSync(filePath, "utf8"));
		refreshPromptBlock();
	}

	function scanPathAncestorsOnce(targetPath: string): void {
		if (!targetPath.startsWith(repoRoot)) return;
		const targetDir = directoryForPath(targetPath);
		for (const dirPath of chainFromRoot(repoRoot, targetDir)) {
			if (checkedDirs.has(dirPath)) continue;
			// AIDEV-NOTE: Scan each ancestor directory once per session to avoid repeated fs checks.
			checkedDirs.add(dirPath);
			for (const contextName of CONTEXT_FILENAMES) {
				maybeAddContextFile(resolve(dirPath, contextName));
			}
		}
	}

	pi.on("tool_call", async (event, ctx) => {
		if (!PATH_TOOLS.has(event.toolName)) return;
		const rawPath = typeof event.input.path === "string" ? event.input.path : "";
		if (!rawPath.trim()) return;
		const normalized = rawPath.replace(/^@/, "").trim();
		const absolutePath = isAbsolute(normalized) ? normalized : resolve(ctx.cwd, normalized);
		scanPathAncestorsOnce(absolutePath);
	});

	pi.on("before_agent_start", async (event) => {
		if (!cachedPromptBlock) return;
		return {
			systemPrompt: `${event.systemPrompt}\n\n${cachedPromptBlock}`,
		};
	});
}

function discoverDefaultContextFiles(startDir: string): string[] {
	const files: string[] = [];
	for (const dirPath of upwardChain(startDir)) {
		for (const contextName of CONTEXT_FILENAMES) {
			const filePath = resolve(dirPath, contextName);
			if (existsSync(filePath)) files.push(filePath);
		}
	}
	return files;
}

function findRepoRoot(startDir: string): string {
	for (const dirPath of upwardChain(startDir)) {
		if (existsSync(resolve(dirPath, ".git"))) {
			return dirPath;
		}
	}
	return startDir;
}

function upwardChain(startDir: string): string[] {
	const chain: string[] = [];
	let current = resolve(startDir);
	while (true) {
		chain.push(current);
		const parent = dirname(current);
		if (parent === current) break;
		current = parent;
	}
	return chain;
}

function chainFromRoot(rootDir: string, targetDir: string): string[] {
	const root = resolve(rootDir);
	const target = resolve(targetDir);
	if (root === target) return [root];
	if (!target.startsWith(root + "/")) return [];

	const relative = target.slice(root.length + 1);
	const parts = relative.split("/").filter(Boolean);
	const chain = [root];
	let current = root;
	for (const part of parts) {
		current = resolve(current, part);
		chain.push(current);
	}
	return chain;
}

function directoryForPath(targetPath: string): string {
	const resolved = resolve(targetPath);
	try {
		if (statSync(resolved).isDirectory()) {
			return resolved;
		}
	} catch {
		// Ignore missing paths and treat as file-like.
	}
	return dirname(resolved);
}
