import assert from "node:assert/strict";
import { homedir, tmpdir } from "node:os";
import { resolve } from "node:path";
import { test } from "node:test";

import { type RoleName } from "../roles.ts";
import { canSummonAgents, parseSummonArgs, parseSummonToolParams, summonAgent, type SummonToolParams } from "../summon.ts";

const params: SummonToolParams = { layout: "tab", role: "reviewer" };
const model = { provider: "test-provider", model: "test-model", thinkingLevel: "high" as const };

test("only planner and coder roles are eligible for the summon tool", () => {
  assert.equal(canSummonAgents("my-planner"), true);
  assert.equal(canSummonAgents("my-coder"), true);
  for (const role of [undefined, "my-reviewer", "my-monkey"] as const) {
    assert.equal(canSummonAgents(role), false);
    assert.throws(() => parseSummonToolParams(params, "/work", role), /Only planner and coder/);
  }
});

test("both eligible callers can summon every child role using the same request as the slash command", () => {
  for (const caller of ["my-planner", "my-coder"] as const) {
    for (const role of ["planner", "coder", "reviewer", "monkey"] as const) {
      for (const layout of ["tab", "workspace", "pane"] as const) {
        assert.deepEqual(
          parseSummonToolParams({ layout, role }, "/work", caller),
          parseSummonArgs(`summon-${layout} ${role}`, "/work"),
        );
      }
    }
  }
});

test("tool pane directions match the default and -v slash commands", () => {
  assert.deepEqual(parseSummonToolParams({ ...params, layout: "pane", direction: "right" }, "/work", "my-coder"), parseSummonArgs("summon-pane reviewer", "/work"));
  assert.deepEqual(parseSummonToolParams({ ...params, layout: "pane", direction: "down" }, "/work", "my-planner"), parseSummonArgs("summon-pane -v reviewer", "/work"));
});

test("workspace directory defaults to caller cwd and supports relative, home and literal quoted paths", () => {
  const request = { ...params, layout: "workspace" as const };
  assert.equal(parseSummonToolParams(request, "/work/repo", "my-planner").cwd, "/work/repo");
  assert.equal(parseSummonToolParams({ ...request, directory: "../other" }, "/work/repo", "my-planner").cwd, "/work/other");
  assert.equal(parseSummonToolParams({ ...request, directory: "~/my repo" }, "/work", "my-coder").cwd, resolve(homedir(), "my repo"));
  assert.equal(parseSummonToolParams({ ...request, directory: '/work/a "quoted" repo' }, "/work", "my-coder").cwd, '/work/a "quoted" repo');
});

test("omitting or blanking the message preserves shared role defaults; explicit messages remain literal", () => {
  assert.equal(parseSummonToolParams(params, "/work", "my-coder").message, undefined);
  assert.equal(parseSummonToolParams({ ...params, message: "  " }, "/work", "my-planner").message, undefined);
  const message = '--dir is message text; $(not-a-command)\n"keep quotes"';
  assert.equal(parseSummonToolParams({ ...params, message }, "/work", "my-coder").message, message);
});

test("layout-specific options and invalid roles are rejected rather than silently ignored", () => {
  const invalid = [
    { ...params, directory: "/work" },
    { ...params, layout: "pane", directory: "/work" },
    { ...params, direction: "down" },
    { ...params, layout: "workspace", direction: "right" },
    { ...params, layout: "workspace", directory: " " },
    { ...params, layout: "other" },
    { ...params, role: "stranger" },
    { ...params, layout: "pane", direction: "left" },
  ];
  for (const input of invalid) assert.throws(() => parseSummonToolParams(input as SummonToolParams, "/work", "my-planner"), Error);
});

test("caller role is checked before parsing a request", () => {
  assert.throws(() => parseSummonToolParams({ ...params, role: "stranger" } as unknown as SummonToolParams, "/work", "my-reviewer" as RoleName), /Only planner and coder/);
});

test("a cancelled summon creates no resources", async () => {
  const controller = new AbortController();
  controller.abort(new Error("User cancelled"));
  const calls: string[][] = [];
  await assert.rejects(summonAgent(parseSummonToolParams(params, tmpdir(), "my-planner"), {
    paneId: "w1:p1", workspaceId: "w1", agentDir: "/profiles/test", model, signal: controller.signal,
    run: async (args) => { calls.push(args); throw new Error("Must not execute"); },
  }), /User cancelled/);
  assert.equal(calls.length, 0);
});

test("cancellation after creating a child reports its location without activating or prompting it", async () => {
  const controller = new AbortController();
  const calls: string[][] = [];
  await assert.rejects(summonAgent(parseSummonToolParams(params, tmpdir(), "my-coder"), {
    paneId: "w1:p1", workspaceId: "w1", agentDir: "/profiles/test", model, signal: controller.signal,
    run: async (args) => {
      calls.push(args);
      if (args[0] === "tab") return JSON.stringify({ result: { root_pane: { pane_id: "w1:p2", workspace_id: "w1" } } });
      controller.abort(new Error("User cancelled"));
      return JSON.stringify({ result: {} });
    },
  }), /User cancelled.*pane w1:p2.*No automatic retry/);
  assert.deepEqual(calls.map((args) => args.slice(0, 2)), [["tab", "create"], ["agent", "start"]]);
});
