import { test } from "node:test";
import assert from "node:assert/strict";
import { promises as fs } from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import {
	capture,
	hasSnapshots,
	listEntryIds,
	readManifest,
	restoreEntry,
} from "../src/store.ts";
import { entryDir } from "../src/paths.ts";

async function tmpStore(): Promise<string> {
	const dir = await fs.mkdtemp(path.join(os.tmpdir(), "pfs-"));
	return dir;
}

test("capture records the pre-change state of an existing file", async () => {
	const root = await tmpStore();
	const dir = entryDir(root, "sess", "entry1");
	const file = path.join(root, "live", "a.txt");
	await fs.mkdir(path.dirname(file), { recursive: true });
	await fs.writeFile(file, "original");

	const record = await capture(dir, file);
	assert.equal(record?.absent, false);
	assert.equal(record?.path, file);

	// Mutate the live file after capture.
	await fs.writeFile(file, "changed");

	// Restore brings back the original contents.
	const res = await restoreEntry(dir, root);
	assert.equal(res.restored, 1);
	assert.equal(res.deleted, 0);
	assert.equal(await fs.readFile(file, "utf8"), "original");
});

test("capture of a not-yet-existing file marks it absent; restore deletes it", async () => {
	const root = await tmpStore();
	const dir = entryDir(root, "sess", "entry1");
	const file = path.join(root, "live", "new.txt");

	const record = await capture(dir, file);
	assert.equal(record?.absent, true);

	// Simulate the file being created later.
	await fs.mkdir(path.dirname(file), { recursive: true });
	await fs.writeFile(file, "later content");

	const res = await restoreEntry(dir, root);
	assert.equal(res.deleted, 1);
	assert.equal(res.restored, 0);
	await assert.rejects(() => fs.access(file));
});

test("capture is idempotent within an entry — first capture wins", async () => {
	const root = await tmpStore();
	const dir = entryDir(root, "sess", "entry1");
	const file = path.join(root, "live", "a.txt");
	await fs.mkdir(path.dirname(file), { recursive: true });
	await fs.writeFile(file, "v1");

	const first = await capture(dir, file);
	assert.ok(first);

	await fs.writeFile(file, "v2");
	const second = await capture(dir, file); // should be a no-op
	assert.equal(second, null);

	const res = await restoreEntry(dir, root);
	assert.equal(res.restored, 1);
	assert.equal(await fs.readFile(file, "utf8"), "v1");
});

test("readManifest returns first-capture absent flags per path", async () => {
	const root = await tmpStore();
	const dir = entryDir(root, "sess", "entry1");
	const a = path.join(root, "a.txt");
	const b = path.join(root, "b.txt");
	await fs.writeFile(a, "a");

	await capture(dir, a); // exists -> absent=false
	await capture(dir, b); // missing -> absent=true

	const manifest = await readManifest(dir);
	assert.equal(manifest.size, 2);
	assert.equal(manifest.get(a), false);
	assert.equal(manifest.get(b), true);
});

test("hasSnapshots is false for an empty/missing entry", async () => {
	const root = await tmpStore();
	assert.equal(await hasSnapshots(entryDir(root, "sess", "empty")), false);
});

test("listEntryIds returns directories under the session dir", async () => {
	const root = await tmpStore();
	await fs.mkdir(entryDir(root, "sess", "e1"), { recursive: true });
	await fs.mkdir(entryDir(root, "sess", "e2"), { recursive: true });
	// Non-directory stray file should be ignored.
	await fs.writeFile(path.join(root, "sess", "stray.txt"), "x");

	const ids = await listEntryIds(path.join(root, "sess"));
	assert.deepEqual(ids.sort(), ["e1", "e2"]);
});

test("restore round-trips a multi-file snapshot", async () => {
	const root = await tmpStore();
	const dir = entryDir(root, "sess", "e1");
	const live = path.join(root, "live");
	const f1 = path.join(live, "one.txt");
	const f2 = path.join(live, "nested", "two.ts");
	await fs.mkdir(path.dirname(f2), { recursive: true });
	await fs.writeFile(f1, "one");
	await fs.writeFile(f2, "two");

	await capture(dir, f1);
	await capture(dir, f2);

	// Make changes after capture.
	await fs.writeFile(f1, "CHANGED");
	await fs.unlink(f2);

	const res = await restoreEntry(dir, root);
	assert.equal(res.restored, 2);
	assert.equal(await fs.readFile(f1, "utf8"), "one");
	assert.equal(await fs.readFile(f2, "utf8"), "two");
	assert.equal(res.warnings.length, 0);
});

test("restore warns but continues when a target directory is gone", async () => {
	const root = await tmpStore();
	const dir = entryDir(root, "sess", "e1");
	const file = path.join(root, "live", "a.txt");
	await fs.mkdir(path.dirname(file), { recursive: true });
	await fs.writeFile(file, "x");
	await capture(dir, file);

	// Removing the snapshot dir entirely yields a "No snapshots" warning.
	await fs.rm(dir, { recursive: true });
	const res = await restoreEntry(dir, root);
	assert.equal(res.restored, 0);
	assert.ok(res.warnings.length > 0);
});

test("paths under virtual filesystems are not captured", async () => {
	const root = await tmpStore();
	const dir = entryDir(root, "sess", "e1");
	const record = await capture(dir, "/proc/self/status");
	assert.equal(record, null);
	const manifest = await readManifest(dir);
	assert.equal(manifest.size, 0);
});
