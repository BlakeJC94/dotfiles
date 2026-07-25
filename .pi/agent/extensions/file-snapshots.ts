/**
 * File Snapshot Extension
 *
 * Keeps an independent, git-free record of file state as the agent works,
 * so you can revert the working tree to the state it was in at any earlier
 * message in the conversation — without the agent ever touching git.
 *
 * How it works:
 *   - On every `write` / `edit` tool_call, the current on-disk version of the
 *     targeted file is copied into a side store BEFORE the tool runs.
 *   - Snapshots are keyed by session id and conversation entry id, so each
 *     entry remembers which files existed at that point and their contents.
 *   - A `/snapshots` command lists entries that changed files; pick one and
 *     the extension restores the working tree to that state.
 *   - On `/fork` (session_before_fork), it offers to restore code state to
 *     the fork point, mirroring the built-in git-checkpoint.ts pattern.
 *
 * Storage layout:
 *   ~/.pi/agent/file-snapshots/<sessionId>/<entryId>/<safePath>
 *
 * Notes / scope:
 *   - Only `write` and `edit` tool calls are captured. Changes made by the
 *     `bash` tool (sed, tee, redirects, etc.) are NOT snapshotted, by design.
 *   - Nothing is committed to git. The store lives entirely outside the repo.
 *   - The store accumulates over a session; deleted files are restored as
 *     deletions when reverting to a point before they existed.
 */

import { promises as fs } from "node:fs";
import * as path from "node:path";
import * as crypto from "node:crypto";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STORE_ROOT = path.join(
	process.env.HOME ?? "/tmp",
	".pi",
	"agent",
	"file-snapshots",
);

// Skip snapshotting for obviously-non-project paths that the agent might
// touch via write/edit. Keep this conservative — we only exclude things that
// would be pointless or dangerous to round-trip through the store.
const EXCLUDE_PREFIXES = ["/dev/", "/proc/", "/sys/"];

function sessionIdOf(ctx: ExtensionContext): string {
	// SessionManager.getSessionId() returns the session UUID; fall back to a
	// hash of the file path for in-memory/ephemeral sessions so the store is
	// still isolated.
	const sm = ctx.sessionManager;
	const id = sm.getSessionId();
	if (id) return id;
	const file = sm.getSessionFile();
	return file ? crypto.createHash("sha1").update(file).digest("hex").slice(0, 12) : "ephemeral";
}

function storeDir(ctx: ExtensionContext): string {
	return path.join(STORE_ROOT, sessionIdOf(ctx));
}

/**
 * Encode an arbitrary absolute path into a single safe filename component.
 * We keep it reversible so we can decode it back to the real path on restore.
 */
function encodePath(absPath: string): string {
	// Use a length-prefixed base64 of the absolute path. Prefix with the
	// length so collisions on suffix are impossible and decoding is exact.
	const b = Buffer.from(absPath, "utf8");
	return `${b.length.toString(36)}_${b.toString("base64url")}`;
}

function decodeName(name: string): string | null {
	const sep = name.indexOf("_");
	if (sep < 0) return null;
	const len = parseInt(name.slice(0, sep), 36);
	const b64 = name.slice(sep + 1);
	const buf = Buffer.from(b64, "base64url");
	if (buf.length !== len) return null;
	return buf.toString("utf8");
}

function shouldCapture(absPath: string): boolean {
	if (EXCLUDE_PREFIXES.some((p) => absPath.startsWith(p))) return false;
	return true;
}

async function snapshotFile(
	ctx: ExtensionContext,
	entryId: string,
	absPath: string,
): Promise<void> {
	if (!shouldCapture(absPath)) return;
	const dir = path.join(storeDir(ctx), entryId);
	await fs.mkdir(dir, { recursive: true });

	const dest = path.join(dir, encodePath(absPath));
	// If we already snapshotted this file for this entry (e.g. two writes to
	// the same file in one turn both pre-snapshot against the same on-disk
	// state), don't overwrite our first capture — that first copy is the
	// "before" state we want to restore.
	try {
		await fs.access(dest);
		return; // already have a snapshot for this entry
	} catch {
		// not present — proceed to copy
	}

	// Copy the current on-disk version if it exists. If it doesn't exist yet
	// (new file being created by `write`), record an empty marker so we know
	// this file did NOT exist at this entry and should be deleted on restore.
	let exists = true;
	try {
		await fs.access(absPath);
	} catch {
		exists = false;
	}

	if (exists) {
		// Copy the current on-disk version. Store growth is bounded by session
		// activity and you can `rm -rf` the store anytime.
		try {
			await fs.copyFile(absPath, dest);
		} catch {
			// best effort
		}
	} else {
		// File did not exist before this tool call. Write a marker so restore
		// knows to delete it.
		await fs.writeFile(dest, "", { flag: "w" });
		await fs.writeFile(dest + ".absent", "1", { flag: "w" });
	}
}

