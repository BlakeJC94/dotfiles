/**
 * nvim-editor-improved
 *
 * Opens the current Pi prompt in real nvim, with a read-only, condensed
 * snapshot of the conversation (everything since the last compaction) in a
 * split above the editable prompt buffer. Pi is suspended while nvim owns the
 * terminal, so the user's own init.lua, plugins, and keymaps all apply.
 *
 * Outcomes:
 * - `:wqa` (or `:PiSubmit`) -> submit the edited text as the next prompt
 * - `:PiEdit`               -> put the edited text back in Pi's editor
 * - `:cq` (or `:PiCancel`)  -> cancel, keeping the previous Pi prompt
 *
 * Triggered by the `/vim` command or `Alt+G`. The built-in `Ctrl+G` external
 * editor (app.editor.external) is left untouched: Pi reserves that keybinding
 * for extensions, so it cannot be overridden here.
 */

import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionContext, SessionEntry } from "@earendil-works/pi-coding-agent";

const LUA_SHIM = fileURLToPath(new URL("./pi-context.lua", import.meta.url));

/** Total line budget for the rendered context snapshot. */
const MAX_CONTEXT_LINES = 4000;
/** Lines kept from each tool result before truncating. */
const MAX_TOOL_RESULT_LINES = 12;
/** Characters kept from a tool call's serialized arguments. */
const MAX_TOOL_ARG_CHARS = 160;

type Outcome = "submit" | "edit" | "cancel";

/** Loosely-typed view over the session message union for rendering. */
interface AnyMessage {
	role?: string;
	content?: unknown;
	toolName?: string;
	isError?: boolean;
	command?: string;
	output?: string;
	customType?: string;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("vim", {
		description: "Edit the prompt in nvim with conversation context",
		handler: (_args, ctx) => runFlow(pi, ctx),
	});

	pi.registerShortcut("alt+g", {
		description: "Edit the prompt in nvim with conversation context",
		handler: (ctx) => runFlow(pi, ctx),
	});
}

async function runFlow(pi: ExtensionAPI, ctx: ExtensionContext): Promise<void> {
	if (ctx.mode !== "tui") {
		ctx.ui.notify("vim editor requires interactive mode", "error");
		return;
	}
	if (!existsSync(LUA_SHIM)) {
		ctx.ui.notify(`nvim-editor-improved: cannot find ${LUA_SHIM}`, "error");
		return;
	}

	const prompt = ctx.ui.getEditorText();
	let result: { outcome: Outcome; text: string } | undefined;

	try {
		await ctx.ui.custom<void>((tui, _theme, _keybindings, done) => {
			tui.stop();
			process.stdout.write("\x1b[2J\x1b[H");
			try {
				result = openInNvim(ctx, prompt);
			} finally {
				tui.start();
				tui.requestRender(true);
				done();
			}
			return { render: () => [], invalidate: () => {} };
		});
	} catch (error) {
		ctx.ui.notify(`nvim-editor-improved: ${error instanceof Error ? error.message : String(error)}`, "error");
		return;
	}

	if (!result || result.outcome === "cancel") return;

	if (result.outcome === "edit") {
		ctx.ui.setEditorText(result.text);
		return;
	}

	// Submit. Clear the Pi editor first so a sent prompt is not left behind.
	const text = result.text.trim();
	ctx.ui.setEditorText("");
	if (!text) return;

	if (ctx.isIdle()) {
		pi.sendUserMessage(text, { expandPromptTemplates: true });
		ctx.ui.notify("Prompt sent", "info");
	} else {
		pi.sendUserMessage(text, { deliverAs: "steer", expandPromptTemplates: true });
		ctx.ui.notify("Prompt steered into the running turn", "info");
	}
}

