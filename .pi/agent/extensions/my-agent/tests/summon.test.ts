import assert from "node:assert/strict";
import { homedir, tmpdir } from "node:os";
import { resolve } from "node:path";
import { test } from "node:test";

import { parseRoleSettings, type RoleName } from "../roles.ts";
import { DEFAULT_MESSAGES, parseSummonArgs, summonAgent } from "../summon.ts";

const model = { provider: "test-provider", model: "test-model", thinkingLevel: "high" as const };
const location = { pane_id: "w1:p2", workspace_id: "w1", tab_id: "w1:t2" };

function fakeHerdr(options: { startError?: string; foreground?: string; activation?: "missing" | "blocked"; taskError?: boolean } = {}) {
  const calls: string[][] = [];
  const envelope = (result: unknown) => JSON.stringify({ result });
  const run = async (args: string[]): Promise<string> => {
    calls.push(args);
    const command = args.slice(0, 2).join(" ");
    switch (command) {
      case "tab create":
      case "workspace create":
        return envelope({ root_pane: location });
      case "pane split":
        return envelope({ pane: location });
      case "agent start":
        if (options.startError) throw Object.assign(new Error("start failed"), { stderr: JSON.stringify({ error: { code: options.startError } }) });
        return envelope({ agent: { agent_status: "idle" } });
      case "pane process-info":
        return envelope({ process_info: { shell_pid: 10, foreground_processes: [{ pid: options.foreground ? 11 : 10, name: options.foreground ?? "zsh" }] } });
      case "pane run":
        return "";
      case "pane get":
        return envelope({ pane: { ...location, agent: "pi", agent_status: "idle" } });
      case "agent rename":
        return envelope({});
      case "agent read": {
        const activation = calls.find((call) => call[0] === "agent" && call[1] === "prompt")?.[3];
        return options.activation === "missing" ? "Role activation failed." : `Activated my-${activation?.slice(7)} on test-provider/test-model.`;
      }
      case "agent get":
        return envelope({ agent: { agent_status: options.activation === "blocked" ? "blocked" : "idle" } });
      case "agent prompt":
        if (options.taskError && !args[3].startsWith("/agent ")) throw new Error("delivery uncertain");
        return envelope({});
      default:
        throw new Error(`Unexpected command: ${args.join(" ")}`);
    }
  };
  return { calls, run };
}

function launchOptions(fake: ReturnType<typeof fakeHerdr>, defaultMessage?: string) {
  return { workspaceId: "w1", paneId: "w1:p1", agentDir: "/profiles/custom", model: { ...model, ...(defaultMessage ? { defaultMessage } : {}) }, run: fake.run, pause: async () => {}, attempts: 2 };
}

function prompts(calls: string[][]): string[][] {
  return calls.filter((args) => args[0] === "agent" && args[1] === "prompt");
}

test("summon parsing accepts all role names and defaults to the caller directory", () => {
  for (const role of ["planner", "coder", "reviewer", "monkey"]) {
    for (const spelling of [role, `my-${role}`]) {
      const request = parseSummonArgs(`summon-tab ${spelling}`, "/work");
      assert.equal(request.role, `my-${role}`);
      assert.equal(request.cwd, "/work");
      assert.equal(request.message, undefined);
    }
  }
});

test("pane defaults right and -v splits below", () => {
  assert.equal(parseSummonArgs("summon-pane coder", "/work").direction, "right");
  assert.equal(parseSummonArgs("summon-pane -v coder inspect this", "/work").direction, "down");
});

test("workspace --dir supports relative, home and quoted paths without consuming the message", () => {
  assert.equal(parseSummonArgs("summon-workspace coder --dir ../other", "/work/repo").cwd, "/work/other");
  assert.equal(parseSummonArgs("summon-workspace coder --dir ~/repo", "/work").cwd, resolve(homedir(), "repo"));
  const request = parseSummonArgs('summon-workspace reviewer --dir "/work/my repo" review the changes', "/work");
  assert.equal(request.cwd, "/work/my repo");
  assert.equal(request.message, "review the changes");
  assert.equal(parseSummonArgs("summon-workspace coder --dir .", "/work").cwd, "/work");
});

