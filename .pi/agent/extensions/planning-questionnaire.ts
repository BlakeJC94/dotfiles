import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { Editor, Key, matchesKey, Text, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui"
import { Type } from "typebox"

const QuestionOptionSchema = Type.Object({
  label: Type.String({ description: "Option label" }),
  description: Type.Optional(Type.String({ description: "Optional helper text" })),
})

const QuestionSchema = Type.Object({
  header: Type.Optional(Type.String({ description: "Short section header for this question" })),
  question: Type.String({ description: "Question to ask the user" }),
  options: Type.Array(QuestionOptionSchema, { description: "Available options" }),
  multiple: Type.Optional(Type.Boolean({ description: "Allow selecting multiple options" })),
  custom: Type.Optional(Type.Boolean({ description: "Allow typing a custom answer (default true)" })),
})

const Parameters = Type.Object({
  questions: Type.Array(QuestionSchema, { description: "Questions to ask in one interactive flow" }),
})

type QuestionOption = {
  label: string
  description?: string
}

type Question = {
  header?: string
  question: string
  options: QuestionOption[]
  multiple?: boolean
  custom?: boolean
}

type FlowResult = {
  cancelled: boolean
  answers: string[][]
}

const BLOCKED_DURING_CLARIFY = new Set(["edit", "write", "bash"])
const CUSTOM_OPTION_LABEL = "Type something."

function messageText(message: unknown): string {
  if (!message || typeof message !== "object") return ""
  const content = (message as { content?: unknown }).content
  if (typeof content === "string") return content.trim()
  if (!Array.isArray(content)) return ""

  return content
    .flatMap((item) => {
      if (!item || typeof item !== "object") return []
      const block = item as { type?: unknown; text?: unknown }
      if (block.type !== "text" || typeof block.text !== "string") return []
      return [block.text]
    })
    .join("\n")
    .trim()
}

function questionOptions(question: Question): QuestionOption[] {
  if (question.custom === false) return question.options
  return [...question.options, { label: CUSTOM_OPTION_LABEL }]
}

function hasCustomOption(question: Question, selected: number): boolean {
  if (question.custom === false) return false
  return selected === questionOptions(question).length - 1
}

function answerGroups(answers: Set<string>[]): string[][] {
  return answers.map((set) => Array.from(set.values()))
}

function questionnaireCancelledResult() {
  return {
    content: [{ type: "text", text: "User cancelled the questionnaire." }],
  }
}

function questionnaireUnavailableResult() {
  return {
    content: [{ type: "text", text: "Questionnaire unavailable in non-interactive mode." }],
    details: { cancelled: true, answers: [] as string[][] },
  }
}

function questionnaireEmptyResult() {
  return {
    content: [{ type: "text", text: "No questions provided." }],
    details: { cancelled: true, answers: [] as string[][] },
  }
}

export default function planningQuestionnaire(pi: ExtensionAPI) {
  let clarifyPlanningPhase = false

  pi.on("tool_call", async (event) => {
    // AIDEV-NOTE: /clarify enforces read-only planning by blocking mutating tools until run settles.
    if (!clarifyPlanningPhase) return
    if (!BLOCKED_DURING_CLARIFY.has(event.toolName)) return
    return {
      block: true,
      reason: `Blocked during clarify planning phase: ${event.toolName} is disabled until planning completes.`,
    }
  })

  pi.on("agent_settled", async (_event, ctx) => {
    if (!clarifyPlanningPhase) return
    clarifyPlanningPhase = false
    ctx.ui.setStatus("clarify-mode", undefined)
  })

  pi.registerCommand("clarify", {
    description: "Ask context-aware clarifying planning questions",
    handler: async (_args, ctx) => {
      // AIDEV-NOTE: /clarify rejects empty sessions to avoid blind questionnaire generation.
      const branch = ctx.sessionManager.getBranch()
      const recentUserContext = branch
        .slice()
        .reverse()
        .flatMap((entry) => {
          if (entry.type !== "message") return []
          const msg = entry.message as { role?: unknown }
          if (msg.role !== "user") return []
          const text = messageText(entry.message)
          if (!text) return []
          return [text]
        })
        .slice(0, 2)

      if (recentUserContext.length === 0) {
        ctx.ui.notify("No user context found in this session. Ask something first, then run /clarify.", "warning")
        return
      }

      if (!ctx.isIdle()) {
        ctx.ui.notify("/clarify can only run while the agent is idle.", "warning")
        return
      }

      const prompt = `Call planning_questionnaire now.\n\nBased on the current session context, ask 3-6 clarifying planning questions that are needed before producing an implementation plan.\n\nRules:\n- Questions must be concrete and decision-relevant\n- Prefer multiple choice options\n- Use multiple=true only when selection of several options is genuinely useful\n- Include custom=true when free-form input might be needed\n- Keep options concise\n\nAfter the questionnaire is answered, provide a short implementation plan.`

      clarifyPlanningPhase = true
      ctx.ui.setStatus("clarify-mode", ctx.ui.theme.fg("warning", "clarify: read-only"))
      pi.sendUserMessage(prompt)
    },
  })

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

      const result = await ctx.ui.custom<FlowResult>((tui, theme, _kb, done) => {
        // AIDEV-NOTE: Single component state machine mirrors opencode planning-mode batch question flow.
        let index = 0
        let selected = 0
        let editing = false
        let cached: string[] | undefined
        const answers = questions.map(() => new Set<string>())

        const editor = new Editor(tui, {
          borderColor: (s) => theme.fg("accent", s),
          selectList: {
            selectedPrefix: (t) => theme.fg("accent", t),
            selectedText: (t) => theme.fg("accent", t),
            description: (t) => theme.fg("muted", t),
            scrollInfo: (t) => theme.fg("dim", t),
            noMatch: (t) => theme.fg("warning", t),
          },
        })

        const atConfirm = () => index >= questions.length

        const refresh = () => {
          cached = undefined
          tui.requestRender()
        }

        const ensureBounds = () => {
          if (atConfirm()) {
            selected = 0
            return
          }

          const total = questionOptions(questions[index]).length
          if (selected >= total) selected = Math.max(0, total - 1)
        }

        const submit = (cancelled: boolean) => {
          done({
            cancelled,
            answers: answerGroups(answers),
          })
        }

        const advance = () => {
          if (index < questions.length - 1) {
            index += 1
            selected = 0
            refresh()
            return
          }

          index = questions.length
          selected = 0
          refresh()
        }

        const clearEditor = () => {
          editing = false
          editor.setText("")
        }

        const setSingleAnswer = (questionIndex: number, value: string) => {
          const bucket = answers[questionIndex]
          bucket.clear()
          bucket.add(value)
        }

        const addMultiAnswer = (questionIndex: number, value: string) => {
          answers[questionIndex].add(value)
        }

        const toggleOption = () => {
          const question = questions[index]
          const options = questionOptions(question)
          const option = options[selected]
          if (!option) return

          if (hasCustomOption(question, selected)) {
            editing = true
            editor.setText("")
            refresh()
            return
          }

          const bucket = answers[index]
          if (question.multiple) {
            if (bucket.has(option.label)) bucket.delete(option.label)
            else bucket.add(option.label)
            refresh()
            return
          }

          setSingleAnswer(index, option.label)
          advance()
        }

        editor.onSubmit = (value) => {
          if (atConfirm()) return

          const trimmed = value.trim()
          if (!trimmed) {
            clearEditor()
            refresh()
            return
          }

          const question = questions[index]
          if (question.multiple) addMultiAnswer(index, trimmed)
          else setSingleAnswer(index, trimmed)

          clearEditor()
          advance()
        }

        const line = (lines: string[], text: string, width: number) => {
          lines.push(...wrapTextWithAnsi(text, Math.max(1, width)))
        }

        const prefixed = (lines: string[], prefix: string, text: string, width: number) => {
          const prefixWidth = visibleWidth(prefix)
          if (prefixWidth >= width) {
            line(lines, `${prefix}${text}`, width)
            return
          }

          const wrapped = wrapTextWithAnsi(text, width - prefixWidth)
          const continuation = " ".repeat(prefixWidth)
          for (let i = 0; i < wrapped.length; i++) {
            lines.push(`${i === 0 ? prefix : continuation}${wrapped[i]}`)
          }
        }

        const renderConfirm = (lines: string[], width: number) => {
          prefixed(lines, " ", theme.fg("accent", theme.bold("Confirm answers")), width)
          lines.push("")

          for (let i = 0; i < questions.length; i++) {
            const question = questions[i]
            const picked = Array.from(answers[i].values())
            const header = question.header ? `${question.header}: ` : ""

            prefixed(lines, " ", theme.fg("muted", `${i + 1}. ${header}${question.question}`), width)
            prefixed(
              lines,
              "    ",
              picked.length > 0 ? theme.fg("text", picked.join(", ")) : theme.fg("warning", "Unanswered"),
              width,
            )
            lines.push("")
          }

          prefixed(lines, " ", theme.fg("success", "Enter submit - Shift+Tab edit previous - Esc cancel"), width)
        }

        const renderQuestion = (lines: string[], width: number) => {
          const question = questions[index]

          if (question.header) {
            prefixed(lines, " ", theme.fg("accent", theme.bold(question.header)), width)
            lines.push("")
          }

          prefixed(lines, " ", theme.fg("text", question.question), width)
          lines.push("")

          const options = questionOptions(question)
          const picked = answers[index]
          for (let i = 0; i < options.length; i++) {
            const option = options[i]
            const active = i === selected
            const marker = active ? theme.fg("accent", ">") : " "
            const checked = picked.has(option.label)
            const checkbox = question.multiple ? (checked ? "[x]" : "[ ]") : checked ? "(*)" : "( )"

            prefixed(lines, ` ${marker} `, `${checkbox} ${theme.fg(active ? "accent" : "text", `${i + 1}. ${option.label}`)}`, width)
            if (option.description) {
              prefixed(lines, "     ", theme.fg("muted", option.description), width)
            }
          }

          lines.push("")
          if (editing) {
            prefixed(lines, " ", theme.fg("muted", "Your answer:"), width)
            for (const row of editor.render(Math.max(1, width - 2))) {
              lines.push(` ${row}`)
            }
            prefixed(lines, " ", theme.fg("dim", "Enter save - Esc back"), width)
            return
          }

          const hint = question.multiple
            ? "Up/Down navigate - Space toggle - Enter continue - Shift+Tab previous - Esc cancel"
            : "Up/Down navigate - Enter select - Shift+Tab previous - Esc cancel"
          prefixed(lines, " ", theme.fg("dim", hint), width)
        }

        const handleEditingInput = (data: Buffer): boolean => {
          if (!editing) return false

          if (matchesKey(data, Key.escape)) {
            clearEditor()
            refresh()
            return true
          }

          editor.handleInput(data)
          refresh()
          return true
        }

        const handleConfirmInput = (data: Buffer): boolean => {
          if (!atConfirm()) return false

          if (matchesKey(data, Key.enter)) {
            submit(false)
            return true
          }

          if (matchesKey(data, Key.left) || matchesKey(data, Key.shift("tab"))) {
            index = Math.max(0, questions.length - 1)
            ensureBounds()
            refresh()
          }

          return true
        }

        const handleNavigationInput = (data: Buffer): boolean => {
          if (matchesKey(data, Key.up)) {
            selected = Math.max(0, selected - 1)
            refresh()
            return true
          }

          if (matchesKey(data, Key.down)) {
            selected = Math.min(questionOptions(questions[index]).length - 1, selected + 1)
            refresh()
            return true
          }

          if (matchesKey(data, Key.left) || matchesKey(data, Key.shift("tab"))) {
            index = Math.max(0, index - 1)
            ensureBounds()
            refresh()
            return true
          }

          if (matchesKey(data, Key.right) || matchesKey(data, Key.tab)) {
            const answered = answers[index].size > 0
            if (!questions[index].multiple && answered) {
              index = Math.min(questions.length, index + 1)
              ensureBounds()
              refresh()
            }
            return true
          }

          return false
        }

        const handleSelectionInput = (data: Buffer) => {
          if (matchesKey(data, Key.space) && questions[index].multiple) {
            toggleOption()
            return
          }

          if (!matchesKey(data, Key.enter)) return

          if (questions[index].multiple) {
            if (hasCustomOption(questions[index], selected)) {
              toggleOption()
              return
            }

            if (answers[index].size === 0) {
              toggleOption()
              return
            }

            advance()
            return
          }

          toggleOption()
        }

        return {
          invalidate: () => {
            cached = undefined
          },
          handleInput: (data) => {
            if (handleEditingInput(data)) return

            if (matchesKey(data, Key.escape)) {
              submit(true)
              return
            }

            if (handleConfirmInput(data)) return
            if (handleNavigationInput(data)) return
            handleSelectionInput(data)
          },
          render: (width) => {
            if (cached) return cached

            const lines: string[] = []
            const safeWidth = Math.max(1, width)
            lines.push(theme.fg("accent", "-".repeat(safeWidth)))

            const answeredCount = answers.filter((group) => group.size > 0).length
            prefixed(
              lines,
              " ",
              theme.fg("muted", `Question ${Math.min(index + 1, questions.length)} of ${questions.length} - ${answeredCount}/${questions.length} answered`),
              safeWidth,
            )
            lines.push("")

            if (atConfirm()) {
              renderConfirm(lines, safeWidth)
              lines.push(theme.fg("accent", "-".repeat(safeWidth)))
              cached = lines
              return lines
            }

            renderQuestion(lines, safeWidth)
            lines.push(theme.fg("accent", "-".repeat(safeWidth)))
            cached = lines
            return lines
          },
        }
      })

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
          return `"${header}${q.question}"="${selectedAnswers.length > 0 ? selectedAnswers.join(", ") : "Unanswered"}"`
        })
        .join(", ")

      return {
        content: [{ type: "text", text: `User has answered your questions: ${summary}.` }],
        details: result,
      }
    },

    renderCall(args, theme) {
      const total = Array.isArray(args.questions) ? args.questions.length : 0
      return new Text(
        `${theme.fg("toolTitle", theme.bold("planning_questionnaire "))}${theme.fg("muted", `${total} question${total === 1 ? "" : "s"}`)}`,
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
