/**
 * Pure path-encoding and store-location helpers.
 *
 * These functions have no dependency on pi's runtime context, which keeps
 * them trivially unit-testable.
 */

import * as path from "node:path";

/**
 * Default on-disk root for the snapshot store.
 *
 * Layout: `<STORE_ROOT>/<sessionId>/<entryId>/<encodedPath>`
 */
export const DEFAULT_STORE_ROOT = path.join(
	process.env.HOME ?? "/tmp",
	".pi",
	"agent",
	"file-snapshots",
);

/**
 * Paths the store should never attempt to round-trip. Anything under these
 * virtual filesystems is pointless or dangerous to snapshot/restore.
 */
const EXCLUDE_PREFIXES = ["/dev/", "/proc/", "/sys/"];

/** Resolve the store root, honoring the `PI_FILE_SNAPSHOTS_DIR` override. */
export function storeRoot(override?: string): string {
	return override ?? process.env.PI_FILE_SNAPSHOTS_DIR ?? DEFAULT_STORE_ROOT;
}

/** Directory holding all snapshots for a given session. */
export function sessionDir(root: string, sessionId: string): string {
	return path.join(root, sessionId);
}

/** Directory holding all snapshots captured at a given conversation entry. */
export function entryDir(root: string, sessionId: string, entryId: string): string {
	return path.join(root, sessionId, entryId);
}

/**
 * Encode an absolute path into a single safe filename component. The
 * encoding is reversible: see {@link decodeName}.
 *
 * Format: `<byteLength(base36)>_<base64url(path)>`. The length prefix makes
 * decoding exact and rules out suffix collisions.
 */
export function encodePath(absPath: string): string {
	const bytes = Buffer.from(absPath, "utf8");
	return `${bytes.length.toString(36)}_${bytes.toString("base64url")}`;
}

/** Inverse of {@link encodePath}. Returns `null` on malformed input. */
export function decodeName(name: string): string | null {
	const sep = name.indexOf("_");
	if (sep < 0) return null;
	const len = parseInt(name.slice(0, sep), 36);
	if (!Number.isInteger(len) || len < 0) return null;
	const b64 = name.slice(sep + 1);
	const buf = Buffer.from(b64, "base64url");
	if (buf.length !== len) return null;
	return buf.toString("utf8");
}

/** Whether a path is eligible to be snapshotted. */
export function shouldCapture(absPath: string): boolean {
	return !EXCLUDE_PREFIXES.some((p) => absPath.startsWith(p));
}

/** Marker file written alongside a snapshot when the file did not yet exist. */
export const ABSENT_SUFFIX = ".absent";
