/**
 * Prompt Injection Guard Extension
 *
 * Scans tool inputs and outputs for prompt injection patterns using
 * regex heuristics. Blocks tool calls that attempt to inject instructions
 * and sanitizes outputs that contain potential injection content.
 *
 * No external dependencies — pure regex.
 *
 * Configuration (via /injection-guard or config file):
 *   mode: "block" | "warn" | "audit"
 *     block (default) - prevent the tool call / sanitize the result
 *     warn           - allow but flag in the output
 *     audit          - log to stderr but take no action
 *
 *   inputCheck: boolean (default: true)
 *     Check tool input parameters for injection patterns.
 *
 *   outputCheck: boolean (default: true)
 *     Check tool result content for injection patterns.
 *
 *   toolFilters: string[] (default: [])
 *     Only check these tools. Empty = check all.
 *
 * Usage:
 *   /injection-guard              — show settings & help
 *   /injection-guard mode block   — set mode
 *   /injection-guard test "text"  — test a string
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import { readFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

// ─── Config ───────────────────────────────────────────────────────────────────

interface GuardConfig {
	mode: "block" | "warn" | "audit";
	inputCheck: boolean;
	outputCheck: boolean;
	toolFilters: string[];
}

const DEFAULT_CONFIG: GuardConfig = {
	mode: "block",
	inputCheck: true,
	outputCheck: true,
	toolFilters: [],
};

// ─── Detection Patterns ────────────────────────────────────────────────────────

interface InjectionPattern {
	pattern: RegExp;
	label: string;
	severity: "high" | "medium" | "low";
}

const INJECTION_PATTERNS: InjectionPattern[] = [
	// ── HIGH: Direct instruction override attempts ──
	{
		pattern: /ignore\s+(all\s+)?(previous|above|prior|earlier|the\s+above)\s+(instructions?|directives?|commands?|rules?|directions?|orders?)/i,
		label: "instruction-override",
		severity: "high",
	},
	{
		pattern: /disregard\s+(all\s+)?(previous|above|prior|earlier|the\s+above)\s+(instructions?|directives?|commands?|rules?|directions?|orders?)/i,
		label: "instruction-disregard",
		severity: "high",
	},
	{
		pattern: /forget\s+(all\s+)?(previous|above|prior|earlier|the\s+above)\s+(instructions?|directives?|commands?|rules?)/i,
		label: "instruction-forget",
		severity: "high",
	},
	{
		pattern: /override\s+(all\s+)?(previous|above|prior|earlier|the\s+above)\s+(instructions?|directives?|commands?|rules?)/i,
		label: "instruction-override-v2",
		severity: "high",
	},

	// ── HIGH: Role/identity hijacking ──
	{
		pattern: /from\s+now\s+on\s*,\s*you\s+(are|will\s+be|shall\s+be|must\s+act|should\s+act|are\s+going\s+to\s+act)/i,
		label: "role-hijack",
		severity: "high",
	},
	{
		pattern: /you\s+(are|will\s+now\s+be|must\s+now\s+act)\s+(as\s+)?(a\s+|an\s+)?(new\s+)?(role|persona|character|identity|version|instance)\b/i,
		label: "role-change",
		severity: "high",
	},
	{
		pattern: /your\s+(new\s+)?(role|persona|identity|name)\s+(is|will\s+be|should\s+be)/i,
		label: "role-assign",
		severity: "high",
	},
	{
		pattern: /pretend\s+(that\s+)?you\s+(are|were)/i,
		label: "pretend-role",
		severity: "high",
	},

	// ── HIGH: System prompt manipulation ──
	{
		pattern: /\byou\s+are\s+now\s+in\s+(developer|system|configuration|admin|root)\s+mode\b/i,
		label: "mode-elevation",
		severity: "high",
	},
	{
		pattern: /\[\s*(SYSTEM|SYS|INST|INSTRUCTION|DIRECTIVE)\s*\]/i,
		label: "system-marker",
		severity: "high",
	},
	{
		pattern: /\byour\s+(new\s+)?(instructions?|directives?|commands?|rules?)\s+(are|have\s+changed|will\s+be)/i,
		label: "your-instructions-changed",
		severity: "high",
	},

	// ── MEDIUM: Suspicious redirection ──
	{
		pattern: /do\s+not\s+(output|respond|reply|answer|print|display|show|reveal)\s+(anything|the\s+(above|previous|instructions)|what\s+(was|i)\s+(said|wrote|typed|asked))/i,
		label: "output-suppression",
		severity: "medium",
	},
	{
		pattern: /output\s+(only|just|exactly|strictly)\s+(the|a|your)\s+(word|letter|number|text|response).*?(and\s+nothing\s+else)/i,
		label: "output-restriction",
		severity: "medium",
	},
	{
		pattern: /repeat\s+(after\s+me|the\s+(above|previous)\s+(text|message|content)|everything\s+(above|below))/i,
		label: "repeat-attack",
		severity: "medium",
	},
	{
		pattern: /begin\s+(your\s+)?(response|output|answer|reply)\s+(with|by|using)/i,
		label: "output-prefix",
		severity: "medium",
	},

	// ── MEDIUM: Token smuggling / encoded payloads ──
	{
		pattern: /(base64|base32|hex)\s*(decode|encod(?:e|ed))\s*(the\s+)?(following|this|below|content)/i,
		label: "encoded-instruction",
		severity: "medium",
	},
	{
		pattern: /(reverse|rot13|caesar|cipher)\s*(the\s+)?(following|this|below|string|text)/i,
		label: "ciphered-instruction",
		severity: "medium",
	},

	// ── LOW: Chat template / token boundary markers ──
	{
		pattern: /<\|im_start\|>\s*(system|user|assistant|tool)/i,
		label: "chat-template-start",
		severity: "low",
	},
	{
		pattern: /<\|im_end\|>/i,
		label: "chat-template-end",
		severity: "low",
	},
	{
		pattern: /<\|(system|user|assistant|tool)\|>/i,
		label: "compact-template-marker",
		severity: "low",
	},
];

// ─── Helpers ───────────────────────────────────────────────────────────────────

function checkForInjection(text: string): { label: string; severity: string; match: string } | null {
	for (const { pattern, label, severity } of INJECTION_PATTERNS) {
		const match = text.match(pattern);
		if (match) {
			return { label, severity, match: match[0].slice(0, 120) };
		}
	}
	return null;
}

/** Recursively extract all string values from an object (up to 5 levels deep). */
function extractStringValues(obj: unknown, depth = 0): string[] {
	if (depth > 5) return [];
	if (typeof obj === "string") return [obj];
	if (typeof obj === "object" && obj !== null) {
		const results: string[] = [];
		for (const value of Object.values(obj as Record<string, unknown>)) {
			results.push(...extractStringValues(value, depth + 1));
		}
		return results;
	}
	return [];
}

