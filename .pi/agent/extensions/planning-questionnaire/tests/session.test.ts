import assert from "node:assert/strict"
import { test } from "node:test"

import { messageText } from "../session.ts"

test("messageText returns trimmed string content", () => {
  assert.equal(messageText({ content: "  hello world  " }), "hello world")
})

test("messageText joins an array of text blocks", () => {
  const msg = { content: [{ type: "text", text: "first" }, { type: "text", text: "second" }] }
  assert.equal(messageText(msg), "first\nsecond")
})

test("messageText ignores non-text blocks", () => {
  const msg = { content: [{ type: "image", url: "x" }, { type: "text", text: "only" }] }
  assert.equal(messageText(msg), "only")
})

test("messageText returns empty string for unsupported shapes", () => {
  assert.equal(messageText(null), "")
  assert.equal(messageText(undefined), "")
  assert.equal(messageText("plain string"), "")
  assert.equal(messageText({ content: 42 }), "")
  assert.equal(messageText({ content: [{ type: "image", url: "x" }] }), "")
})
