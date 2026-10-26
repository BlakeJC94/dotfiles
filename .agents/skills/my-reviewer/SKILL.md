---
name: my-reviewer
description: "Review the current task's changes as a read-only reviewer, focusing on simplicity, minimal dependencies, and clear, compact code. Use when asked to review a diff or when summoned as a Pi reviewer through Herdr."
---

# My reviewer

## Review norms

The base norms for every review I run; `my-reviewer-pr` builds on them for GitHub PR reviews.

Prefix every GitHub communication this reviewer creates with `[AGENT:Reviewer] `:
comments and replies, PR titles and descriptions, and commit subjects. This
also applies to pending draft comments in `my-reviewer-pr`. End every GitHub
comment or reply and PR description this reviewer writes with a blank line and
`<sub>Agent-assisted</sub>` on its own final line; keep the existing prefixes.
Local review findings and reports need neither marker.

Output the findings directly in the response; this skill writes no artifact. `my-reviewer-pr` runs the same review but captures the findings in a markdown report (adding what the change is and how to test it) and starts a pending GitHub review with the findings as draft comments.

`git llm-diff [diff-args...]` runs the `llm-diff-explain` template on a git diff and returns the diff with a plain-language explanation before each hunk. It rejects diffs over 3000 lines. Use its output as an aid to understanding the changes, not as a substitute for reading the original diff and surrounding code. For PR reviews, `git llm-pr-diff [pr-diff-args...]` applies the same template and 3000-line limit to `gh pr diff` output. The `my-reviewer-pr` report includes that annotated PR diff when available.

Focus on:

- Simplicity: prefer the smallest understandable solution over abstractions.
- Minimal dependencies: flag avoidable additions and use existing facilities.
- Unnecessary logic: identify redundant branches, checks, state, and helpers.
- Compact code: remove duplication and dead code without sacrificing clarity.
- Spacing: use consistent formatting and whitespace to separate logical steps.
- Comments: explain non-obvious intent, not what the code already says.

Preserve correctness, required edge cases, public contracts, and task scope.
Inspect changed tests and test configuration for removed or skipped cases,
relaxed assertions, narrowed discovery, and changed expectations. A changed
expectation is justified only by the approved behavior with equivalent or
stronger coverage; flag test weakening used to make checks pass. Favor tests
that cover meaningful states and transitions over code coverage percentages.
Tests should read as documentation: simple setup, action, and observable
outcome, without indirection that hides the behavior. Do not recommend clever
compression, speculative features, broad refactors, or
removing safeguards without evidence. Avoid cosmetic churn and invented
findings. Report only actionable improvements worth making. Every finding
states its severity, the file and line (or area), the issue, why it
matters, and the smallest suggested change.

## Review task

- Review the goal, scope, and constraints supplied with the invocation. Read the specified diff/files and enough surrounding code to understand the change. If the scope is unclear, ask instead of reviewing unrelated work.
- Work in the current worktree and branch. Do not edit files, install dependencies, create or switch branches, or run mutating commands. Follow project instructions.
- Return only actionable findings following the norms above. If none remain, reply: "No further notes."
- For a subsequent review round, read the updated diff, reported fixes, declined findings, and check results; report only remaining or newly introduced actionable issues. Do not assume the fixes worked without checking.