/** Collect all string parameters from a tool call input object. */
function collectToolInput(event: { input: Record<string, unknown> }): string[] {
	const strings: string[] = [];
	for (const value of Object.values(event.input)) {
		if (typeof value === "string") {
			strings.push(value);
		} else if (typeof value === "object" && value !== null) {
			strings.push(...extractStringValues(value));
		}
	}
	return strings;
}

/** Collect text content from a tool result. */
function collectToolResultText(event: { content?: Array<{ type: string; text?: string }> }): string[] {
	return (event.content ?? [])
		.filter((c): c is { type: string; text: string } => c.type === "text" && typeof c.text === "string")
		.map((c) => c.text);
}

// ─── Config Persistence ────────────────────────────────────────────────────────

function configPath(): string {
	return join(getAgentDir(), "extensions", "prompt-injection-guard.json");
}

function loadConfig(): GuardConfig {
	const path = configPath();
	try {
		if (existsSync(path)) {
			const raw = JSON.parse(readFileSync(path, "utf-8"));
			return { ...DEFAULT_CONFIG, ...raw };
		}
	} catch {
		// Fall through to default
	}
	return { ...DEFAULT_CONFIG };
}

function saveConfig(config: GuardConfig): void {
	const path = configPath();
	const dir = join(getAgentDir(), "extensions");
	if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
	writeFileSync(path, JSON.stringify(config, null, 2), "utf-8");
}