/**
 * Record that, as of `entryId`, the working tree had this set of captured
 * files. We append a small manifest alongside the file copies so `/snapshots`
 * can quickly list which entries touched which files without scanning dirs.
 */
async function recordManifest(
	ctx: ExtensionContext,
	entryId: string,
	absPath: string,
	absent: boolean,
): Promise<void> {
	const dir = path.join(storeDir(ctx), entryId);
	await fs.mkdir(dir, { recursive: true });
	const mf = path.join(dir, "manifest.jsonl");
	const line = JSON.stringify({ path: absPath, absent, ts: Date.now() }) + "\n";
	await fs.appendFile(mf, line, { flag: "a" });
}

/**
 * Find the snapshot entry id to associate a tool_call with.
 * We use the current leaf entry id at the time of the call.
 */
function currentEntryId(ctx: ExtensionContext): string | undefined {
	const leaf = ctx.sessionManager.getLeafEntry();
	return leaf?.id;
}

export default function (pi: ExtensionAPI) {
	// In-memory map: entryId -> { absPath: absent }
	// Rehydrated lazily from disk on demand.
	const changedFiles = new Map<string, Map<string, boolean>>();

	async function loadEntryIndex(ctx: ExtensionContext, entryId: string): Promise<Map<string, boolean>> {
		const existing = changedFiles.get(entryId);
		if (existing) return existing;
		const map = new Map<string, boolean>();
		const mf = path.join(storeDir(ctx), entryId, "manifest.jsonl");
		try {
			const txt = await fs.readFile(mf, "utf8");
			for (const line of txt.split("\n")) {
				if (!line.trim()) continue;
				try {
					const rec = JSON.parse(line) as { path: string; absent: boolean };
					map.set(rec.path, rec.absent);
				} catch {
					// ignore malformed
				}
			}
		} catch {
			// no manifest yet
		}
		changedFiles.set(entryId, map);
		return map;
	}

	async function recordChange(ctx: ExtensionContext, entryId: string, absPath: string, absent: boolean) {
		const map = await loadEntryIndex(ctx, entryId);
		if (!map.has(absPath)) map.set(absPath, absent);
	}

	// --- Capture pre-edit state on every write / edit ---

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "write" && event.toolName !== "edit") return;

		const relPath = (event.input as { path?: string }).path;
		if (!relPath || typeof relPath !== "string") return;

		const absPath = path.resolve(ctx.cwd, relPath);
		const entryId = currentEntryId(ctx);
		if (!entryId) return;

		// Determine if file currently exists (before the tool runs).
		let absent = true;
		try {
			await fs.access(absPath);
			absent = false;
		} catch {
			absent = true;
		}

		await snapshotFile(ctx, entryId, absPath);
		await recordManifest(ctx, entryId, absPath, absent);
		await recordChange(ctx, entryId, absPath, absent);
	});

	// --- Restore a single entry's file state into the working tree ---

	async function restoreEntry(ctx: ExtensionContext, targetEntryId: string): Promise<{ restored: number; deleted: number; warnings: string[] }> {
		const dir = path.join(storeDir(ctx), targetEntryId);
		const warnings: string[] = [];
		let restored = 0;
		let deleted = 0;

		let entries: string[];
		try {
			entries = await fs.readdir(dir);
		} catch {
			return { restored: 0, deleted: 0, warnings: [`No snapshots for entry ${targetEntryId}`] };
		}

		for (const name of entries) {
			if (name === "manifest.jsonl") continue;
			if (name.endsWith(".absent")) continue;

			const absPath = decodeName(name);
			if (!absPath) {
				warnings.push(`Could not decode snapshot name: ${name}`);
				continue;
			}

			const src = path.join(dir, name);
			const absentMarker = src + ".absent";

			let wasAbsent = false;
			try {
				await fs.access(absentMarker);
				wasAbsent = true;
			} catch {
				wasAbsent = false;
			}

			if (wasAbsent) {
				// The file did NOT exist at this point. Delete current copy if present.
				try {
					await fs.unlink(absPath);
					deleted++;
				} catch {
					// already absent — fine
				}
			} else {
				// Ensure parent dir exists, then copy the snapshot over the live file.
				try {
					await fs.mkdir(path.dirname(absPath), { recursive: true });
					await fs.copyFile(src, absPath);
					restored++;
				} catch (err) {
					warnings.push(`Failed to restore ${absPath}: ${(err as Error).message}`);
				}
			}
		}

		return { restored, deleted, warnings };
	}

	// --- /snapshots command ---

	pi.registerCommand("snapshots", {
		description: "List conversation entries that changed files and restore the working tree to one",
		async handler(_args, ctx) {
			if (!ctx.hasUI) {
				ctx.ui.notify("/snapshots requires interactive mode", "warning");
				return;
			}

			// Collect all entries that have a snapshot dir.
			const sdir = storeDir(ctx);
			let entryIds: string[];
			try {
				entryIds = await fs.readdir(sdir);
			} catch {
				ctx.ui.notify("No file snapshots recorded yet for this session.", "info");
				return;
			}

			if (entryIds.length === 0) {
				ctx.ui.notify("No file snapshots recorded yet for this session.", "info");
				return;
			}

			// Build a human-readable list mapping entryId -> a short label
			// (entry type + a snippet of the message at that point) and the
			// list of changed files.
			type Row = { id: string; label: string; files: string[] };
			const rows: Row[] = [];

			for (const id of entryIds) {
				const entry = ctx.sessionManager.getEntry(id);
				const manifest = await loadEntryIndex(ctx, id);
				const files = [...manifest.keys()].map((p) => path.relative(ctx.cwd, p));
				if (files.length === 0) continue;

				let label: string;
				if (!entry) {
					label = `${id} (entry not in current branch)`;
				} else if (entry.type === "message" && (entry as { message?: { role?: string; content?: unknown } }).message) {
					const msg = (entry as { message: { role?: string; content?: unknown } }).message;
					const role = msg.role ?? "?";
					let snippet = "";
					if (typeof msg.content === "string") snippet = msg.content;
					else if (Array.isArray(msg.content)) {
						const first = msg.content[0] as { text?: string } | undefined;
						snippet = first?.text ?? "";
					}
					snippet = snippet.replace(/\s+/g, " ").trim().slice(0, 60);
					label = `${id} [${role}] ${snippet}`;
				} else {
					label = `${id} [${entry.type}]`;
				}
				rows.push({ id, label, files });
			}

			if (rows.length === 0) {
				ctx.ui.notify("No file snapshots recorded yet for this session.", "info");
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

			const res = await restoreEntry(ctx, target.id);
			ctx.ui.notify(
				`Restored ${res.restored} file(s), deleted ${res.deleted}${res.warnings.length ? ` (${res.warnings.length} warnings)` : ""}.`,
				res.warnings.length ? "warning" : "info",
			);
		},
	});

	// --- Offer to restore on /fork (mirrors git-checkpoint.ts) ---

	pi.on("session_before_fork", async (event, ctx) => {
		if (!ctx.hasUI) return; // don't auto-restore in non-interactive mode

		const targetId = event.entryId;
		const manifest = await loadEntryIndex(ctx, targetId);
		if (manifest.size === 0) return; // nothing to restore at this point

		const choice = await ctx.ui.select("Restore file state to this fork point?", [
			"Yes, restore files to that point",
			"No, keep current files",
		]);

		if (choice?.startsWith("Yes")) {
			const res = await restoreEntry(ctx, targetId);
			ctx.ui.notify(
				`Restored ${res.restored} file(s), deleted ${res.deleted} before fork.`,
				res.warnings.length ? "warning" : "info",
			);
		}
	});

	// --- Tidy up on session shutdown ---

	pi.on("session_shutdown", async (event, ctx) => {
		// Keep the store on disk so it survives resume/reload, but drop the
		// in-memory index to avoid stale state after the runtime rebinds.
		changedFiles.clear();
		void event; void ctx;
	});
}