test("message text is literal and -- permits a message beginning with an option", () => {
  const message = 'Review $(touch /tmp/not-executed); "keep quotes"\nand newlines';
  assert.equal(parseSummonArgs(`summon-tab reviewer ${message}`, "/work").message, message);
  assert.equal(parseSummonArgs("summon-tab coder -- --dir is message text", "/work").message, "--dir is message text");
  assert.equal(parseSummonArgs("summon-workspace coder implement the plan", "/work").message, "implement the plan");
});

test("invalid summon syntax fails before launching anything", () => {
  for (const command of ["summon-other coder", "summon-tab", "summon-tab stranger", "summon-tab -v coder", "summon-pane coder -v", "summon-tab coder --dir /work", "summon-workspace coder --dir", 'summon-workspace coder --dir "unclosed', "summon-tab coder --unknown"]) {
    assert.throws(() => parseSummonArgs(command, "/work"), Error, command);
  }
});

test("role defaultMessage is optional, configurable and validated", () => {
  const config = (defaultMessage: unknown) => JSON.stringify({ "my-coder": { ...model, defaultMessage } });
  const parsed = parseRoleSettings(config("Custom task."), "my-coder");
  assert.equal(parsed.ok, true);
  if (parsed.ok) assert.equal(parsed.value.defaultMessage, "Custom task.");
  for (const invalid of ["", " ", 2, null]) assert.equal(parseRoleSettings(config(invalid), "my-coder").ok, false);
  assert.deepEqual(parseRoleSettings(JSON.stringify({ "my-coder": model }), "my-coder"), { ok: true, value: model });
});

for (const command of ["summon-tab", "summon-workspace", "summon-pane"] as const) {
  test(`${command} creates only its requested location, preserves focus/profile, and starts a fresh role before its task`, async () => {
    const fake = fakeHerdr();
    const request = parseSummonArgs(`${command} coder`, tmpdir());
    const child = await summonAgent(request, launchOptions(fake));
    assert.match(child.name, /^my-coder-[a-f0-9]{8}$/);
    assert.equal(child.paneId, location.pane_id);
    const creation = fake.calls[0];
    assert.deepEqual(creation.slice(0, 2), command === "summon-tab" ? ["tab", "create"] : command === "summon-workspace" ? ["workspace", "create"] : ["pane", "split"]);
    assert.ok(creation.includes("--no-focus"));
    assert.ok(creation.includes("PI_CODING_AGENT_DIR=/profiles/custom"));
    assert.equal(creation[creation.indexOf("--cwd") + 1], tmpdir());
    if (command === "summon-tab") assert.equal(creation[creation.indexOf("--workspace") + 1], "w1");
    if (command === "summon-pane") assert.equal(creation[creation.indexOf("--pane") + 1], "w1:p1");
    const start = fake.calls.find((args) => args[1] === "start")!;
    assert.deepEqual(start.slice(start.indexOf("--") + 1), ["--provider", "test-provider", "--model", "test-model", "--thinking", "high"]);
    for (const forbidden of ["--fork", "--session", "--continue", "--resume", "--approve"]) assert.ok(!start.includes(forbidden));
    assert.equal(prompts(fake.calls)[0][3], "/agent coder");
    assert.equal(prompts(fake.calls)[1][3], DEFAULT_MESSAGES["my-coder"]);
    assert.equal(prompts(fake.calls).length, 2);
    assert.ok(fake.calls.filter((args) => args[1] === "read").every((args) => args.includes("visible")));
  });
}

