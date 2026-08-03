import assert from "node:assert/strict"
import { test } from "node:test"

import { registerClarifyCommand } from "../clarify.ts"
import {
  createFakeCommandCtx,
  createFakePi,
  type FakePi,
  userEntry,
} from "./helpers.ts"

const BLOCKED_TOOLS = ["edit", "write", "bash"]
const ALLOWED_TOOLS = ["read", "grep", "ls"]

/** Drive a registered `/clarify` command and expose its handlers/state. */
function setup(branch: unknown[], idle = true) {
  const pi = createFakePi()
  registerClarifyCommand(pi as unknown as Parameters<typeof registerClarifyCommand>[0])
  const command = pi.commands["clarify"]
  assert.ok(command, "clarify command should be registered")
  const { ctx, notifications, status } = createFakeCommandCtx({ branch, idle })
  return { pi, command, ctx, notifications, status }
}

test("/clarify is registered with a description", () => {
  const { pi } = setup([])
  assert.equal(pi.commands["clarify"].description, "Ask context-aware clarifying planning questions")
})

test("/clarify notifies and bails when the session has no user context", async () => {
  const { command, ctx, notifications, status } = setup([])
  await command.handler(undefined, ctx)
  assert.equal(notifications.length, 1)
  assert.match(notifications[0].message, /No user context/)
  assert.equal(status["clarify-mode"], undefined)
})

test("/clarify notifies and bails when the agent is not idle", async () => {
  const { command, ctx, notifications, status } = setup([userEntry("hi")], false)
  await command.handler(undefined, ctx)
  assert.equal(notifications.length, 1)
  assert.match(notifications[0].message, /idle/)
  assert.equal(status["clarify-mode"], undefined)
})

test("/clarify sends a questionnaire prompt and enters read-only phase", async () => {
  const { pi, command, ctx } = setup([userEntry("plan a thing")])
  await command.handler(undefined, ctx)
  assert.equal(pi.sentMessages.length, 1)
  assert.match(pi.sentMessages[0], /planning_questionnaire/)
  assert.match(pi.sentMessages[0], /3-6 clarifying planning questions/)
})

test("/clarify sets the clarify-mode status while the phase is active", async () => {
  const { command, ctx, status } = setup([userEntry("plan a thing")])
  await command.handler(undefined, ctx)
  assert.ok(status["clarify-mode"], "clarify-mode status should be set")
})

test("tool_call guard blocks mutating tools during the planning phase", async () => {
  const { pi, command, ctx } = setup([userEntry("plan a thing")])
  await command.handler(undefined, ctx) // activates the phase
  const guard = pi.handlers["tool_call"][0]
  for (const toolName of BLOCKED_TOOLS) {
    const res = await guard({ toolName }, undefined)
    assert.deepEqual(res, {
      block: true,
      reason: `Blocked during clarify planning phase: ${toolName} is disabled until planning completes.`,
    })
  }
})

test("tool_call guard allows read-only tools during the planning phase", async () => {
  const { pi, command, ctx } = setup([userEntry("plan a thing")])
  await command.handler(undefined, ctx)
  const guard = pi.handlers["tool_call"][0]
  for (const toolName of ALLOWED_TOOLS) {
    const res = await guard({ toolName }, undefined)
    assert.equal(res, undefined, `${toolName} should not be blocked`)
  }
})

test("tool_call guard does nothing before the phase is activated", async () => {
  const { pi } = setup([userEntry("plan a thing")])
  const guard = pi.handlers["tool_call"][0]
  const res = await guard({ toolName: "edit" }, undefined)
  assert.equal(res, undefined)
})

test("agent_settled clears the phase and the status indicator", async () => {
  const { pi, command, ctx, status } = setup([userEntry("plan a thing")])
  await command.handler(undefined, ctx)
  assert.ok(status["clarify-mode"])

  const settled = pi.handlers["agent_settled"][0]
  const { ctx: ctx2 } = createFakeCommandCtx()
  await settled(undefined, ctx2)

  // Guard is now inactive again.
  const guard = pi.handlers["tool_call"][0]
  assert.equal(await guard({ toolName: "edit" }, undefined), undefined)
})

test("agent_settled is a no-op when no phase is active", async () => {
  const pi = createFakePi()
  registerClarifyCommand(pi as unknown as Parameters<typeof registerClarifyCommand>[0])
  const { ctx, status } = createFakeCommandCtx()
  await pi.handlers["agent_settled"][0](undefined, ctx)
  assert.equal(status["clarify-mode"], undefined, "nothing should have been set or cleared")
})