// ─── UI Formatting ─────────────────────────────────────────────────────────────

function formatMatch(
	ctx: ExtensionContext,
	toolName: string,
	target: "input" | "output",
	result: { label: string; severity: string; match: string },
): string {
	const severityIcon =
		result.severity === "high" ? "[H]" :
		result.severity === "medium" ? "[M]" :
		"[L]";

	return `${severityIcon} [${result.severity}] "${result.label}" in ${toolName} ${target}: "${result.match}"`;
}

// ─── Extension ─────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	const config = loadConfig();

	// ── Startup notification ──────────────────────────────────────────────

	pi.on("session_start", async (_event, ctx) => {
		const modeIcon =
			config.mode === "block" ? "[BLOCK]" :
			config.mode === "warn" ? "[WARN]" :
			"[AUDIT]";

		const parts: string[] = [];
		if (config.inputCheck) parts.push("input");
		if (config.outputCheck) parts.push("output");

		ctx.ui.setStatus(
			"injection-guard",
			`${modeIcon} guard:${config.mode} (${parts.join("+")})${config.toolFilters.length ? ` filter:[${config.toolFilters.join(",")}]` : ""}`,
		);

		if (ctx.hasUI) {
			ctx.ui.notify(
				`Injection guard active — mode: ${config.mode}, checking: ${parts.join(" + ")}`,
				"info",
			);
		}
	});

	// ── Tool input vetting ────────────────────────────────────────────────

	pi.on("tool_call", async (event, ctx) => {
		if (!config.inputCheck) return;
		if (config.toolFilters.length > 0 && !config.toolFilters.includes(event.toolName)) return;

		const strings = collectToolInput(event as unknown as { input: Record<string, unknown> });

		for (const text of strings) {
			const result = checkForInjection(text);
			if (!result) continue;

			const message = formatMatch(ctx, event.toolName, "input", result);

			switch (config.mode) {
				case "block": {
					if (ctx.hasUI) ctx.ui.notify(`Blocked — injection in tool input: ${message}`, "error");
					return {
						block: true,
						reason: `[InjectionGuard] Prompt injection detected in ${event.toolName} input: [${result.severity}] ${result.label} (matched: "${result.match}")`,
					};
				}
				case "warn": {
					if (ctx.hasUI) ctx.ui.notify(`Warning — ${message}`, "warning");
					return; // Allow but notify
				}
				case "audit": {
					console.error(`[InjectionGuard] ${message}`);
					return;
				}
			}
		}
	});

	// ── Tool output vetting ───────────────────────────────────────────────

	pi.on("tool_result", async (event, ctx) => {
		if (!config.outputCheck) return;
		if (config.toolFilters.length > 0 && !config.toolFilters.includes(event.toolName)) return;

		const texts = collectToolResultText(event as unknown as { content?: Array<{ type: string; text?: string }> });

		for (const text of texts) {
			const result = checkForInjection(text);
			if (!result) continue;

			const message = formatMatch(ctx, event.toolName, "output", result);

			switch (config.mode) {
				case "block": {
					if (ctx.hasUI) ctx.ui.notify(`Sanitized — injection in tool output: ${message}`, "error");
					return {
						content: [
							{
								type: "text" as const,
								text: [
									`[InjectionGuard: Output suppressed — ${result.severity} severity]`,
									`Pattern: ${result.label}`,
									`Matched: "${result.match}"`,
									"The output was blocked to protect agent integrity.",
								].join("\n"),
							},
						],
						details: {
							...event.details,
							injectionGuard: {
								action: "blocked",
								severity: result.severity,
								pattern: result.label,
								match: result.match,
							},
						},
						isError: true,
					};
				}
				case "warn": {
					if (ctx.hasUI) ctx.ui.notify(`Warning — ${message}`, "warning");
					// Append a warning marker to the content without blocking
					const warningBlock = {
						type: "text" as const,
						text: `\n\n[InjectionGuard Warning: potential prompt injection detected — ${result.label}]`,
					};
					return {
						content: [...(event.content ?? []), warningBlock],
					};
				}
				case "audit": {
					console.error(`[InjectionGuard] ${message}`);
					return;
				}
			}
		}
	});

	// ── Command: View / Configure ─────────────────────────────────────────

	pi.registerCommand("injection-guard", {
		description: "Show or configure prompt injection guard settings",
		handler: async (args, ctx) => {
			const trimmedArgs = (args ?? "").trim();

			// Re-read config on each command invocation so changes are reflected
			const currentConfig = loadConfig();

			const showHelp = () => {
				const lines = [
					"Prompt Injection Guard",
					"",
					`mode:           ${currentConfig.mode}`,
					`inputCheck:     ${currentConfig.inputCheck}`,
					`outputCheck:    ${currentConfig.outputCheck}`,
					`toolFilters:    ${currentConfig.toolFilters.length ? currentConfig.toolFilters.join(", ") : "(all tools)"}`,
					"",
					`Patterns (${INJECTION_PATTERNS.length} total):`,
					...INJECTION_PATTERNS.map((p) => `  [${p.severity}] ${p.label}`),
					"",
					"Commands:",
					"  /injection-guard                        — show this help",
					"  /injection-guard mode <block|warn|audit>",
					"  /injection-guard inputCheck <true|false>",
					"  /injection-guard outputCheck <true|false>",
					"  /injection-guard toolFilters <t1,t2,...> — empty = check all",
					"  /injection-guard test <text>             — test a string against patterns",
				];
				ctx.ui.notify(lines.join("\n"), "info");
			};

			if (!trimmedArgs) {
				showHelp();
				return;
			}

			const parts = trimmedArgs.split(/\s+/);
			const changedConfig = { ...currentConfig };
			let changed = false;

			if (parts[0] === "mode" && parts[1]) {
				const mode = parts[1] as GuardConfig["mode"];
				if (!["block", "warn", "audit"].includes(mode)) {
					ctx.ui.notify(`Invalid mode: ${mode}. Use block, warn, or audit.`, "error");
					return;
				}
				changedConfig.mode = mode;
				changed = true;
			} else if (parts[0] === "inputCheck" && parts[1]) {
				changedConfig.inputCheck = parts[1] === "true";
				changed = true;
			} else if (parts[0] === "outputCheck" && parts[1]) {
				changedConfig.outputCheck = parts[1] === "true";
				changed = true;
			} else if (parts[0] === "toolFilters") {
				const filterStr = parts.slice(1).join("");
				changedConfig.toolFilters = filterStr ? filterStr.split(",").map((s) => s.trim()).filter(Boolean) : [];
				changed = true;
			} else if (parts[0] === "test" && parts.slice(1).join(" ")) {
				const testText = parts.slice(1).join(" ");
				const result = checkForInjection(testText);
				if (result) {
					ctx.ui.notify(
						`Matched: [${result.severity}] ${result.label}\n   "${result.match}"`,
						"warning",
					);
				} else {
					ctx.ui.notify("No injection patterns detected", "info");
				}
				return;
			} else {
				ctx.ui.notify(`Unknown command: ${trimmedArgs}`, "error");
				showHelp();
				return;
			}

			if (changed) {
				// Merge with persisted config so non-overridden fields survive
				const persisted = loadConfig();
				const merged = { ...persisted, ...changedConfig };
				saveConfig(merged);

				const diff = Object.entries(changedConfig)
					.filter(([k, v]) => JSON.stringify(v) !== JSON.stringify(currentConfig[k as keyof GuardConfig]))
					.map(([k, v]) => `${k}=${JSON.stringify(v)}`)
					.join(", ");
				ctx.ui.notify(`Updated: ${diff}`, "info");

				// Update the status indicator
				const modeIcon =
					merged.mode === "block" ? "[BLOCK]" :
					merged.mode === "warn" ? "[WARN]" :
					"[AUDIT]";
				const checkParts: string[] = [];
				if (merged.inputCheck) checkParts.push("input");
				if (merged.outputCheck) checkParts.push("output");
				ctx.ui.setStatus(
					"injection-guard",
					`${modeIcon} guard:${merged.mode} (${checkParts.join("+")})${merged.toolFilters.length ? ` filter:[${merged.toolFilters.join(",")}]` : ""}`,
				);
			}
		},
	});
}