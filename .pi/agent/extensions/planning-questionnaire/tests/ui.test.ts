import assert from "node:assert/strict"
import { test } from "node:test"

import { QuestionnaireComponent, type QuestionnaireResult } from "../ui.ts"
import type { Question } from "../types.ts"
import { fakeTui, passthroughTheme } from "./helpers.ts"

/** Raw terminal byte sequences the component matches via `matchesKey`. */
const KEY = {
  enter: "\r",
  escape: "\x1b",
  space: " ",
  up: "\x1b[A",
  down: "\x1b[B",
  left: "\x1b[D",
  right: "\x1b[C",
  shiftTab: "\x1b[Z",
} as const

function newComponent(
  questions: Question[],
): { component: QuestionnaireComponent; result: () => QuestionnaireResult | undefined } {
  let captured: QuestionnaireResult | undefined
  const component = new QuestionnaireComponent(
    fakeTui() as never,
    passthroughTheme() as never,
    questions,
    (r) => {
      captured = r
    },
  )
  return { component, result: () => captured }
}

const SINGLE: Question[] = [
  {
    header: "Lang",
    question: "Which language?",
    options: [{ label: "TypeScript" }, { label: "Python" }],
  },
]

const MULTI: Question[] = [
  {
    question: "Which frameworks?",
    multiple: true,
    options: [{ label: "React" }, { label: "Vue" }, { label: "Svelte" }],
  },
]

test("renders the question screen with header, progress, and options", () => {
  const { component } = newComponent(SINGLE)
  const lines = component.render(80)
  const out = lines.join("\n")
  assert.match(out, /Question 1 of 1 - 0\/1 answered/)
  assert.match(out, /Lang/)
  assert.match(out, /Which language\?/)
  assert.match(out, /TypeScript/)
  assert.match(out, /Python/)
})

test("the active option is marked with '>'", () => {
  const { component } = newComponent(SINGLE)
  const out = component.render(80).join("\n")
  assert.match(out, / > .*TypeScript/)
  assert.match(out, / {3}.*Python/)
})

test("down arrow moves the selection marker", () => {
  const { component } = newComponent(SINGLE)
  component.handleInput(KEY.down)
  const out = component.render(80).join("\n")
  assert.match(out, / {3}.*TypeScript/)
  assert.match(out, / > .*Python/)
})

test("enter on a single-select question selects and advances to confirm", () => {
  const { component } = newComponent(SINGLE)
  component.handleInput(KEY.enter) // select TypeScript -> advance
  const out = component.render(80).join("\n")
  assert.match(out, /Confirm answers/)
  assert.match(out, /TypeScript/)
})

test("enter on the confirm screen submits the answers", () => {
  const { component, result } = newComponent(SINGLE)
  component.handleInput(KEY.enter) // select
  component.handleInput(KEY.enter) // submit
  const res = result()
  assert.ok(res)
  assert.equal(res!.cancelled, false)
  assert.deepEqual(res!.answers, [["TypeScript"]])
})

test("escape on the question screen cancels the whole questionnaire", () => {
  const { component, result } = newComponent(SINGLE)
  component.handleInput(KEY.escape)
  const res = result()
  assert.ok(res)
  assert.equal(res!.cancelled, true)
})

test("space toggles a multi-select option without advancing", () => {
  const { component } = newComponent(MULTI)
  component.handleInput(KEY.space) // toggle React
  const out = component.render(80).join("\n")
  assert.match(out, /\[x\] .*React/)
  assert.match(out, /\[ \] .*Vue/)
})

test("down then space toggles the second option in multi-select", () => {
  const { component } = newComponent(MULTI)
  component.handleInput(KEY.down)
  component.handleInput(KEY.space) // toggle Vue
  const out = component.render(80).join("\n")
  assert.match(out, /\[ \] .*React/)
  assert.match(out, /\[x\] .*Vue/)
})

test("enter on multi-select with answers advances to confirm", () => {
  const { component, result } = newComponent(MULTI)
  component.handleInput(KEY.space) // toggle React
  component.handleInput(KEY.enter) // answers present -> advance
  const out = component.render(80).join("\n")
  assert.match(out, /Confirm answers/)
  assert.equal(result(), undefined, "should not have submitted yet")
})

test("confirm screen lists answered questions and the submit hint", () => {
  const two: Question[] = [
    { header: "H1", question: "Q1", options: [{ label: "A" }] },
    { question: "Q2", options: [{ label: "B" }] },
  ]
  const { component } = newComponent(two)
  component.handleInput(KEY.enter) // answer Q1 = A -> advance to Q2
  component.handleInput(KEY.enter) // answer Q2 = B -> advance to confirm
  const out = component.render(80).join("\n")
  assert.match(out, /Confirm answers/)
  assert.match(out, /H1: Q1[\s\S]*A/)
  assert.match(out, /Q2[\s\S]*B/)
  assert.match(out, /Enter submit - Shift\+Tab edit previous - Esc cancel/)
})

test("shift+tab from confirm returns to the last question", () => {
  const { component } = newComponent(SINGLE)
  component.handleInput(KEY.enter) // select -> confirm
  assert.match(component.render(80).join("\n"), /Confirm answers/)
  component.handleInput(KEY.shiftTab)
  assert.match(component.render(80).join("\n"), /Which language\?/)
})

test("left arrow navigates to the previous question", () => {
  const two: Question[] = [
    { question: "Q1", options: [{ label: "A" }] },
    { question: "Q2", options: [{ label: "B" }] },
  ]
  const { component } = newComponent(two)
  component.handleInput(KEY.enter) // Q1 -> Q2
  assert.match(component.render(80).join("\n"), /Q2/)
  component.handleInput(KEY.left)
  assert.match(component.render(80).join("\n"), /Q1/)
})

test("selecting the custom-entry option opens the free-form editor", () => {
  // default custom === undefined means custom is allowed -> custom entry appended
  const q: Question[] = [{ question: "Name?", options: [{ label: "A" }] }]
  const { component } = newComponent(q)
  component.handleInput(KEY.down) // move to custom entry (last option)
  component.handleInput(KEY.enter) // toggleOption -> editing true
  const out = component.render(80).join("\n")
  assert.match(out, /Your answer:/)
})

test("escape exits the free-form editor without submitting", () => {
  const q: Question[] = [{ question: "Name?", options: [{ label: "A" }] }]
  const { component, result } = newComponent(q)
  component.handleInput(KEY.down)
  component.handleInput(KEY.enter) // enter editing
  component.handleInput(KEY.escape) // back out of editor
  const out = component.render(80).join("\n")
  assert.doesNotMatch(out, /Your answer:/)
  assert.match(out, /Name\?/)
  assert.equal(result(), undefined, "should not have cancelled the whole questionnaire")
})
