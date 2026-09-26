/**
 * Web Search Extension
 *
 * Registers tools for:
 *   - web_search     — DuckDuckGo search (returns titles + snippets + URLs)
 *   - web_fetch      — fetch a URL and extract clean text content
 *   - web_research   — combined: search + fetch top results
 *
 * Uses the DuckDuckGo HTML endpoint (no API key required).
 * Prompt injection scanning is handled by the separate injection-guard
 * extension via tool_call and tool_result lifecycle events.
 *
 * Security:
 *   - URL validation (http/https only)
 *   - Content size limits (50KB per fetch, 100KB per search)
 *   - No JavaScript execution
 *   - Timeout protection
 *
 * Usage:
 *   /websearch <query>     — Quick DuckDuckGo search
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type, type Static } from "typebox";

// ─── Constants ──────────────────────────────────────────────────────────────

const MAX_FETCH_SIZE = 50 * 1024; // 50KB max per fetched page
const MAX_SEARCH_RESULTS = 10;
const MAX_SEARCH_SIZE = 100 * 1024; // 100KB max search results
const FETCH_TIMEOUT_MS = 15_000;
const SEARCH_TIMEOUT_MS = 10_000;
const MAX_TEXT_LENGTH = 30_000; // Truncate extracted text to ~30K chars

const DDG_HTML_URL = "https://html.duckduckgo.com/html/";

const USER_AGENT =
	"Mozilla/5.0 (compatible; CodingAgent/1.0; +https://github.com/earendil-works/pi-coding-agent)";

// ─── HTML-to-Text Extraction ────────────────────────────────────────────────

/**
 * Strip HTML tags and extract readable text.
 * Intentionally simple — no external parser dependency.
 */
function htmlToText(html: string): string {
	let text = html
		// Remove scripts and styles
		.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, " ")
		.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, " ")
		// Block-level tags → newlines
		.replace(/<(?:br|p|li|div|tr|h[1-6]|blockquote|pre|section|article|header|footer)[^>]*>/gi, "\n")
		// Inline tags → spaces
		.replace(/<(?:td|th|a|span|strong|em|b|i|code|mark|small|sub|sup)[^>]*>/gi, " ")
		// Strip remaining tags
		.replace(/<[^>]*>/g, " ")
		// Decode HTML entities
		.replace(/&amp;/g, "&")
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&quot;/g, '"')
		.replace(/&#39;/g, "'")
		.replace(/&nbsp;/g, " ")
		.replace(/&#x27;/g, "'")
		.replace(/&#x2F;/g, "/")
		// Collapse whitespace
		.replace(/\n{3,}/g, "\n\n")
		.replace(/[ \t]{3,}/g, " ");

	text = text
		.split("\n")
		.map((l) => l.trim())
		.join("\n")
		.replace(/^\n+/, "")
		.replace(/\n+$/, "");

	return text.trim();
}

function extractTitle(html: string): string {
	const match = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
	return match ? htmlToText(match[1]).trim().slice(0, 200) : "(no title)";
}

// ─── DuckDuckGo HTML Search ────────────────────────────────────────────────

interface SearchResult {
	title: string;
	snippet: string;
	url: string;
}

/**
 * Parse the DuckDuckGo HTML results page.
 *
 * Searches for result blocks with class "result results_links results_links_deep",
 * then extracts title, URL, and snippet from each.
 */
function parseDdgResults(html: string): SearchResult[] {
	const results: SearchResult[] = [];

	// Try primary parser: find result blocks
	const blocks = html.match(
		/<div\s+class="result\s+results_links\s+results_links_deep"[^>]*>[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/gi,
	);

	if (blocks) {
		for (const block of blocks) {
			const titleMatch = block.match(/<a[^>]*class="result__a"[^>]*>([\s\S]*?)<\/a>/i);
			const urlMatch = block.match(/<a[^>]*class="result__a"[^>]*href="(https?:\/\/[^"]+)"/i);
			const snippetMatch = block.match(/<a[^>]*class="result__snippet"[^>]*>([\s\S]*?)<\/a>/i);

			const title = titleMatch ? htmlToText(titleMatch[1]).trim() : "";
			const url = urlMatch ? urlMatch[1] : "";
			const snippet = snippetMatch ? htmlToText(snippetMatch[1]).trim() : "";

			if (url && title) results.push({ title, snippet, url });
		}
	}

	if (results.length > 0) return results;

	// Fallback: scan for rel="nofollow" links with results__a-like titles
	const linkRe = /<a[^>]*rel="nofollow"[^>]*href="(https?:\/\/[^"]+)"[^>]*>([\s\S]*?)<\/a>/gi;
	let match: RegExpExecArray | null;
	while ((match = linkRe.exec(html)) !== null) {
		const url = match[1];
		const title = htmlToText(match[2]).trim();
		if (url && title && !url.includes("duckduckgo.com")) {
			const after = html.slice(match.index + match[0].length, match.index + match[0].length + 500);
			const snippetHit = after.match(/class="result__snippet"[^>]*>([\s\S]*?)<\/a>/i);
			const snippet = snippetHit ? htmlToText(snippetHit[1]).trim() : "";
			results.push({ title, snippet, url });
		}
	}

	return results;
}

