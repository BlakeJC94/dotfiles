import assert from "node:assert/strict";
import { test } from "node:test";

import { buildReviewPrompt, getReviewState, hasCompletedMarker, type ReviewState } from "../review-state.ts";

const review: ReviewState = {
  id: "cycle-1",
  reviewerModel: { provider: "review-provider", model: "review-model", thinkingLevel: "high" },
  name: "my-reviewer-cycle1",
  round: 2,
  status: "waiting",
  goal: "Keep role state branch-local.",
  planSection: "~/Workspace/field-notes/repos-gitreview.md ## PROJ-1234 Fix bug plot issue",
  diffScope: "my-agent/index.ts and tests",
  decisions: "No fallback model.",
  constraints: "Read-only reviewer.",
  checkResults: "node --test passed.",
  updates: "Applied the state restoration fix.",
  revision: "abc123",
  marker: "MY_AGENT_REVIEW_COMPLETE_cycle-1_2",
};

test("getReviewState restores pending reviewer identity and scope from the branch", () => {
  const restored = getReviewState([
    { type: "custom", customType: "my-agent-review", data: review },
  ]);

  assert.deepEqual(restored, review);
  assert.equal(getReviewState([]), undefined);
});

test("pending startup and role-activation states restore the pane identity", () => {
  const starting = { ...review, status: "starting" as const, paneId: "w1:p7" };
  const restoredStarting = getReviewState([{ type: "custom", customType: "my-agent-review", data: starting }]);
  const activating = { ...starting, status: "activating" as const };
  const restoredActivating = getReviewState([{ type: "custom", customType: "my-agent-review", data: activating }]);

  assert.equal(restoredStarting?.status, "starting");
  assert.equal(restoredStarting?.paneId, "w1:p7");
  assert.equal(restoredActivating?.status, "activating");
});

test("an echoed prompt marker alone does not establish completed feedback", () => {
  const marker = "MY_AGENT_REVIEW_COMPLETE_cycle-1_2";

  assert.equal(hasCompletedMarker(`prompt requests ${marker}`, marker), false);
  assert.equal(hasCompletedMarker(`prompt requests ${marker}\\nresponse ends ${marker}`, marker), true);
});

test("buildReviewPrompt sends the same reviewer updated scope and a completion marker", () => {
  const prompt = buildReviewPrompt(review);

  assert.match(prompt, /^Review the current changes/);
  assert.doesNotMatch(prompt, /\/skill:my-reviewer/);
  assert.match(prompt, /Review cycle: cycle-1; round 2\/3; revision: abc123\./);
  assert.match(prompt, /Applied the state restoration fix\./);
  assert.match(prompt, /End your complete response with this exact line: MY_AGENT_REVIEW_COMPLETE_cycle-1_2/);
});
