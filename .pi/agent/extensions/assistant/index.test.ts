import assert from "node:assert/strict";
import test from "node:test";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import assistantExtension, { ASSISTANT_MODE_ENV, buildActivationLine, buildAssistantInstructions, buildDateTimeLine, buildScheduleRequest, isAssistantModeEnabled, parseAssistantModelConfig, switchAssistantModel } from "./index.ts";

function createExtension() {
  const commands = new Map<string, { handler: (args: string, ctx: unknown) => Promise<void> }>();
  const handlers = new Map<string, (event: { systemPromptOptions: { sections: Record<string, string> } }) => void>();
  const pi = {
    registerCommand(name: string, command: { handler: (args: string, ctx: unknown) => Promise<void> }) {
      commands.set(name, command);
    },
    setModel: async () => true,
    on(name: string, handler: (event: { systemPromptOptions: { sections: Record<string, string> } }) => void) {
      handlers.set(name, handler);
      return () => {};
    },
  } as unknown as ExtensionAPI;

  assistantExtension(pi);
  return { commands, handlers };
}

function createContext() {
  const notifications: string[] = [];
  const messages: string[] = [];
  return {
    notifications,
    messages,
    ctx: {
      ui: { notify: (message: string) => notifications.push(message) },
      model: { id: "previous-model" },
      modelRegistry: { find: () => ({ id: "assistant-model" }) },
      sendUserMessage: async (message: string) => messages.push(message),
    },
  };
}

test("assistant mode adds and removes its own prompt section", async () => {
  const { commands, handlers } = createExtension();
  const command = commands.get("assistant")!;
  const { ctx } = createContext();

  await command.handler("on", ctx);
  const enabledEvent = { systemPromptOptions: { sections: {} } };
  handlers.get("before_agent_start")!(enabledEvent);
  assert.match(enabledEvent.systemPromptOptions.sections["field-notes-assistant"], /source of truth is the field-notes directory/);
  assert.match(enabledEvent.systemPromptOptions.sections["field-notes-assistant"], /Assistant mode activated:/);
  assert.doesNotMatch(enabledEvent.systemPromptOptions.sections["field-notes-assistant"], /Current date and time:/);

  await command.handler("off", ctx);
  const disabledEvent = { systemPromptOptions: { sections: { "field-notes-assistant": "old" } } };
  handlers.get("before_agent_start")!(disabledEvent);
  assert.equal(disabledEvent.systemPromptOptions.sections["field-notes-assistant"], undefined);
});

test("checkin adds assistant instructions for one turn without enabling the mode", async () => {
  const { commands, handlers } = createExtension();
  const command = commands.get("assistant")!;
  const { ctx, messages } = createContext();

  await command.handler("checkin", ctx);
  assert.equal(messages.length, 1);

  const checkinEvent = { systemPromptOptions: { sections: {} } };
  handlers.get("before_agent_start")!(checkinEvent);
  assert.ok(checkinEvent.systemPromptOptions.sections["field-notes-assistant"]);

  const nextEvent = { systemPromptOptions: { sections: { "field-notes-assistant": "old" } } };
  handlers.get("before_agent_start")!(nextEvent);
  assert.equal(nextEvent.systemPromptOptions.sections["field-notes-assistant"], undefined);
});

test("assistant model config requires a provider and model ID", () => {
  assert.deepEqual(
    parseAssistantModelConfig('assistant_model_provider = "openai"\nassistant_model_id = "gpt-example"'),
    { provider: "openai", id: "gpt-example" },
  );
  assert.equal(parseAssistantModelConfig('assistant_model_provider = ""\nassistant_model_id = ""'), undefined);
  assert.throws(() => parseAssistantModelConfig('assistant_model_provider = "openai"'), /Configure both/);
});