async function searchDdg(query: string, maxResults: number): Promise<SearchResult[]> {
	const params = new URLSearchParams({ q: query });
	const url = `${DDG_HTML_URL}?${params.toString()}`;

	const response = await fetch(url, {
		signal: AbortSignal.timeout(SEARCH_TIMEOUT_MS),
		headers: {
			"User-Agent": USER_AGENT,
			Accept: "text/html,application/xhtml+xml",
			"Accept-Language": "en-US,en;q=0.9",
		},
	});

	if (!response.ok) throw new Error(`DuckDuckGo returned HTTP ${response.status}`);

	const html = await response.text();
	if (html.length > MAX_SEARCH_SIZE)
		throw new Error(`Search results too large (${html.length} bytes, max ${MAX_SEARCH_SIZE})`);

	return parseDdgResults(html).slice(0, maxResults);
}

// ─── Web Fetch ──────────────────────────────────────────────────────────────

interface FetchResult {
	title: string;
	text: string;
	contentType: string;
	length: number;
}

async function fetchUrl(url: string): Promise<FetchResult> {
	// Validate URL
	try {
		const parsed = new URL(url);
		if (!["http:", "https:"].includes(parsed.protocol))
			throw new Error(`Unsupported protocol: ${parsed.protocol}`);
	} catch (e) {
		throw new Error(`Invalid URL: ${e instanceof Error ? e.message : "unknown error"}`);
	}

	const response = await fetch(url, {
		signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
		headers: {
			"User-Agent": USER_AGENT,
			Accept: "text/html,application/xhtml+xml,text/plain,application/json",
		},
		redirect: "follow",
	});

	if (!response.ok) throw new Error(`HTTP ${response.status} ${response.statusText}`);

	const contentType = response.headers.get("content-type") ?? "unknown";
	const contentLength = response.headers.get("content-length");

	if (contentLength && parseInt(contentLength, 10) > MAX_FETCH_SIZE)
		throw new Error(`Content too large (${contentLength} bytes, max ${MAX_FETCH_SIZE})`);

	const raw = await response.text();
	const truncated = raw.slice(0, MAX_FETCH_SIZE);

	let text: string;
	let title = "(no title)";

	if (contentType.includes("text/html")) {
		title = extractTitle(truncated);
		text = htmlToText(truncated);
	} else if (contentType.includes("application/json")) {
		title = url;
		try {
			text = JSON.stringify(JSON.parse(truncated), null, 2);
		} catch {
			text = truncated;
		}
	} else {
		title = url;
		text = truncated;
	}

	if (text.length > MAX_TEXT_LENGTH)
		text = text.slice(0, MAX_TEXT_LENGTH) + `\n\n[... truncated at ${MAX_TEXT_LENGTH} characters]`;

	return { title, text, contentType, length: text.length };
}

// ─── Tool Parameter Schemas ─────────────────────────────────────────────────

const WebSearchParams = Type.Object({
	query: Type.String({ description: "Search query" }),
	maxResults: Type.Optional(
		Type.Integer({ description: "Maximum results to return (1-10)", default: 5, minimum: 1, maximum: 10 }),
	),
});