/** Write the prompt and context to a temp dir and hand the terminal to nvim. */
function openInNvim(ctx: ExtensionContext, prompt: string): { outcome: Outcome; text: string } {
	const dir = mkdtempSync(join(tmpdir(), "pi-nvim-"));
	const contextPath = join(dir, "context.md");
	const promptPath = join(dir, "prompt.md");
	const outcomePath = join(dir, "outcome");

	try {
		writeFileSync(contextPath, renderContext(ctx), "utf8");
		writeFileSync(promptPath, prompt, "utf8");

		const result = spawnSync("nvim", ["-c", "lua dofile(vim.env.PI_NVIM_LUA)", promptPath], {
			stdio: "inherit",
			env: {
				...process.env,
				PI_NVIM_CONTEXT: contextPath,
				PI_NVIM_PROMPT: promptPath,
				PI_NVIM_OUTCOME: outcomePath,
				PI_NVIM_LUA: LUA_SHIM,
			},
		});

		if (result.error) {
			throw new Error(`failed to launch nvim: ${result.error.message}`);
		}
		if (result.status !== 0) {
			// Non-zero exit (`:cq`, crash, signal) means cancel.
			return { outcome: "cancel", text: prompt };
		}

		const text = existsSync(promptPath) ? readFileSync(promptPath, "utf8").replace(/\n$/, "") : prompt;
		let outcome: Outcome = "submit";
		if (existsSync(outcomePath)) {
			const raw = readFileSync(outcomePath, "utf8").trim();
			if (raw === "submit" || raw === "edit" || raw === "cancel") outcome = raw;
		}
		return { outcome, text };
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
}

// --- Context rendering -----------------------------------------------------

/** Render the compaction-aware conversation window the model sees. */
function renderContext(ctx: ExtensionContext): string {
	const blocks: string[][] = [];
	for (const entry of ctx.sessionManager.buildContextEntries()) {
		const block = renderEntry(entry);
		if (block.length > 0) blocks.push(block);
	}

	const header = [
		"# Conversation context",
		"",
		"_Read-only snapshot since the last compaction. Your prompt is the window below._",
		"_Submit with `:wqa`, return to Pi's editor with `:PiEdit`, cancel with `:cq`._",
		"",
	];

	const chosen: string[][] = [];
	let used = header.length;
	for (let i = blocks.length - 1; i >= 0; i--) {
		const block = blocks[i]!;
		if (chosen.length > 0 && used + block.length > MAX_CONTEXT_LINES) {
			chosen.unshift(["", "_…older turns omitted to keep the snapshot small…_", ""]);
			break;
		}
		chosen.unshift(block);
		used += block.length;
	}

	return [...header, ...chosen.flat()].join("\n");
}

function renderEntry(entry: SessionEntry): string[] {
	switch (entry.type) {
		case "compaction":
			return ["## ⏮ compaction summary", "", entry.summary.trim(), ""];
		case "branch_summary":
			return ["## ⏮ branch summary", "", entry.summary.trim(), ""];
		case "custom_message": {
			const text = contentToText(entry.content).trim();
			return text ? [`## ${entry.customType}`, "", text, ""] : [];
		}
		case "message":
			return renderMessage(entry.message as unknown as AnyMessage);
		default:
			return [];
	}
}

function renderMessage(message: AnyMessage): string[] {
	switch (message.role) {
		case "user": {
			const text = contentToText(message.content).trim();
			return text ? ["## 🧑 user", "", text, ""] : [];
		}
		case "assistant": {
			const lines = ["## 🤖 assistant", ""];
			const blocks = Array.isArray(message.content) ? message.content : [];
			for (const block of blocks) {
				if (!block || typeof block !== "object") continue;
				const b = block as { type?: string; text?: string; name?: string; arguments?: unknown };
				if (b.type === "text" && typeof b.text === "string") {
					lines.push(b.text.trimEnd());
				} else if (b.type === "toolCall" && typeof b.name === "string") {
					lines.push(`- 🔧 ${b.name}(${formatArgs(b.arguments)})`);
				}
			}
			lines.push("");
			return lines;
		}
		case "toolResult": {
			const body = contentToText(message.content).trimEnd();
			const label = `- ↩ ${message.toolName ?? "tool"}${message.isError ? " (error)" : ""}:`;
			return [label, "```", truncateLines(body, MAX_TOOL_RESULT_LINES), "```", ""];
		}
		case "bashExecution": {
			if (typeof message.output !== "string") return [];
			return [
				`- $ ${message.command ?? ""}`,
				"```",
				truncateLines(message.output.trimEnd(), MAX_TOOL_RESULT_LINES),
				"```",
				"",
			];
		}
		case "custom": {
			const text = contentToText(message.content).trim();
			return text ? [`## ${message.customType ?? "note"}`, "", text, ""] : [];
		}
		default:
			return [];
	}
}

function contentToText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	const parts: string[] = [];
	for (const block of content) {
		if (!block || typeof block !== "object") continue;
		const b = block as { type?: string; text?: string };
		if (b.type === "text" && typeof b.text === "string") parts.push(b.text);
		else if (b.type === "image") parts.push("[image]");
	}
	return parts.join("\n");
}

function formatArgs(args: unknown): string {
	if (args === undefined || args === null) return "";
	let text: string;
	try {
		text = typeof args === "string" ? args : JSON.stringify(args);
	} catch {
		text = String(args);
	}
	if (text.length > MAX_TOOL_ARG_CHARS) text = `${text.slice(0, MAX_TOOL_ARG_CHARS)}…`;
	return text;
}

function truncateLines(text: string, maxLines: number): string {
	const lines = text.split("\n");
	if (lines.length <= maxLines) return text;
	const omitted = lines.length - maxLines;
	return [...lines.slice(0, maxLines), `… (+${omitted} more line${omitted === 1 ? "" : "s"})`].join("\n");
}