test("each role gets its own default message", async () => {
  for (const role of Object.keys(DEFAULT_MESSAGES) as RoleName[]) {
    const fake = fakeHerdr();
    await summonAgent(parseSummonArgs(`summon-tab ${role}`, tmpdir()), launchOptions(fake));
    assert.equal(prompts(fake.calls)[1][3], DEFAULT_MESSAGES[role]);
  }
});

test("an explicit task overrides configuration and configuration overrides the built-in default", async () => {
  const fake = fakeHerdr();
  await summonAgent(parseSummonArgs("summon-tab coder", tmpdir()), launchOptions(fake, "Configured task."));
  assert.equal(prompts(fake.calls)[1][3], "Configured task.");
  const custom = fakeHerdr();
  await summonAgent(parseSummonArgs("summon-tab coder Explicit task.", tmpdir()), launchOptions(custom, "Configured task."));
  assert.equal(prompts(custom.calls)[1][3], "Explicit task.");
});

test("-v passes the down direction to Herdr", async () => {
  const fake = fakeHerdr();
  await summonAgent(parseSummonArgs("summon-pane -v reviewer", tmpdir()), launchOptions(fake));
  assert.equal(fake.calls[0][fake.calls[0].indexOf("--direction") + 1], "down");
});

test("an incorrectly busy fresh shell is inspected before a single fallback launch", async () => {
  const fake = fakeHerdr({ startError: "agent_pane_busy" });
  await summonAgent(parseSummonArgs("summon-tab coder", tmpdir()), launchOptions(fake));
  const inspection = fake.calls.findIndex((args) => args[1] === "process-info");
  const fallback = fake.calls.findIndex((args) => args[0] === "pane" && args[1] === "run");
  assert.ok(inspection >= 0 && inspection < fallback);
  assert.equal(fake.calls.filter((args) => args[0] === "pane" && args[1] === "run").length, 1);
  assert.ok(fake.calls.some((args) => args[1] === "rename"));
  assert.equal(prompts(fake.calls).length, 2);
});

test("a busy editor is never bypassed or prompted", async () => {
  const fake = fakeHerdr({ startError: "agent_pane_busy", foreground: "vim" });
  await assert.rejects(summonAgent(parseSummonArgs("summon-tab coder", tmpdir()), launchOptions(fake)), /not an idle shell.*pane w1:p2/);
  assert.ok(!fake.calls.some((args) => args[0] === "pane" && args[1] === "run"));
  assert.equal(prompts(fake.calls).length, 0);
});

test("other startup errors preserve the created location without retrying or closing it", async () => {
  const fake = fakeHerdr({ startError: "agent_not_ready" });
  await assert.rejects(summonAgent(parseSummonArgs("summon-tab coder", tmpdir()), launchOptions(fake)), /agent_not_ready.*No automatic retry or cleanup/);
  assert.ok(!fake.calls.some((args) => ["run", "close", "process-info"].includes(args[1])));
  assert.equal(prompts(fake.calls).length, 0);
});

for (const activation of ["missing", "blocked"] as const) {
  test(`unconfirmed ${activation} role activation sends no task or duplicate activation`, async () => {
    const fake = fakeHerdr({ activation });
    await assert.rejects(summonAgent(parseSummonArgs("summon-tab coder", tmpdir()), launchOptions(fake)), /no task was sent/i);
    assert.equal(prompts(fake.calls).length, 1);
  });
}

test("uncertain task delivery is reported with child ids and is never resent", async () => {
  const fake = fakeHerdr({ taskError: true });
  await assert.rejects(summonAgent(parseSummonArgs("summon-tab coder", tmpdir()), launchOptions(fake)), /delivery uncertain.*pane w1:p2.*No automatic retry/);
  assert.equal(prompts(fake.calls).length, 2);
});

test("an invalid directory creates no Herdr resources", async () => {
  const fake = fakeHerdr();
  await assert.rejects(summonAgent(parseSummonArgs("summon-workspace coder --dir /definitely-missing-my-agent-directory", tmpdir()), launchOptions(fake)), /ENOENT/);
  assert.equal(fake.calls.length, 0);
});