const WebFetchParams = Type.Object({
	url: Type.String({ description: "URL to fetch" }),
	maxLength: Type.Optional(
		Type.Integer({
			description: "Maximum characters in extracted text (default: 15000)",
			default: 15_000,
			minimum: 1000,
			maximum: 50000,
		}),
	),
});

const WebResearchParams = Type.Object({
	query: Type.String({ description: "Research query" }),
	depth: Type.Optional(
		Type.Integer({
			description: "Number of search results to fully fetch (1-5)",
			default: 3,
			minimum: 1,
			maximum: 5,
		}),
	),
	maxSearchResults: Type.Optional(
		Type.Integer({
			description: "Number of search results to list (1-10)",
			default: 8,
			minimum: 1,
			maximum: 10,
		}),
	),
});

type WebSearchParamsType = Static<typeof WebSearchParams>;
type WebFetchParamsType = Static<typeof WebFetchParams>;
type WebResearchParamsType = Static<typeof WebResearchParams>;

// ─── Details Types ──────────────────────────────────────────────────────────

interface SearchDetails {
	mode: "search";
	query: string;
	maxResults: number;
	results: SearchResult[];
	resultCount: number;
	resultLimit: number;
}

interface FetchDetails {
	mode: "fetch";
	url: string;
	title: string;
	contentType: string;
	length: number;
	truncated: boolean;
}

interface ResearchDetails {
	mode: "research";
	query: string;
	searchResults: SearchResult[];
	fetched: Array<{ url: string; title: string; success: boolean; error?: string; length: number }>;
}

