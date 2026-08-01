import { readdirSync } from "node:fs";
import { relative, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	type AutocompleteItem,
	type AutocompleteProvider,
	type AutocompleteSuggestions,
	fuzzyFilter,
} from "@earendil-works/pi-tui";

const IGNORE_DIRS = new Set([
	".git",
	"node_modules",
	"dist",
	"build",
	"target",
	".next",
	".cache",
	".venv",
	"venv",
]);

const MAX_INDEX_ENTRIES = 12_000;
const MAX_SUGGESTIONS = 20;
const RESCAN_INTERVAL_MS = 30_000;

type IndexedPath = {
	path: string;
	isDir: boolean;
};

export default function fuzzyPathCompletionExtension(pi: ExtensionAPI): void {
	pi.on("session_start", async (_event, ctx) => {
		const root = ctx.cwd;
		let cache: IndexedPath[] | undefined;
		let cacheExpiresAt = 0;

		function getIndex(): IndexedPath[] {
			const now = Date.now();
			if (cache && now < cacheExpiresAt) {
				return cache;
			}

			cache = buildPathIndex(root);
			cacheExpiresAt = now + RESCAN_INTERVAL_MS;
			return cache;
		}

		ctx.ui.addAutocompleteProvider((current) =>
			createProvider({
				current,
				getIndex,
			}),
		);
	});
}

function createProvider(params: {
	current: AutocompleteProvider;
	getIndex: () => IndexedPath[];
}): AutocompleteProvider {
	return {
		async getSuggestions(lines, cursorLine, cursorCol, options): Promise<AutocompleteSuggestions | null> {
			const line = lines[cursorLine] ?? "";
			const token = extractToken(line.slice(0, cursorCol));
			if (!token || !looksLikePathToken(token)) {
				return params.current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			const atPrefix = token.startsWith("@");
			const query = normalizeToken(token);
			const index = params.getIndex();

			const matches = fuzzyFilter(index, query, (entry) => entry.path)
				.slice(0, MAX_SUGGESTIONS)
				.map((entry) => toItem(entry, atPrefix));

			if (options.signal.aborted || matches.length === 0) {
				return params.current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			return {
				prefix: token,
				items: matches,
			};
		},

		applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
			return params.current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
		},

		shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
			return params.current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
		},
	};
}

function extractToken(beforeCursor: string): string | undefined {
	const match = beforeCursor.match(/(?:^|[\s("'])(@?[^\s"')]+)$/);
	return match?.[1];
}

function looksLikePathToken(token: string): boolean {
	const value = normalizeToken(token);
	return token.startsWith("@") || value.includes("/") || value.startsWith(".");
}

function normalizeToken(token: string): string {
	const withoutAt = token.startsWith("@") ? token.slice(1) : token;
	if (withoutAt.startsWith("./")) return withoutAt.slice(2);
	return withoutAt;
}

function toItem(entry: IndexedPath, withAtPrefix: boolean): AutocompleteItem {
	const suffix = entry.isDir ? "/" : "";
	const value = `${withAtPrefix ? "@" : ""}${entry.path}${suffix}`;
	return {
		value,
		label: value,
		description: entry.isDir ? "directory" : "file",
	};
}

function buildPathIndex(root: string): IndexedPath[] {
	const results: IndexedPath[] = [];
	const pending: string[] = [root];

	// AIDEV-NOTE: Cap index size so autocomplete stays responsive in large repositories.
	while (pending.length > 0 && results.length < MAX_INDEX_ENTRIES) {
		const currentDir = pending.pop();
		if (!currentDir) continue;

		let entries: ReturnType<typeof readdirSync>;
		try {
			entries = readdirSync(currentDir, { withFileTypes: true });
		} catch {
			continue;
		}

		for (const entry of entries) {
			if (results.length >= MAX_INDEX_ENTRIES) break;
			if (entry.name === ".DS_Store") continue;

			const absolutePath = resolve(currentDir, entry.name);
			const relPath = relative(root, absolutePath).split("\\").join("/");
			if (!relPath) continue;

			if (entry.isDirectory()) {
				if (IGNORE_DIRS.has(entry.name)) continue;
				results.push({ path: relPath, isDir: true });
				pending.push(absolutePath);
				continue;
			}

			if (entry.isFile()) {
				results.push({ path: relPath, isDir: false });
			}
		}
	}

	return results;
}
