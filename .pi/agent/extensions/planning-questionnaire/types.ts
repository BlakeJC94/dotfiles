import { Type } from "typebox"

/** Typebox schemas describing the tool parameters to the LLM. */
export const QuestionOptionSchema = Type.Object({
  label: Type.String({ description: "Option label" }),
  description: Type.Optional(Type.String({ description: "Optional helper text" })),
})

export const QuestionSchema = Type.Object({
  header: Type.Optional(Type.String({ description: "Short section header for this question" })),
  question: Type.String({ description: "Question to ask the user" }),
  options: Type.Array(QuestionOptionSchema, { description: "Available options" }),
  multiple: Type.Optional(Type.Boolean({ description: "Allow selecting multiple options" })),
  custom: Type.Optional(Type.Boolean({ description: "Allow typing a custom answer (default true)" })),
})

export const Parameters = Type.Object({
  questions: Type.Array(QuestionSchema, { description: "Questions to ask in one interactive flow" }),
})

/** Domain types derived from the schemas above. */
export type QuestionOption = {
  label: string
  description?: string
}

export type Question = {
  header?: string
  question: string
  options: QuestionOption[]
  multiple?: boolean
  custom?: boolean
}

export type FlowResult = {
  cancelled: boolean
  answers: string[][]
}

/** Mutating tools blocked while a clarify planning phase is active. */
export const BLOCKED_DURING_CLARIFY = new Set(["edit", "write", "bash"])

/** Label appended as an extra option when custom input is allowed. */
export const CUSTOM_OPTION_LABEL = "Type something."

/** Options shown for a question, with the custom-entry option appended unless disabled. */
export function questionOptions(question: Question): QuestionOption[] {
  if (question.custom === false) return question.options
  return [...question.options, { label: CUSTOM_OPTION_LABEL }]
}

/** True when the given selection index points at the appended custom-entry option. */
export function hasCustomOption(question: Question, selected: number): boolean {
  if (question.custom === false) return false
  return selected === questionOptions(question).length - 1
}

/** Convert per-question answer sets into ordered arrays for the result payload. */
export function answerGroups(answers: Set<string>[]): string[][] {
  return answers.map((set) => Array.from(set.values()))
}
