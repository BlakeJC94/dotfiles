import assert from "node:assert/strict";
import test from "node:test";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import assistantExtension, { buildAssistantInstructions, buildScheduleRequest } from "./index.ts";

function createExtension() {
  const commands = new Map<string, { handler: (args: string, ctx: unknown) => Promise<void> }>();
  const handlers = new Map<string, (event: { systemPromptOptions: { sections: Record<string, string> } }) => void>();
  const pi = {
    registerCommand(name: string, command: { handler: (args: string, ctx: unknown) => Promise<void> }) {
      commands.set(name, command);
    },
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
  assert.match(enabledEvent.systemPromptOptions.sections["workday-assistant"], /workday assistant mode/);

  await command.handler("off", ctx);
  const disabledEvent = { systemPromptOptions: { sections: { "workday-assistant": "old" } } };
  handlers.get("before_agent_start")!(disabledEvent);
  assert.equal(disabledEvent.systemPromptOptions.sections["workday-assistant"], undefined);
});

test("checkin adds assistant instructions for one turn without enabling the mode", async () => {
  const { commands, handlers } = createExtension();
  const command = commands.get("assistant")!;
  const { ctx, messages } = createContext();

  await command.handler("checkin", ctx);
  assert.equal(messages.length, 1);

  const checkinEvent = { systemPromptOptions: { sections: {} } };
  handlers.get("before_agent_start")!(checkinEvent);
  assert.ok(checkinEvent.systemPromptOptions.sections["workday-assistant"]);

  const nextEvent = { systemPromptOptions: { sections: { "workday-assistant": "old" } } };
  handlers.get("before_agent_start")!(nextEvent);
  assert.equal(nextEvent.systemPromptOptions.sections["workday-assistant"], undefined);
});

test("instructions and schedule setup use the local config and required tasks", () => {
  const instructions = buildAssistantInstructions();
  const scheduleRequest = buildScheduleRequest();

  assert.match(instructions, /config\.toml/);
  assert.match(instructions, /Only add or change entries under today's date inside ## Log/);
  assert.match(scheduleRequest, /assistant-start-of-day/);
  assert.match(scheduleRequest, /assistant-afternoon-checkin/);
  assert.match(scheduleRequest, /assistant-zoom-poll/);
  assert.match(scheduleRequest, /Do not change crontab/);
});
