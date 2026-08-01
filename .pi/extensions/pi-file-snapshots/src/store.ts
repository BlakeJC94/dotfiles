/**
 * Snapshot store: capture and restore on-disk file state, keyed by
 * conversation entry, with no dependency on git or pi's runtime context.
 *
 * The store is a directory tree:
 *
 *   <root>/<sessionId>/<entryId>/
 *     ├── manifest.jsonl              # one JSON line per captured file
 *     ├── <encodedPath>               # on-disk contents at capture time
 *     └── <encodedPath>.absent        # marker: file did NOT exist at capture
 *
 * Capture semantics: a snapshot for an entry records the file state *before*
 * the write/edit tool call that triggered it. Replaying an entry's snapshots
 * therefore restores the tree to the state just prior to that entry's
 * changes — i.e. "the state at that point in the conversation."
 */

import { promises as fs } from "node:fs";
import * as path from "node:path";
import {
	ABSENT_SUFFIX,
	decodeName,
	encodePath,
	entryDir,
	shouldCapture,
} from "./paths.ts";

/** One record in an entry's manifest. */
export interface ManifestRecord {
	/** Absolute path of the captured file. */
	path: string;
	/** `true` if the file did not exist at capture time (creation marker). */
	absent: boolean;
	/** Capture timestamp (Unix ms). */
	ts: number;
}

/** Result of restoring an entry's snapshots into the working tree. */
export interface RestoreResult {
	/** Number of files overwritten with snapshot contents. */
	restored: number;
	/** Number of files deleted (because they did not exist at that point). */
	deleted: number;
	/** Non-fatal problems encountered per file. */
	warnings: string[];
}

/** Whether a file currently exists on disk. */
async function fileExists(absPath: string): Promise<boolean> {
	try {
		await fs.access(absPath);
		return true;
	} catch {
		return false;
	}
}

/**
 * Capture the current on-disk state of `absPath` into `dir` (an entry dir).
 * Idempotent: if a snapshot for this path already exists in this entry, it
 * is preserved — the first capture is the "before" state we want to keep.
 *
 * @returns The manifest record describing what was captured.
 */
export async function snapshotFile(
	dir: string,
	absPath: string,
): Promise<ManifestRecord | null> {
	if (!shouldCapture(absPath)) return null;

	await fs.mkdir(dir, { recursive: true });
	const dest = path.join(dir, encodePath(absPath));

	// Already captured for this entry — keep the first (pre-change) copy.
	if (await fileExists(dest)) {
		return null;
	}

	const exists = await fileExists(absPath);
	const record: ManifestRecord = {
		path: absPath,
		absent: !exists,
		ts: Date.now(),
	};

	if (exists) {
		try {
			await fs.copyFile(absPath, dest);
		} catch {
			// best effort; manifest still records the intent
		}
	} else {
		// Empty body + absent marker so restore knows to delete on replay.
		await fs.writeFile(dest, "", { flag: "w" });
		await fs.writeFile(dest + ABSENT_SUFFIX, "1", { flag: "w" });
	}

	return record;
}

/** Append a manifest record for an entry. */
export async function appendManifest(
	dir: string,
	record: ManifestRecord,
): Promise<void> {
	await fs.mkdir(dir, { recursive: true });
	const mf = path.join(dir, "manifest.jsonl");
	const line = JSON.stringify(record) + "\n";
	await fs.appendFile(mf, line, { flag: "a" });
}

/**
 * Convenience: snapshot a file and append its manifest record in one call.
 * Returns the record (or `null` if nothing was captured).
 */
export async function capture(
	dir: string,
	absPath: string,
): Promise<ManifestRecord | null> {
	const record = await snapshotFile(dir, absPath);
	if (record) await appendManifest(dir, record);
	return record;
}

/** Read an entry's manifest as a map of `absPath -> absent`. */
export async function readManifest(
	dir: string,
): Promise<Map<string, boolean>> {
	const out = new Map<string, boolean>();
	const mf = path.join(dir, "manifest.jsonl");
	let text: string;
	try {
		text = await fs.readFile(mf, "utf8");
	} catch {
		return out; // no manifest yet
	}
	for (const line of text.split("\n")) {
		if (!line.trim()) continue;
		try {
			const rec = JSON.parse(line) as ManifestRecord;
			// First capture wins — preserves the earliest "before" state.
			if (!out.has(rec.path)) out.set(rec.path, rec.absent);
		} catch {
			// ignore malformed lines
		}
	}
	return out;
}

/** Whether an entry has any captured snapshots. */
export async function hasSnapshots(dir: string): Promise<boolean> {
	const manifest = await readManifest(dir);
	return manifest.size > 0;
}

/**
 * Restore the working tree to the state recorded for an entry.
 *
 * - Files marked absent are deleted (if present).
 * - Files with contents are overwritten with the snapshot copy.
 *
 * @param dir      Entry dir containing the snapshots.
 * @param cwdHint  Optional cwd, used only to make warnings relative.
 */
export async function restoreEntry(
	dir: string,
	cwdHint?: string,
): Promise<RestoreResult> {
	const result: RestoreResult = { restored: 0, deleted: 0, warnings: [] };

	let names: string[];
	try {
		names = await fs.readdir(dir);
	} catch {
		result.warnings.push(`No snapshots for entry at ${dir}`);
		return result;
	}

	for (const name of names) {
		if (name === "manifest.jsonl" || name.endsWith(ABSENT_SUFFIX)) continue;

		const absPath = decodeName(name);
		if (!absPath) {
			result.warnings.push(`Could not decode snapshot name: ${name}`);
			continue;
		}

		const src = path.join(dir, name);
		const wasAbsent = await fileExists(src + ABSENT_SUFFIX);
		const display = cwdHint ? path.relative(cwdHint, absPath) || absPath : absPath;

		if (wasAbsent) {
			try {
				await fs.unlink(absPath);
				result.deleted++;
			} catch {
				// already absent — fine
			}
		} else {
			try {
				await fs.mkdir(path.dirname(absPath), { recursive: true });
				await fs.copyFile(src, absPath);
				result.restored++;
			} catch (err) {
				result.warnings.push(`Failed to restore ${display}: ${(err as Error).message}`);
			}
		}
	}

	return result;
}

/**
 * List every entry id that has snapshots for a session.
 */
export async function listEntryIds(sessionDirPath: string): Promise<string[]> {
	try {
		const entries = await fs.readdir(sessionDirPath, { withFileTypes: true });
		return entries.filter((e) => e.isDirectory()).map((e) => e.name);
	} catch {
		return [];
	}
}

export { entryDir };
