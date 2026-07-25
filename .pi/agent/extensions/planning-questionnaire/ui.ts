import type { Theme } from "@earendil-works/pi-coding-agent"
import {
  Editor,
  Key,
  matchesKey,
  type Component,
  type TUI,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui"

import {
  answerGroups,
  hasCustomOption,
  type Question,
  questionOptions,
} from "./types.ts"

/**
 * Interactive multi-question questionnaire component.
 *
 * A single state machine that mirrors the opencode planning-mode batch question
 * flow: navigate options, toggle/select answers, optionally type a free-form
 * answer, then confirm (or cancel) the whole batch.
 *
 * Returned to `ctx.ui.custom()` and resolved with a {@link QuestionnaireResult}
 * when the user submits or cancels.
 */
export type QuestionnaireResult = {
  cancelled: boolean
  answers: string[][]
}

export class QuestionnaireComponent implements Component {
  private readonly tui: TUI
  private readonly theme: Theme
  private readonly questions: Question[]
  private readonly done: (result: QuestionnaireResult) => void
  private readonly editor: Editor

  private index = 0
  private selected = 0
  private editing = false
  private cached: string[] | undefined
  private readonly answers: Set<string>[]

  constructor(
    tui: TUI,
    theme: Theme,
    questions: Question[],
    done: (result: QuestionnaireResult) => void,
  ) {
    this.tui = tui
    this.theme = theme
    this.questions = questions
    this.done = done
    this.answers = questions.map(() => new Set<string>())

    this.editor = new Editor(tui, {
      borderColor: (s) => theme.fg("accent", s),
      selectList: {
        selectedPrefix: (t) => theme.fg("accent", t),
        selectedText: (t) => theme.fg("accent", t),
        description: (t) => theme.fg("muted", t),
        scrollInfo: (t) => theme.fg("dim", t),
        noMatch: (t) => theme.fg("warning", t),
      },
    })
    // Arrow field already bound to `this`; route editor submissions to it.
    this.editor.onSubmit = this.onEditorSubmit
  }

  // ---- public Component interface ----

  invalidate(): void {
    this.cached = undefined
  }

  handleInput(data: string): void {
    if (this.handleEditingInput(data)) return

    if (matchesKey(data, Key.escape)) {
      this.submit(true)
      return
    }

    if (this.handleConfirmInput(data)) return
    if (this.handleNavigationInput(data)) return
    this.handleSelectionInput(data)
  }

  render(width: number): string[] {
    if (this.cached) return this.cached

    const lines: string[] = []
    const safeWidth = Math.max(1, width)
    lines.push(this.theme.fg("accent", "-".repeat(safeWidth)))

    const answeredCount = this.answers.filter((group) => group.size > 0).length
    this.prefixed(
      lines,
      " ",
      this.theme.fg(
        "muted",
        `Question ${Math.min(this.index + 1, this.questions.length)} of ${this.questions.length} - ${answeredCount}/${this.questions.length} answered`,
      ),
      safeWidth,
    )
    lines.push("")

    if (this.atConfirm()) {
      this.renderConfirm(lines, safeWidth)
    } else {
      this.renderQuestion(lines, safeWidth)
    }

    lines.push(this.theme.fg("accent", "-".repeat(safeWidth)))
    this.cached = lines
    return lines
  }

  // ---- state helpers ----

  private atConfirm(): boolean {
    return this.index >= this.questions.length
  }

  private refresh(): void {
    this.cached = undefined
    this.tui.requestRender()
  }

  private ensureBounds(): void {
    if (this.atConfirm()) {
      this.selected = 0
      return
    }
    const total = questionOptions(this.questions[this.index]).length
    if (this.selected >= total) this.selected = Math.max(0, total - 1)
  }

  private submit(cancelled: boolean): void {
    this.done({ cancelled, answers: answerGroups(this.answers) })
  }

  private advance(): void {
    if (this.index < this.questions.length - 1) {
      this.index += 1
      this.selected = 0
      this.refresh()
      return
    }
    this.index = this.questions.length
    this.selected = 0
    this.refresh()
  }

  private clearEditor(): void {
    this.editing = false
    this.editor.setText("")
  }

  private setSingleAnswer(questionIndex: number, value: string): void {
    const bucket = this.answers[questionIndex]
    bucket.clear()
    bucket.add(value)
  }

  private addMultiAnswer(questionIndex: number, value: string): void {
    this.answers[questionIndex].add(value)
  }

  private toggleOption(): void {
    const question = this.questions[this.index]
    const options = questionOptions(question)
    const option = options[this.selected]
    if (!option) return

    if (hasCustomOption(question, this.selected)) {
      this.editing = true
      this.editor.setText("")
      this.refresh()
      return
    }

    const bucket = this.answers[this.index]
    if (question.multiple) {
      if (bucket.has(option.label)) bucket.delete(option.label)
      else bucket.add(option.label)
      this.refresh()
      return
    }

    this.setSingleAnswer(this.index, option.label)
    this.advance()
  }

  // ---- editor submission ----

  private readonly onEditorSubmit = (value: string): void => {
    if (this.atConfirm()) return

    const trimmed = value.trim()
    if (!trimmed) {
      this.clearEditor()
      this.refresh()
      return
    }

    const question = this.questions[this.index]
    if (question.multiple) this.addMultiAnswer(this.index, trimmed)
    else this.setSingleAnswer(this.index, trimmed)

    this.clearEditor()
    this.advance()
  }

  // ---- rendering ----

  private line(lines: string[], text: string, width: number): void {
    lines.push(...wrapTextWithAnsi(text, Math.max(1, width)))
  }

  private prefixed(lines: string[], prefix: string, text: string, width: number): void {
    const prefixWidth = visibleWidth(prefix)
    if (prefixWidth >= width) {
      this.line(lines, `${prefix}${text}`, width)
      return
    }

    const wrapped = wrapTextWithAnsi(text, width - prefixWidth)
    const continuation = " ".repeat(prefixWidth)
    for (let i = 0; i < wrapped.length; i++) {
      lines.push(`${i === 0 ? prefix : continuation}${wrapped[i]}`)
    }
  }

  private renderConfirm(lines: string[], width: number): void {
    this.prefixed(lines, " ", this.theme.fg("accent", this.theme.bold("Confirm answers")), width)
    lines.push("")

    for (let i = 0; i < this.questions.length; i++) {
      const question = this.questions[i]
      const picked = Array.from(this.answers[i].values())
      const header = question.header ? `${question.header}: ` : ""

      this.prefixed(lines, " ", this.theme.fg("muted", `${i + 1}. ${header}${question.question}`), width)
      this.prefixed(
        lines,
        "    ",
        picked.length > 0
          ? this.theme.fg("text", picked.join(", "))
          : this.theme.fg("warning", "Unanswered"),
        width,
      )
      lines.push("")
    }

    this.prefixed(
      lines,
      " ",
      this.theme.fg("success", "Enter submit - Shift+Tab edit previous - Esc cancel"),
      width,
    )
  }

  private renderQuestion(lines: string[], width: number): void {
    const question = this.questions[this.index]

    if (question.header) {
      this.prefixed(lines, " ", this.theme.fg("accent", this.theme.bold(question.header)), width)
      lines.push("")
    }

    this.prefixed(lines, " ", this.theme.fg("text", question.question), width)
    lines.push("")

    const options = questionOptions(question)
    const picked = this.answers[this.index]
    for (let i = 0; i < options.length; i++) {
      const option = options[i]
      const active = i === this.selected
      const marker = active ? this.theme.fg("accent", ">") : " "
      const checked = picked.has(option.label)
      const checkbox = question.multiple
        ? checked
          ? "[x]"
          : "[ ]"
        : checked
          ? "(*)"
          : "( )"

      this.prefixed(
        lines,
        ` ${marker} `,
        `${checkbox} ${this.theme.fg(active ? "accent" : "text", `${i + 1}. ${option.label}`)}`,
        width,
      )
      if (option.description) {
        this.prefixed(lines, "     ", this.theme.fg("muted", option.description), width)
      }
    }

    lines.push("")
    if (this.editing) {
      this.prefixed(lines, " ", this.theme.fg("muted", "Your answer:"), width)
      for (const row of this.editor.render(Math.max(1, width - 2))) {
        lines.push(` ${row}`)
      }
      this.prefixed(lines, " ", this.theme.fg("dim", "Enter save - Esc back"), width)
      return
    }

    const hint = question.multiple
      ? "Up/Down navigate - Space toggle - Enter continue - Shift+Tab previous - Esc cancel"
      : "Up/Down navigate - Enter select - Shift+Tab previous - Esc cancel"
    this.prefixed(lines, " ", this.theme.fg("dim", hint), width)
  }

  // ---- input handling ----

  private handleEditingInput(data: string): boolean {
    if (!this.editing) return false

    if (matchesKey(data, Key.escape)) {
      this.clearEditor()
      this.refresh()
      return true
    }

    this.editor.handleInput(data)
    this.refresh()
    return true
  }

  private handleConfirmInput(data: string): boolean {
    if (!this.atConfirm()) return false

    if (matchesKey(data, Key.enter)) {
      this.submit(false)
      return true
    }

    if (matchesKey(data, Key.left) || matchesKey(data, Key.shift("tab"))) {
      this.index = Math.max(0, this.questions.length - 1)
      this.ensureBounds()
      this.refresh()
    }

    return true
  }

  private handleNavigationInput(data: string): boolean {
    if (matchesKey(data, Key.up)) {
      this.selected = Math.max(0, this.selected - 1)
      this.refresh()
      return true
    }

    if (matchesKey(data, Key.down)) {
      this.selected = Math.min(questionOptions(this.questions[this.index]).length - 1, this.selected + 1)
      this.refresh()
      return true
    }

    if (matchesKey(data, Key.left) || matchesKey(data, Key.shift("tab"))) {
      this.index = Math.max(0, this.index - 1)
      this.ensureBounds()
      this.refresh()
      return true
    }

    if (matchesKey(data, Key.right) || matchesKey(data, Key.tab)) {
      const answered = this.answers[this.index].size > 0
      if (!this.questions[this.index].multiple && answered) {
        this.index = Math.min(this.questions.length, this.index + 1)
        this.ensureBounds()
        this.refresh()
      }
      return true
    }

    return false
  }

  private handleSelectionInput(data: string): void {
    if (matchesKey(data, Key.space) && this.questions[this.index].multiple) {
      this.toggleOption()
      return
    }

    if (!matchesKey(data, Key.enter)) return

    const question = this.questions[this.index]
    if (question.multiple) {
      if (hasCustomOption(question, this.selected)) {
        this.toggleOption()
        return
      }

      if (this.answers[this.index].size === 0) {
        this.toggleOption()
        return
      }

      this.advance()
      return
    }

    this.toggleOption()
  }
}

/**
 * Construct the questionnaire component inside the `ctx.ui.custom()`
 * callback. Returns a `Component` ready for the TUI to render.
 */
export function createQuestionnaireComponent(
  tui: TUI,
  theme: Theme,
  questions: Question[],
  done: (result: QuestionnaireResult) => void,
): QuestionnaireComponent {
  return new QuestionnaireComponent(tui, theme, questions, done)
}
