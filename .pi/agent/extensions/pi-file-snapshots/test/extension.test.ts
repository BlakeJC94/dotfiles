import { test } from "node:test";
import assert from "node:assert/strict";
import {
	currentEntryId,
	labelForEntry,
	sessionIdOf,
} from "../src/extension.ts";

/**
 * Minimal mock of ExtensionContext.sessionManager. We cast to the real type
 * via `as any` so the helpers exercise their real code paths without pulling
 * in a live pi runtime.
 */
function mockCtx(sessionManager: object) {
	return { sessionManager } as unknown as Parameters<typeof sessionIdOf>[0];
}

test("sessionIdOf prefers getSessionId()", () => {
	const ctx = mockCtx({ getSessionId: () => "uuid-1", getSessionFile: () => "/x.jsonl" });
	assert.equal(sessionIdOf(ctx), "uuid-1");
});

test("sessionIdOf falls back to a hash of the session file", () => {
	const ctx = mockCtx({ getSessionId: () => undefined, getSessionFile: () => "/x.jsonl" });
	const id = sessionIdOf(ctx);
	assert.equal(id.length, 12);
	// Same input -> same id (stable).
	assert.equal(sessionIdOf(ctx), id);
});

test("sessionIdOf uses 'ephemeral' when nothing is available", () => {
	const ctx = mockCtx({ getSessionId: () => undefined, getSessionFile: () => undefined });
	assert.equal(sessionIdOf(ctx), "ephemeral");
});

test("currentEntryId returns the leaf entry id", () => {
	const ctx = mockCtx({ getLeafEntry: () => ({ id: "leaf1234" }) });
	assert.equal(currentEntryId(ctx), "leaf1234");
});

test("currentEntryId returns undefined when there is no leaf", () => {
	const ctx = mockCtx({ getLeafEntry: () => undefined });
	assert.equal(currentEntryId(ctx), undefined);
});

test("labelForEntry: user message snippet", () => {
	const ctx = mockCtx({
		getEntry: () => ({
			type: "message",
			message: {
				role: "user",
				content: "Please refactor the auth module to use async/await",
			},
		}),
	});
	const label = labelForEntry(ctx as never, "abcd1234");
	assert.match(label, /\[user\]/);
	assert.match(label, /refactor the auth module/);
	assert.ok(label.length <= 80, "snippet is truncated");
});

test("labelForEntry: assistant message with array content", () => {
	const ctx = mockCtx({
		getEntry: () => ({
			type: "message",
			message: {
				role: "assistant",
				content: [{ type: "text", text: "Here is the plan." }],
			},
		}),
	});
	const label = labelForEntry(ctx as never, "abcd1234");
	assert.match(label, /\[assistant\] Here is the plan\./);
});

test("labelForEntry: collapses whitespace in snippet", () => {
	const ctx = mockCtx({
		getEntry: () => ({
			type: "message",
			message: {
				role: "user",
				content: "a   b\n\tc",
			},
		}),
	});
	const label = labelForEntry(ctx as never, "abcd1234");
	assert.match(label, /a b c/);
});

test("labelForEntry: non-message entry type", () => {
	const ctx = mockCtx({
		getEntry: () => ({ type: "model_change" }),
	});
	assert.equal(labelForEntry(ctx as never, "abcd1234"), "abcd1234 [model_change]");
});

test("labelForEntry: entry not in current branch", () => {
	const ctx = mockCtx({ getEntry: () => undefined });
	assert.equal(labelForEntry(ctx as never, "abcd1234"), "abcd1234 (entry not in current branch)");
});
