---
name: my-reviewer-prs
description: Review a GitHub pull request from its URL or number with the my-reviewer review norms, produce a concise REVIEW-{PR NUMBER}-{BRANCH NAME SLUG}.md report, and start a pending (unsubmitted) GitHub review with the findings as draft comments the user checks and iterates on in chat. GitHub review comments follow github-review-comments etiquette. Use when asked to review a GitHub PR or when invoked with /skill:my-reviewer-prs.
---

# GitHub PR Review

The appended user input must be either:

- A GitHub PR URL: `https://github.com/<owner>/<repo>/pull/<number>`
- A numeric PR number for the current repository

If it is neither, ask for one of those inputs and stop.

## Norms and comment etiquette

- Read `../my-reviewer/SKILL.md` and apply its Review norms to every finding: severity, the file/area, the issue, why it matters, and the smallest suggested change. The report artifact captures the same findings `my-reviewer` outputs directly, plus what the change is and how to test it.
- Every GitHub review comment - the pending review's draft comments, or replies in threads - follows `../github-review-comments/SKILL.md`: Conventional Comments labels, question-first tone, review state for blocking, and when to stay silent.

## Workflow

1. Derive the PR number.
2. Fetch the diff and PR context. Use the PR diff as the source of truth and the title/body as supporting context:

```bash
gh pr diff <pr-url-or-number>
gh pr view <pr-url-or-number> --json title,body,baseRefName,headRefName,headRefOid
```

3. Derive the branch name slug from `headRefName`: lowercase it, replace every run of non-alphanumeric characters with `-`, and trim leading or trailing `-`.
4. Set the report path to `REVIEW-{PR NUMBER}-{BRANCH NAME SLUG}.md` at the project root.
5. Read the existing report if it exists.

6. Use `gh api` and the PR base ref plus head OID to get the comparison response's `merge_base_commit.sha`:

```bash
gh api "repos/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/compare/<base-ref>...<head-oid>" --jq '.merge_base_commit.sha'
```

7. Inspect `git worktree list --porcelain` to find a worktree whose checked-out `HEAD` is that merge-base SHA.
   - If found, inspect the relevant files in that worktree to add context for the PR diff. Do not modify it.
   - Otherwise, inspect the `master` or `main` branch checked out in the primary worktree for context.
   - Use `gh pr diff` for the PR comparison. Never check out the PR branch; do not clone, fetch, or switch branches.
8. Inspect only what is necessary to understand the diff and its risks.
9. Make one update to the report file. Do not modify any other file.
10. Start a pending GitHub review carrying the findings as draft comments. Do not submit it: never call `gh pr review` (it submits) and omit both `body` and `event` so the review is left `PENDING`:

```bash
gh api -X POST "repos/{owner}/{repo}/pulls/{pr-number}/reviews" --input - <<'EOF'
{"comments": [{"path": "<file>", "line": <n>, "side": "RIGHT", "body": "<label: comment>"}]}
EOF
```

   Follow `../github-review-comments/SKILL.md` for each comment: Conventional Comments label, question-first tone, suggestion blocks, and only findings worth posting. A clean review starts no pending review at all. Anchor each comment from the diff hunk headers: `side` `RIGHT` for added or kept lines, `LEFT` for removed lines, plus `start_line`/`start_side` for a multi-line range. Confirm the response has `"state": "PENDING"`, then report the PR URL to the user and print the draft comments in the chat as a numbered list (see `Iterating on the draft comments`). Only one pending review may exist per user per PR - if creation fails because one already exists, ask the user before deleting and recreating it.
11. If running inside Herdr (`HERDR_ENV=1`), open the report in nvim in a new horizontal split for the user to read. Follow the Herdr skill (`../herdr/SKILL.md`) for environment checks and CLI rules; preserve the caller's cwd and keep focus in the calling pane:

```bash
herdr pane split --current --direction down --cwd "$PWD" --no-focus
herdr pane run <new-pane-id> "nvim <report-path>"
```

   Take the new pane ID from the split response's `.result.pane.pane_id`. Outside Herdr, skip this step.
12. Reply only with a short confirmation.

## Iterating on the draft comments

After the pending review exists, list its draft comments in the chat numbered `1..N`: index, `path`, and the full comment body. The index is chat-only - it never appears in a comment body - and lives only in the session, as a mapping from index to the comment's Node ID.

The user reworks the comments by index (e.g. "soften 2", "drop 3", "add one on the error path"). Resolve the index through the session mapping. If the mapping is lost, re-query the pending review's comments and renumber before editing:

```bash
gh api graphql -f query='
query {
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <pr-number>) {
      reviews(last: 1, states: PENDING) {
        nodes { comments(first: 100) { nodes { id path body } } }
      }
    }
  }
}'
```

Apply each requested change through `gh api graphql`:

- Edit a comment: `updatePullRequestReviewComment` with `{pullRequestReviewCommentId, body}`.

- Delete a comment: `deletePullRequestReviewComment` with `{id}`.

- Add a draft comment: `addPullRequestReviewThread` with `{pullRequestId, body, path, line, side}` (`pullRequestId` from `gh pr view <pr> --json id --jq .id`); it attaches to the existing pending review.

After every change, reprint the numbered list so the indexes stay current. These mutations work only while the review is `PENDING`; once the user has submitted it, iterate through ordinary thread replies instead. Every rewritten body still follows `../github-review-comments/SKILL.md`.

## Report requirements

- Start with `# <PR title>`.
- Immediately follow with a quick health check: size (`S`, `M`, `L`, or `XL`) and readiness (`Ready`, `Needs Work`, or `Blocked`).
- Assess size from review complexity, blast radius, and risk, not raw line count alone.
- Exclude generated files, artifacts, and lockfile-only churn from size/risk scoring unless central to the change.
- If the PR is too large or risky for a high-quality review, say why in 1-2 bullets.
- Summarize the change in short, clear chunks.
- List actionable findings with severity and concrete diff file/area references: the issue, why it matters, and the smallest suggested change.
- Include a reviewer checklist using Markdown task items. Each top-level item is a non-generated changed file, with file-specific unordered sub-checks.
- Include thoughtful questions for the developer.
- Include `## Quick testing steps` with 3-6 actionable smoke-test steps. Prefer PR-body testing guidance, then fill gaps from the diff.
- Use short sentences, dot points, and nested lists. Avoid long paragraphs.
- Leave a blank line after every list item.
- Keep the report concise.
