---
name: my-reviewer
description: "Establish the base review norms, and spawn a Pi reviewer through Herdr that applies them for up to three rounds or until no further notes remain. Use when explicitly asked for a Herdr reviewer or iterative review focused on simplicity, minimal dependencies, and clear, compact code. Requires HERDR_ENV=1."
---

# My reviewer

## Review norms

The base norms for every review I run; `my-reviewer-prs` builds on them for GitHub PR reviews.

Output the findings directly in the response; this skill writes no artifact. `my-reviewer-prs` runs the same review but captures the findings in a markdown report (adding what the change is and how to test it) and starts a pending GitHub review with the findings as draft comments.

Focus on:

- Simplicity: prefer the smallest understandable solution over abstractions.
- Minimal dependencies: flag avoidable additions and use existing facilities.
- Unnecessary logic: identify redundant branches, checks, state, and helpers.
- Compact code: remove duplication and dead code without sacrificing clarity.
- Spacing: use consistent formatting and whitespace to separate logical steps.
- Comments: explain non-obvious intent, not what the code already says.

Preserve correctness, required edge cases, public contracts, and task scope.
Do not recommend clever compression, speculative features, broad refactors,
or removing safeguards without evidence. Avoid cosmetic churn and invented
findings. Report only actionable improvements worth making. Every finding
states its severity, the file and line (or area), the issue, why it
matters, and the smallest suggested change.

## Scope and setup

- Read `../herdr/SKILL.md` completely and follow its environment checks, CLI discovery, layout, and coordination rules.
- If not running inside Herdr, stop and explain that this workflow requires a Herdr-managed pane.
- Review the current task's changes, not unrelated work. Use the user's supplied files or diff range; otherwise use the current task's diff. If the scope is unclear, ask before starting.
- Read project instructions. This workflow does not override approval requirements for test edits, API changes, dependencies, or other restricted changes.
- Inspect live agents before creating one. Spawn a fresh Pi agent named `reviewer`; if that name is occupied, choose a unique name such as `reviewer-2` without interrupting the existing agent.
- Create a sibling pane in the current tab, preserve the caller's working directory, and keep focus in the calling pane. Follow the Herdr skill's geometry guidance and use the returned pane ID.
- Discover the installed CLI syntax and confirm Pi support before starting. Start the agent with `--kind pi`, not another coding agent.

Example after CLI discovery, substituting the actual name and returned pane ID:

```bash
herdr agent start reviewer --kind pi --pane <returned-pane-id>
```

## Reviewer instructions

Send the reviewer the task goal, exact review scope, relevant constraints, and this prompt. The reviewer only sees the submitted text, so paste the Review norms section above into the placeholder verbatim. Replace placeholders with concrete context before submission:

```text
You are the reviewer for this task: <goal>.
Review only: <files or diff range>.
Constraints: <project instructions and behavior/API requirements>.

Read the changes and enough surrounding code to understand them. Do not edit
files, install dependencies, or run mutating commands. Return feedback only.

<Review norms from the section above, pasted verbatim>

If no actionable findings remain, reply: "No further notes."
```

Submit through `herdr agent prompt <name> "<prompt>" --wait --timeout 120000`, then read the completed feedback with `herdr agent read <name> --source recent-unwrapped --lines 200`. Follow the Herdr skill's recovery rules if blocked, stalled, timed out, or output is incomplete. Never equate an idle state or missing output with a clean review.

## Review loop

Run at most **three reviewer rounds total**, including the initial review:

1. Get feedback from the reviewer.
2. Evaluate each finding against the code and task requirements. Apply only justified, in-scope changes that the user has authorized. Ask for approval when project instructions require it. Explain rejected findings rather than blindly applying them.
3. After edits, check LSP diagnostics and run relevant permitted checks. Do not modify tests or add dependencies without the required approval.
4. If the reviewer reports no further actionable notes, stop early.
5. Otherwise, if fewer than three rounds have completed, ask the same reviewer to re-read the updated files/diff. Include changes made, findings declined with reasons, and check results. Ask it to verify fixes and report only remaining or newly introduced actionable issues using the same criteria.

After round three, address justified findings within authorization, then stop. Do not start a fourth review or claim the final edits were re-reviewed if they were not.

## Completion

- Report rounds completed, improvements made, checks run, and unresolved or declined findings.
- Distinguish a clean reviewer result from reaching the three-round limit with unverified final edits.
- Leave the reviewer pane available for inspection unless the user requests cleanup. Never close or interrupt unrelated agents or panes.
