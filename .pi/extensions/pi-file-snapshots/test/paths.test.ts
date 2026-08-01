import { test } from "node:test";
import assert from "node:assert/strict";
import * as nodePath from "node:path";
import {
	decodeName,
	encodePath,
	shouldCapture,
	storeRoot,
	sessionDir,
	entryDir,
} from "../src/paths.ts";

test("encodePath / decodeName round-trip arbitrary paths", () => {
	const cases = [
		"/home/blake/projects/foo/bar.ts",
		"/tmp/x with spaces.ts",
		"/repo/ünïcödé-名前.md",
		"/a/b/..hidden",
		"/",
		"relative/path/no-slash.ts",
		"",
	];
	for (const p of cases) {
		const encoded = encodePath(p);
		assert.ok(!encoded.includes("/"), "encoded path must not contain slash");
		assert.ok(!encoded.includes(nodePath.sep), "encoded path must not contain path sep");
		assert.equal(decodeName(encoded), p, `round-trip failed for ${JSON.stringify(p)}`);
	}
});

test("encodePath length prefix rules out suffix collisions", () => {
	// Two paths whose base64 shares a suffix must not both decode to the
	// shorter one: the length prefix guarantees exact decoding.
	const a = encodePath("/x/abc");
	const b = encodePath("/x/abcdef");
	assert.notEqual(a, b);
	assert.equal(decodeName(a), "/x/abc");
	assert.equal(decodeName(b), "/x/abcdef");
});

test("decodeName rejects malformed names", () => {
	assert.equal(decodeName("manifest.jsonl"), null);
	assert.equal(decodeName("no-prefix-part"), null);
	assert.equal(decodeName("999_clearly-too-long"), null); // length won't match
	assert.equal(decodeName(""), null);
});

test("shouldCapture excludes virtual filesystems", () => {
	assert.equal(shouldCapture("/dev/null"), false);
	assert.equal(shouldCapture("/proc/self/status"), false);
	assert.equal(shouldCapture("/sys/kernel/notes"), false);
	assert.equal(shouldCapture("/home/blake/repo/main.ts"), true);
	assert.equal(shouldCapture("./relative.ts"), true);
});

test("storeRoot honors override and env", () => {
	assert.equal(storeRoot("/custom"), "/custom");
	// Without override, falls back to env or default; just ensure it's a string path.
	assert.ok(typeof storeRoot() === "string" && storeRoot().length > 0);
});

test("sessionDir / entryDir nest under the root", () => {
	const root = "/tmp/store";
	assert.equal(sessionDir(root, "sess1"), "/tmp/store/sess1");
	assert.equal(entryDir(root, "sess1", "abcd1234"), "/tmp/store/sess1/abcd1234");
});