test("assistant model switching preserves the model to restore", async () => {
  const previousModel = { id: "previous" } as Parameters<typeof switchAssistantModel>[2];
  const assistantModel = { id: "assistant" } as Parameters<typeof switchAssistantModel>[2];
  const selected: unknown[] = [];
  const ctx = { model: previousModel } as Parameters<typeof switchAssistantModel>[0];
  const setModel: Parameters<typeof switchAssistantModel>[1] = async (model) => {
    selected.push(model);
    return true;
  };

  const result = await switchAssistantModel(ctx, setModel, assistantModel);
  assert.deepEqual(result, { ok: true, previousModel });
  assert.deepEqual(selected, [assistantModel]);
});

test("datetime line reflects the configured timezone", () => {
  const line = buildDateTimeLine(new Date("2026-11-18T01:30:00Z"), "Australia/Melbourne");
  assert.match(line, /Current date and time:/);
  assert.match(line, /2026-11-18/);
  assert.match(line, /12:30/);
  assert.match(line, /Australia\/Melbourne/);
  assert.match(buildActivationLine(new Date("2026-11-18T01:30:00Z"), "Australia/Melbourne"), /Assistant mode activated:.*2026-11-18 12:30/);
});

test("system prompt section is static so the prefix cache survives", async () => {
  const { commands, handlers } = createExtension();
  const { ctx } = createContext();
  const input = handlers.get("input") as unknown as (event: { text: string; source: string }) => { action: string; text?: string };

  assert.equal(input({ text: "hello", source: "interactive" }).action, "continue");

  await commands.get("assistant")!.handler("on", ctx);

  const first = { systemPromptOptions: { sections: {} as Record<string, string> } };
  const second = { systemPromptOptions: { sections: {} as Record<string, string> } };
  handlers.get("before_agent_start")!(first);
  handlers.get("before_agent_start")!(second);
  assert.match(first.systemPromptOptions.sections["field-notes-assistant"], /Assistant mode activated:/);
  assert.equal(first.systemPromptOptions.sections["field-notes-assistant"], second.systemPromptOptions.sections["field-notes-assistant"]);

  const stamped = input({ text: "hello", source: "interactive" });
  assert.equal(stamped.action, "transform");
  assert.match(stamped.text ?? "", /Current date and time:/);
  assert.match(stamped.text ?? "", /hello/);

  assert.equal(input({ text: "/assistant off", source: "interactive" }).action, "continue");
  assert.equal(input({ text: "hello", source: "extension" }).action, "continue");
});

test("PI_ASSISTANT_MODE enables the assistant for headless runs", () => {
  assert.equal(isAssistantModeEnabled({ [ASSISTANT_MODE_ENV]: "1" }), true);
  assert.equal(isAssistantModeEnabled({ [ASSISTANT_MODE_ENV]: "on" }), true);
  assert.equal(isAssistantModeEnabled({ [ASSISTANT_MODE_ENV]: "false" }), false);
  assert.equal(isAssistantModeEnabled({}), false);

  const previous = process.env[ASSISTANT_MODE_ENV];
  process.env[ASSISTANT_MODE_ENV] = "1";
  try {
    const { handlers } = createExtension();
    const event = { systemPromptOptions: { sections: {} as Record<string, string> } };
    handlers.get("before_agent_start")!(event);
    assert.match(event.systemPromptOptions.sections["field-notes-assistant"], /Assistant mode activated:/);
  } finally {
    if (previous === undefined) delete process.env[ASSISTANT_MODE_ENV];
    else process.env[ASSISTANT_MODE_ENV] = previous;
  }
});

test("instructions and schedule setup use the local config and required tasks", () => {
  const instructions = buildAssistantInstructions();
  const scheduleRequest = buildScheduleRequest();

  assert.match(instructions, /config\.toml/);
  assert.match(instructions, /Only add or change entries under today's date heading/);
  assert.match(instructions, /log-create/);
  assert.match(instructions, /journal-create/);
  assert.match(instructions, /kebab-case/);
  assert.match(instructions, /q4-planning-notes\.md/);
  assert.match(scheduleRequest, /assistant-start-of-day/);
  assert.match(scheduleRequest, /assistant-afternoon-checkin/);
  assert.match(scheduleRequest, /assistant-zoom-poll/);
  assert.match(scheduleRequest, /PI_ASSISTANT_MODE=1/);
  assert.match(scheduleRequest, /Do not change crontab/);
});
