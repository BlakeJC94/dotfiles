/**
 * pi-file-snapshots — git-free file-state checkpoints for pi.
 *
 * This module wires pi's lifecycle events and `/snapshots` command to the
 * pure store logic in `store.ts`. It never commits anything to git; the
 * snapshot store lives entirely outside the repo.
 */

import * as path from "node:path";
import * as crypto from "node:crypto";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
	capture,
	hasSnapshots,
	listEntryIds,
	readManifest,
	restoreEntry,
} from "./store.ts";
import { entryDir, sessionDir, storeRoot } from "./paths.ts";

/**
 * Derive a stable per-session id for the store.
 *
 * Real sessions expose a UUID via `getSessionId()`; ephemeral/in-memory
 * sessions fall back to a hash of the session file path, or a fixed
 * `ephemeral` bucket. Exported for testing.
 */
export function sessionIdOf(ctx: ExtensionContext): string {
	const sm = ctx.sessionManager;
	const id = sm.getSessionId();
	if (id) return id;
	const file = sm.getSessionFile();
	if (file) return crypto.createHash("sha1").update(file).digest("hex").slice(0, 12);
	return "ephemeral";
}

/** Current leaf entry id, if any. Exported for testing. */
export function currentEntryId(ctx: ExtensionContext): string | undefined {
	return ctx.sessionManager.getLeafEntry()?.id;
}

/**
 * A short, human-readable label for an entry, for the `/snapshots` picker.
 * Exported for testing.
 */
export function labelForEntry(ctx: ExtensionContext, id: string): string {
	const entry = ctx.sessionManager.getEntry(id);
	if (!entry) return `${id} (entry not in current branch)`;

	if (entry.type === "message") {
		const msg = (entry as { message?: { role?: string; content?: unknown } })
			.message;
		if (!msg) return `${id} [message]`;

		const role = msg.role ?? "?";
		let snippet = "";
		if (typeof msg.content === "string") {
			snippet = msg.content;
		} else if (Array.isArray(msg.content)) {
			const first = msg.content[0] as { text?: string } | undefined;
			snippet = first?.text ?? "";
		}
		snippet = snippet.replace(/\s+/g, " ").trim().slice(0, 60);
		return `${id} [${role}] ${snippet}`;
	}
	return `${id} [${entry.type}]`;
}

export default function fileSnapshots(pi: ExtensionAPI): void {
	const root = storeRoot();

	// In-memory manifest cache, rehydrated lazily from disk. Dropped on
	// session shutdown so it can't go stale across runtime rebinds.
	const manifestCache = new Map<string, Map<string, boolean>>();

	async function manifestFor(
		ctx: ExtensionContext,
		entryId: string,
	): Promise<Map<string, boolean>> {
		const cached = manifestCache.get(entryId);
		if (cached) return cached;
		const dir = entryDir(root, sessionIdOf(ctx), entryId);
		const manifest = await readManifest(dir);
		manifestCache.set(entryId, manifest);
		return manifest;
	}

	// --- Capture pre-edit state on every write / edit ---

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "write" && event.toolName !== "edit") return;

		const relPath = (event.input as { path?: string }).path;
		if (!relPath || typeof relPath !== "string") return;

		const absPath = path.resolve(ctx.cwd, relPath);
		const entryId = currentEntryId(ctx);
		if (!entryId) return;

		const dir = entryDir(root, sessionIdOf(ctx), entryId);
		const record = await capture(dir, absPath);
		if (record) {
			const manifest = manifestCache.get(entryId);
			manifest?.set(absPath, record.absent);
		}
	});

	// --- /snapshots command ---

	pi.registerCommand("snapshots", {
		description:
			"List conversation entries that changed files and restore the working tree to one",
		async handler(_args, ctx) {
			if (!ctx.hasUI) {
				ctx.ui.notify("/snapshots requires interactive mode", "warning");
				return;
			}

			const sessionPath = sessionDir(root, sessionIdOf(ctx));
			const ids = await listEntryIds(sessionPath);

			type Row = { id: string; label: string; files: string[] };
			const rows: Row[] = [];
			for (const id of ids) {
				const manifest = await manifestFor(ctx, id);
				const files = [...manifest.keys()].map((p) =>
					path.relative(ctx.cwd, p),
				);
				if (files.length === 0) continue;
				rows.push({ id, label: labelForEntry(ctx, id), files });
			}

			if (rows.length === 0) {
				ctx.ui.notify(
					"No file snapshots recorded yet for this session.",
					"info",
				);
				return;
			}

			// Newest first.
			rows.sort((a, b) => b.id.localeCompare(a.id));

			const options = rows.map(
				(r) =>
					`${r.label}  —  ${r.files.length} file${r.files.length === 1 ? "" : "s"}`,
			);
			const choice = await ctx.ui.select(
				"Restore working tree to state at entry:",
				options,
			);
			if (!choice) return;

			const idx = options.indexOf(choice);
			if (idx < 0) return;
			const target = rows[idx];
			if (!target) return;

			const ok = await ctx.ui.confirm(
				`Restore ${target.files.length} file(s) to state at ${target.id}?`,
				"This overwrites current working-tree files with snapshot copies (no git involved). Files created after that point will be deleted.",
			);
			if (!ok) return;

			const dir = entryDir(root, sessionIdOf(ctx), target.id);
			const res = await restoreEntry(dir, ctx.cwd);
			ctx.ui.notify(
				`Restored ${res.restored} file(s), deleted ${res.deleted}${res.warnings.length ? ` (${res.warnings.length} warnings)` : ""}.`,
				res.warnings.length ? "warning" : "info",
			);
		},
	});

	// --- Offer to restore on /fork (mirrors pi's git-checkpoint.ts) ---

	pi.on("session_before_fork", async (event, ctx) => {
		if (!ctx.hasUI) return; // never auto-restore in non-interactive mode

		const targetId = event.entryId;
		const manifest = await manifestFor(ctx, targetId);
		if (manifest.size === 0) return;

		const choice = await ctx.ui.select("Restore file state to this fork point?", [
			"Yes, restore files to that point",
			"No, keep current files",
		]);
		if (!choice?.startsWith("Yes")) return;

		const dir = entryDir(root, sessionIdOf(ctx), targetId);
		const res = await restoreEntry(dir, ctx.cwd);
		ctx.ui.notify(
			`Restored ${res.restored} file(s), deleted ${res.deleted} before fork.`,
			res.warnings.length ? "warning" : "info",
		);
	});

	// --- Drop in-memory state on shutdown (store stays on disk) ---

	pi.on("session_shutdown", () => {
		manifestCache.clear();
	});
}