// ─── Extension ──────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	// ── Tool: web_search ──────────────────────────────────────────────
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web using DuckDuckGo. Returns titles, snippets, and URLs. Use web_fetch to get full page content from result URLs.",
		parameters: WebSearchParams,

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			const { query, maxResults = 5 } = params;

			let results: SearchResult[];
			try {
				results = await searchDdg(query, Math.min(maxResults, MAX_SEARCH_RESULTS));
			} catch (e) {
				return {
					content: [{ type: "text", text: `Search failed: ${e instanceof Error ? e.message : "unknown error"}` }],
					details: { mode: "search", query, maxResults, results: [], resultCount: 0, resultLimit: maxResults } as SearchDetails,
					isError: true,
				};
			}

			if (results.length === 0) {
				return {
					content: [{ type: "text", text: "No results found." }],
					details: { mode: "search", query, maxResults, results: [], resultCount: 0, resultLimit: maxResults } as SearchDetails,
				};
			}

			const lines = [`Search results for "${query}" (${results.length} results):`, ""];
			for (let i = 0; i < results.length; i++) {
				const r = results[i];
				lines.push(`${i + 1}. ${r.title}`);
				lines.push(`   URL: ${r.url}`);
				if (r.snippet) lines.push(`   ${r.snippet}`);
				lines.push("");
			}

			return {
				content: [{ type: "text", text: lines.join("\n").trim() }],
				details: { mode: "search", query, maxResults, results, resultCount: results.length, resultLimit: maxResults } as SearchDetails,
			};
		},
	});

	// ── Tool: web_fetch ───────────────────────────────────────────────
	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			"Fetch a URL and extract clean text content. Strips HTML, scripts, and styles. Returns readable text suitable for LLM consumption.",
		parameters: WebFetchParams,

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			const { url, maxLength = 15_000 } = params;

			let result: FetchResult;
			try {
				result = await fetchUrl(url);
			} catch (e) {
				return {
					content: [{ type: "text", text: `Fetch failed: ${e instanceof Error ? e.message : "unknown error"}` }],
					details: { mode: "fetch", url, title: "(error)", contentType: "unknown", length: 0, truncated: false } as FetchDetails,
					isError: true,
				};
			}

			const truncated = result.text.length > maxLength;
			const text = truncated
				? result.text.slice(0, maxLength) + `\n\n[... truncated at ${maxLength} characters]`
				: result.text;

			const header = `Title: ${result.title}\nSource: ${url}\nContent-Type: ${result.contentType}\n${"-".repeat(50)}\n\n`;

			return {
				content: [{ type: "text", text: header + text }],
				details: { mode: "fetch", url, title: result.title, contentType: result.contentType, length: text.length, truncated } as FetchDetails,
			};
		},
	});

	// ── Tool: web_research ────────────────────────────────────────────
	pi.registerTool({
		name: "web_research",
		label: "Web Research",
		description:
			"Combined research tool: search DuckDuckGo, then fetch and extract text from the top results.",
		parameters: WebResearchParams,

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			const { query, depth = 3, maxSearchResults = 8 } = params;

			// Phase 1: Search
			let searchResults: SearchResult[];
			try {
				searchResults = await searchDdg(query, Math.min(maxSearchResults, MAX_SEARCH_RESULTS));
			} catch (e) {
				return {
					content: [{ type: "text", text: `Search failed: ${e instanceof Error ? e.message : "unknown error"}` }],
					details: { mode: "research", query, searchResults: [], fetched: [] } as ResearchDetails,
					isError: true,
				};
			}

			if (searchResults.length === 0) {
				return {
					content: [{ type: "text", text: "No search results found." }],
					details: { mode: "research", query, searchResults: [], fetched: [] } as ResearchDetails,
				};
			}

			// Phase 2: Fetch top results
			const toFetch = searchResults.slice(0, Math.min(depth, 5));
			const fetched: ResearchDetails["fetched"] = [];
			const fetchErrors: string[] = [];

			for (const r of toFetch) {
				try {
					const result = await fetchUrl(r.url);
					fetched.push({ url: r.url, title: result.title, success: true, length: result.text.length });
				} catch (e) {
					const msg = e instanceof Error ? e.message : "unknown error";
					fetched.push({ url: r.url, title: r.title, success: false, error: msg, length: 0 });
					fetchErrors.push(`  ❌ ${r.title}: ${msg}`);
				}
			}

			// Build response
			const lines: string[] = [];
			lines.push(`# Research: "${query}"`);
			lines.push("");
			lines.push(`## Search Results (${searchResults.length})`);
			lines.push("");
			for (let i = 0; i < searchResults.length; i++) {
				const r = searchResults[i];
				lines.push(`${i + 1}. **${r.title}**`);
				lines.push(`   ${r.url}`);
				if (r.snippet) lines.push(`   > ${r.snippet}`);
				lines.push("");
			}

			const successfulFetches = fetched.filter((f) => f.success);
			if (successfulFetches.length > 0) {
				lines.push(`## Fetched Content (${successfulFetches.length}/${toFetch.length})`);
				lines.push("");
				for (const f of successfulFetches) {
					lines.push(`### ${f.title}`);
					lines.push(`Source: ${f.url}`);
					lines.push("");
				}
			}

			if (fetchErrors.length > 0) {
				lines.push("## Fetch Errors");
				lines.push("");
				lines.push(...fetchErrors);
			}

			return {
				content: [{ type: "text", text: lines.join("\n").trim() }],
				details: { mode: "research", query, searchResults, fetched } as ResearchDetails,
			};
		},
	});

	// ── Command: /websearch for quick searches ─────────────────────────
	pi.registerCommand("websearch", {
		description: "Quick DuckDuckGo search. Usage: /websearch <query>",
		handler: async (args, ctx) => {
			if (!args.trim()) {
				ctx.ui.notify("Usage: /websearch <query>", "error");
				return;
			}

			ctx.ui.setStatus("websearch", "🔍 Searching DuckDuckGo...");

			try {
				const results = await searchDdg(args.trim(), 5);
				ctx.ui.setStatus("websearch", "");

				if (results.length === 0) {
					ctx.ui.notify("No results found.", "info");
					return;
				}

				const lines = results.map(
					(r, i) => `${i + 1}. ${r.title}\n   ${r.url}\n   ${r.snippet || "(no snippet)"}`,
				);
				ctx.ui.notify(lines.join("\n\n"), "info");
			} catch (e) {
				ctx.ui.setStatus("websearch", "");
				ctx.ui.notify(`Search failed: ${e instanceof Error ? e.message : "unknown error"}`, "error");
			}
		},
	});
}