import assert from "node:assert/strict"
import { test } from "node:test"

import {
  answerGroups,
  CUSTOM_OPTION_LABEL,
  hasCustomOption,
  questionOptions,
  type Question,
} from "../types.ts"

const baseQuestion: Question = {
  question: "Pick one",
  options: [
    { label: "A" },
    { label: "B", description: "second" },
  ],
}

test("questionOptions appends the custom-entry option by default", () => {
  const opts = questionOptions(baseQuestion)
  assert.equal(opts.length, 3)
  assert.deepEqual(opts[opts.length - 1], { label: CUSTOM_OPTION_LABEL })
})

test("questionOptions omits the custom-entry option when custom is false", () => {
  const q: Question = { ...baseQuestion, custom: false }
  assert.equal(questionOptions(q).length, 2)
})

test("hasCustomOption is true only for the appended custom-entry index", () => {
  const q = baseQuestion
  assert.equal(hasCustomOption(q, 0), false)
  assert.equal(hasCustomOption(q, 1), false)
  assert.equal(hasCustomOption(q, 2), true) // last index == custom entry
})

test("hasCustomOption is always false when custom is disabled", () => {
  const q: Question = { ...baseQuestion, custom: false }
  assert.equal(hasCustomOption(q, 0), false)
  assert.equal(hasCustomOption(q, questionOptions(q).length - 1), false)
})

test("answerGroups converts per-question Sets into ordered arrays", () => {
  const groups = [new Set<string>(["A"]), new Set<string>(), new Set<string>(["X", "Y"])]
  assert.deepEqual(answerGroups(groups), [["A"], [], ["X", "Y"]])
})
