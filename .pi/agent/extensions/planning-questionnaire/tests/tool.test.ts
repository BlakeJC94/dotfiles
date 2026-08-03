import assert from "node:assert/strict"
import { test } from "node:test"

import { registerQuestionnaireTool } from "../tool.ts"
import type { FlowResult, Question } from "../types.ts"
import { createExecuteCtx, createFakePi, passthroughTheme } from "./helpers.ts"

type ToolShape = {
  name: string
  execute: (
    id: string,
    params: { questions: Question[] },
    signal: unknown,
    onUpdate: unknown,
    ctx: { mode: string; ui: { custom: (factory: unknown) => Promise<FlowResult> } },
  ) => Promise<{ content: { type: string; text: string }[]; details?: FlowResult }>
  renderCall: (
    args: { questions: Question[] },
    theme: { fg: (c: string, t: string) => string; bold: (t: string) => string },
  ) => { render: (w: number) => string[] }
  renderResult: (
    result: { content: { type: string; text: string }[]; details?: FlowResult },
    options: unknown,
    theme: { fg: (c: string, t: string) => string; bold: (t: string) => string },
  ) => { render: (w: number) => string[] }
}

/** Register the tool and return the captured tool definition. */
function registerTool(): { tool: ToolShape } {
  const pi = createFakePi()
  registerQuestionnaireTool(pi as unknown as Parameters<typeof registerQuestionnaireTool>[0])
  return { tool: pi.tools[0] as ToolShape }
}

const QUESTIONS: Question[] = [
  {
    header: "Lang",
    question: "Which language?",
    options: [{ label: "TypeScript" }, { label: "Python" }],
  },
]

test("the tool is registered with the expected name and metadata", () => {
  const { tool } = registerTool()
  assert.equal(tool.name, "planning_questionnaire")
})

test("execute returns an unavailable result in non-tui mode", async () => {
  const { tool } = registerTool()
  const { ctx } = createExecuteCtx("print", { cancelled: true, answers: [] })
  const res = await tool.execute("id", { questions: QUESTIONS }, undefined, undefined, ctx as never)
  assert.match(res.content[0].text, /non-interactive/)
  assert.equal(res.details?.cancelled, true)
  assert.deepEqual(res.details?.answers, [])
})

test("execute returns an empty result when no questions are provided", async () => {
  const { tool } = registerTool()
  const { ctx } = createExecuteCtx("tui", { cancelled: true, answers: [] })
  const res = await tool.execute("id", { questions: [] }, undefined, undefined, ctx as never)
  assert.match(res.content[0].text, /No questions provided/)
  assert.equal(res.details?.cancelled, true)
})

test("execute reports a cancelled questionnaire", async () => {
  const { tool } = registerTool()
  const { ctx } = createExecuteCtx("tui", { cancelled: true, answers: [] })
  const res = await tool.execute("id", { questions: QUESTIONS }, undefined, undefined, ctx as never)
  assert.match(res.content[0].text, /cancelled the questionnaire/)
  assert.equal(res.details?.cancelled, true)
})

test("execute summarizes answered questions", async () => {
  const { tool } = registerTool()
  const { ctx } = createExecuteCtx("tui", { cancelled: false, answers: [["TypeScript"]] })
  const res = await tool.execute("id", { questions: QUESTIONS }, undefined, undefined, ctx as never)
  assert.match(res.content[0].text, /User has answered your questions/)
  assert.match(res.content[0].text, /"Lang: Which language\?"="TypeScript"/)
  assert.equal(res.details?.cancelled, false)
})

test("execute marks unanswered questions as Unanswered in the summary", async () => {
  const { tool } = registerTool()
  const { ctx } = createExecuteCtx("tui", { cancelled: false, answers: [[]] })
  const res = await tool.execute("id", { questions: QUESTIONS }, undefined, undefined, ctx as never)
  assert.match(res.content[0].text, /Unanswered/)
})

test("renderCall shows the tool name and question count", () => {
  const { tool } = registerTool()
  const theme = passthroughTheme()
  const out = tool.renderCall({ questions: QUESTIONS }, theme).render(120)[0]
  assert.match(out, /planning_questionnaire/)
  assert.match(out, /1 question/)
  const plural = tool.renderCall({ questions: [...QUESTIONS, ...QUESTIONS] }, theme).render(120)[0]
  assert.match(plural, /2 questions/)
})

test("renderResult renders a cancelled result as Cancelled", () => {
  const { tool } = registerTool()
  const theme = passthroughTheme()
  const out = tool
    .renderResult(
      { content: [{ type: "text", text: "cancelled" }], details: { cancelled: true, answers: [] } },
      undefined,
      theme,
    )
    .render(120)[0]
  assert.equal(out.trim(), "Cancelled")
})

test("renderResult renders answered questions", () => {
  const { tool } = registerTool()
  const theme = passthroughTheme()
  const out = tool
    .renderResult(
      {
        content: [{ type: "text", text: "ok" }],
        details: { cancelled: false, answers: [["TypeScript"], ["Python"]] },
      },
      undefined,
      theme,
    )
    .render(120)
    .join("\n")
  assert.match(out, /Q1: TypeScript/)
  assert.match(out, /Q2: Python/)
})

test("renderResult renders unanswered questions as a warning", () => {
  const { tool } = registerTool()
  const theme = passthroughTheme()
  const out = tool
    .renderResult(
      {
        content: [{ type: "text", text: "ok" }],
        details: { cancelled: false, answers: [[], ["Python"]] },
      },
      undefined,
      theme,
    )
    .render(120)
    .join("\n")
  assert.match(out, /Q1: Unanswered/)
})

test("renderResult falls back to content text when details are absent", () => {
  const { tool } = registerTool()
  const theme = passthroughTheme()
  const out = tool
    .renderResult({ content: [{ type: "text", text: "just content" }] }, undefined, theme)
    .render(120)[0]
  assert.equal(out.trim(), "just content")
})
