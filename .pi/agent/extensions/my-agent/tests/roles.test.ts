import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { getRoleState, parseRoleCommandArg, parseRoleSettings, parseSkill, readOptionalTextFile, renderRoleSection } from "../roles.ts";

test("parseRoleCommandArg accepts short names and existing skill names", () => {
  assert.equal(parseRoleCommandArg("coder"), "my-coder");
  assert.equal(parseRoleCommandArg("my-coder"), "my-coder");
  assert.equal(parseRoleCommandArg("unknown"), undefined);
});

test("readOptionalTextFile ignores a missing config file but reads a present one", () => {
  const dir = mkdtempSync(join(tmpdir(), "my-agent-config-"));
  try {
    assert.deepEqual(readOptionalTextFile(join(dir, "my-agent.json")), { ok: true, value: undefined });

    const present = join(dir, "present.json");
    writeFileSync(present, "{\"my-coder\":{}}");
    assert.deepEqual(readOptionalTextFile(present), { ok: true, value: "{\"my-coder\":{}}" });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("parseRoleSettings requires exact settings for the requested role", () => {
  const parsed = parseRoleSettings(
    JSON.stringify({ "my-coder": { provider: "test-provider", model: "exact-model", thinkingLevel: "medium" } }),
    "my-coder",
  );

  assert.deepEqual(parsed, {
    ok: true,
    value: { provider: "test-provider", model: "exact-model", thinkingLevel: "medium" },
  });
});

test("parseRoleSettings rejects missing or unsupported settings", () => {
  assert.equal(parseRoleSettings("{}", "my-reviewer").ok, false);
  assert.equal(
    parseRoleSettings(
      JSON.stringify({ "my-reviewer": { provider: "provider", model: "model", thinkingLevel: "auto" } }),
      "my-reviewer",
    ).ok,
    false,
  );
});

test("parseSkill keeps the complete body and its source directory", () => {
  const parsed = parseSkill("my-planner", "/skills/my-planner/SKILL.md", "---\nname: my-planner\n---\n\n# Planner\n\nRead ../guide.md\n");

  assert.equal(parsed.ok, true);
  if (!parsed.ok) return;
  assert.equal(parsed.value.sourceDirectory, "/skills/my-planner");
  assert.equal(parsed.value.body, "\n# Planner\n\nRead ../guide.md\n");
  assert.match(renderRoleSection(parsed.value), /Source directory: \/skills\/my-planner/);
  assert.match(renderRoleSection(parsed.value), /Read \.\.\/guide\.md/);
});

test("getRoleState restores the latest role on the active branch only", () => {
  const state = getRoleState([
    { type: "custom", customType: "my-agent-role", data: { skillName: "my-planner", baseline: { thinkingLevel: "low" } } },
    { type: "custom", customType: "my-agent-role", data: { skillName: "my-coder", baseline: { provider: "base", model: "base-model", thinkingLevel: "medium" } } },
  ]);

  assert.deepEqual(state, {
    skillName: "my-coder",
    baseline: { provider: "base", model: "base-model", thinkingLevel: "medium" },
  });
  assert.equal(getRoleState([]), undefined);
});
