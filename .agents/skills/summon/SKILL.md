---
name: summon
description: "Start a new Pi coding agent in a Herdr sibling pane, invoke a specified skill there with relevant task context, wait for its result, and relay it. Use when asked to /skill:summon <skill-name> or to delegate a skill to a new Pi agent. Requires HERDR_ENV=1."
disable-model-invocation: true
---

# Summon a skill-bearing agent

Input: a skill name, optionally followed by instructions for that agent. If the name is missing or the requested skill is not discoverable, ask for a valid name. Do not summon `summon` recursively. Treat the remainder as the delegated task, not as a shell command.

1. Read `../herdr/SKILL.md` completely. Verify `HERDR_ENV=1` before any Herdr control command; otherwise stop. Follow its CLI discovery, pane geometry, cwd, focus, identity, and recovery rules. Confirm the installed CLI supports `--kind pi`.
2. Prepare a concise handoff from the current conversation: the user's goal and delegated task, exact files/diff or other scope, cwd and branch when relevant, decisions already made, constraints/approvals, checks and remaining work. Include only context needed by the requested skill; do not claim to transfer the full session or invent missing details. If the delegated task's scope is unclear, ask before spawning. A new Pi agent cannot see this conversation unless you pass the context explicitly.
3. Inspect live agents; choose a unique, useful name derived from the skill (for example `my-reviewer`, then `my-reviewer-2` if occupied). Split a sibling pane in the current tab without moving focus; preserve `$PWD`. Start that agent in the returned pane with `herdr agent start <name> --kind pi --pane <pane-id>`.
4. Prompt the new agent via `herdr agent prompt <name> "<text>" --wait --timeout 120000`. Begin the text with `/skill:<skill-name> ` (a literal space after the name), then the delegated task and handoff; for example, `/skill:my-reviewer Review the current changes.\nGoal: ...`. Pi separates the skill name at the first space, so a newline immediately after the name would not invoke it. Do not merely tell the agent to behave like the skill: invoke the skill command so Pi loads its instructions. Never send a second copy of the prompt blindly if submission, waiting, or the caller is interrupted.
5. After a settled response, read `herdr agent get <name>` and `herdr agent read <name> --source recent-unwrapped --lines 200`. Relay the result and the agent name/pane ID to the caller. If blocked, stalled, timed out, or interrupted, inspect its state/output before acting; a cancelled wait does not cancel the agent. If it is still working, wait for it again when appropriate, or report that it is ongoing. Never equate an idle state or missing output with a completed answer. Follow the Herdr skill's fallback for incomplete output.

Leave the spawned pane available for inspection. Do not close or interrupt existing agents. Do not forward the entire transcript or unrelated private material.
