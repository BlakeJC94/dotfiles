import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { Text } from "@earendil-works/pi-tui"

import {
  createQuestionnaireComponent,
  type QuestionnaireResult,
} from "./ui.ts"
import { Parameters, type FlowResult, type Question } from "./types.ts"

/** Register the `planning_questionnaire` tool and its renderers. */
export function registerQuestionnaireTool(pi: ExtensionAPI): void {
  pi.registerTool({
    name: "planning_questionnaire",
    label: "Planning Questionnaire",
    description:
      "Ask a batch of clarifying planning questions in one interactive UI, then confirm before returning answers.",
    promptSnippet: "Ask users clarifying planning questions in one interactive widget.",
    promptGuidelines: [
      "Use planning_questionnaire when you need multiple clarifying answers before producing a plan.",
      "Use planning_questionnaire instead of asking one question per model turn.",
    ],
    parameters: Parameters,
    executionMode: "sequential",

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (ctx.mode !== "tui") return questionnaireUnavailableResult()

      const questions = params.questions as Question[]
      if (questions.length === 0) return questionnaireEmptyResult()

      const result = await ctx.ui.custom<QuestionnaireResult>((tui, theme, _kb, done) =>
        createQuestionnaireComponent(tui, theme, questions, done),
      )

      if (result.cancelled) {
        return {
          ...questionnaireCancelledResult(),
          details: result,
        }
      }

      const summary = questions
        .map((q, i) => {
          const header = q.header ? `${q.header}: ` : ""
          const selectedAnswers = result.answers[i]
          return `"${header}${q.question}"="${
            selectedAnswers.length > 0 ? selectedAnswers.join(", ") : "Unanswered"
          }"`
        })
        .join(", ")

      return {
        content: [{ type: "text" as const, text: `User has answered your questions: ${summary}.` }],
        details: result,
      }
    },

    renderCall(args, theme) {
      const total = Array.isArray(args.questions) ? args.questions.length : 0
      return new Text(
        `${theme.fg("toolTitle", theme.bold("planning_questionnaire "))}${theme.fg(
          "muted",
          `${total} question${total === 1 ? "" : "s"}`,
        )}`,
        0,
        0,
      )
    },

    renderResult(result, _options, theme) {
      const details = result.details as FlowResult | undefined
      if (!details) {
        const text = result.content[0]
        return new Text(text?.type === "text" ? text.text : "", 0, 0)
      }
      if (details.cancelled) {
        return new Text(theme.fg("warning", "Cancelled"), 0, 0)
      }

      const lines = details.answers.map((group, i) => {
        if (group.length === 0) return `${theme.fg("warning", `Q${i + 1}: Unanswered`)}`
        return `${theme.fg("success", `Q${i + 1}:`)} ${group.join(", ")}`
      })
      return new Text(lines.join("\n"), 0, 0)
    },
  })
}

function questionnaireCancelledResult() {
  return {
    content: [{ type: "text" as const, text: "User cancelled the questionnaire." }],
  }
}

function questionnaireUnavailableResult() {
  return {
    content: [{ type: "text" as const, text: "Questionnaire unavailable in non-interactive mode." }],
    details: { cancelled: true, answers: [] as string[][] },
  }
}

function questionnaireEmptyResult() {
  return {
    content: [{ type: "text" as const, text: "No questions provided." }],
    details: { cancelled: true, answers: [] as string[][] },
  }
}
