---
name: my-reviewer-pr
description: >-
  Review one GitHub pull request from its URL or number with the my-reviewer review norms, produce a concise REVIEW-{PR NUMBER}-{BRANCH NAME SLUG}.md report, and start a pending (unsubmitted) GitHub review with the findings as draft comments the user checks and iterates on in chat. GitHub review comments follow github-review-comments etiquette and carry a [AGENT:Reviewer] prefix. Use when asked to review a GitHub PR or when invoked with /skill:my-reviewer-pr.
---

# GitHub PR Review

The appended user input must be either:

- A GitHub PR URL: `https://github.com/<owner>/<repo>/pull/<number>`
- A numeric PR number for the current repository

If it is neither, ask for one of those inputs and stop.

## Norms and comment etiquette

- Read `../my-reviewer/SKILL.md` and apply its Review norms to every finding: severity, the file/area, the issue, why it matters, and the smallest suggested change. The report artifact captures the same findings `my-reviewer` outputs directly, plus what the change is and how to test it.
- Every GitHub review comment - pending drafts, edits, added comments, and thread replies - starts with `[AGENT:Reviewer] `, followed by the Conventional Comments label: `[AGENT:Reviewer] issue: ...`. End each with a blank line and `<sub>Agent-assisted</sub>` on its own final line. Follow `../github-review-comments/SKILL.md` for the first-sentence, blank-line, short-dotpoint style, tone, review state for blocking, and when to stay silent. The prefix overrides that skill's `label: subject` opening; its other rules still apply.
- In an `issue:` comment, use the dotpoints to explain the failure and why it matters. After those dotpoints, put the smallest fix on its own line, separated by a blank line, as `suggestion: Could ...?` (or another direct question). Do not bury the fix in the explanatory dotpoints. Keep the comment's opening `[AGENT:Reviewer] issue:` label; the later `suggestion:` is a separate recommendation, not a second review comment. For example:

  ~~~text
  [AGENT:Reviewer] issue: Can the primary destination have its own rate?

  - The builder constructs it without a rate, so Weave cannot be ramped down while it remains primary.

  suggestion: Could the builder accept a primary rate and test primary-off / Langfuse-on export?

  <sub>Agent-assisted</sub>
  ~~~

## Workflow

1. Derive the PR number.
2. Fetch the diff and PR context. Use the PR diff as the source of truth and the title/body as supporting context:

```bash
gh pr diff <pr-url-or-number>
gh pr view <pr-url-or-number> --json title,body,baseRefName,headRefName,headRefOid
```

   Also fetch all existing inline review comments (including replies), PR conversation comments, and review summaries. Paginate each endpoint; ignore bot noise when assessing the change. Fetch review-thread state so resolved and outdated threads are not treated as open findings. Read these before judging the diff, and check whether an author reply or a later commit has addressed each concern:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr-number}/comments?per_page=100" --paginate
gh api "repos/{owner}/{repo}/issues/{pr-number}/comments?per_page=100" --paginate
gh api "repos/{owner}/{repo}/pulls/{pr-number}/reviews?per_page=100" --paginate
gh api graphql --paginate -F owner=<owner> -F name=<repo> -F number=<pr-number> -f query='
query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $endCursor) {
        nodes { id isResolved isOutdated comments(first: 100) { nodes { id body author { login } } } }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}'
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
8. Inspect only what is necessary to understand the diff and its risks. Count the lines in the PR diff from step 2. Run `git llm-pr-diff <pr-url-or-number>` only when the diff is **900 lines or fewer**. For larger diffs, skip the alias and record the line-count reason in the report. When run, verify the annotated output against the original diff; treat its explanations as aids, not findings. If annotation fails, record the reason instead of using partial output. Review test coverage by tracing the changed behavior through its meaningful states and transitions (for example: success, failure, skip, partial export, retry, and teardown where applicable). Check assertions on observable outcomes, not just whether lines execute. Identify missing state coverage only when it protects a concrete failure mode; do not request tests for every branch or a coverage percentage. Compare each finding with existing review threads: verify whether it still applies at the current head, and distinguish a new issue from additional evidence for an existing one. Do not repeat a concern already resolved or answered.
9. Make one update to the report file. Do not modify any other file. Attribute overlapping findings to the existing review thread; do not present them as newly discovered. If the existing comment already says everything useful, cite it in the report and do not post a redundant reply.
10. Start a pending GitHub review with draft comments for findings that do not overlap existing threads. Do not submit it: never call `gh pr review` (it submits) and omit both `body` and `event` so the review is left `PENDING`. If there are only overlapping findings with useful new evidence, start the pending review with `"comments": []` and add draft replies as described below. If there are no comments or replies worth posting, start no review:

```bash
gh api -X POST "repos/{owner}/{repo}/pulls/{pr-number}/reviews" --input - <<'EOF'
{"comments": [{"path": "<file>", "line": <n>, "side": "RIGHT", "body": "[AGENT:Reviewer] <label: comment>\n\n<sub>Agent-assisted</sub>"}]}
EOF
```

   Follow `../github-review-comments/SKILL.md` for each comment: Conventional Comments label, question-first tone, suggestion blocks, and only findings worth posting. Anchor each new comment from the diff hunk headers: `side` `RIGHT` for added or kept lines, `LEFT` for removed lines, plus `start_line`/`start_side` for a multi-line range. Confirm the response has `"state": "PENDING"`. Only one pending review may exist per user per PR - if creation fails because one already exists, ask the user before deleting and recreating it.

   For a finding that overlaps an existing unresolved thread, add any new evidence or smallest fix as a **draft reply on that thread**, not a new inline comment. Resolve the thread's GraphQL ID and pass the pending review's GraphQL ID as `pullRequestReviewId` to `addPullRequestReviewThreadReply`:

```graphql
mutation($reviewId: ID!, $threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewId: $reviewId,
    pullRequestReviewThreadId: $threadId,
    body: $body
  }) { comment { id body } }
}
```

   Use `gh api graphql` with variables for that mutation. Check the review remains `PENDING` and the reply belongs to it. If GitHub cannot save the reply as a pending draft, do not post an ordinary reply: keep the finding in the local report and tell the user. Report the PR URL to the user and print all draft comments and replies as a numbered list (see `Iterating on the draft comments`).
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

- Add a draft comment: `addPullRequestReviewThread` with `{pullRequestId, pullRequestReviewId, body, path, line, side}` (`pullRequestId` from `gh pr view <pr> --json id --jq .id`); it attaches to the existing pending review.

- Add a draft reply to an existing thread: `addPullRequestReviewThreadReply` with `{pullRequestReviewId, pullRequestReviewThreadId, body}`. Re-query the thread and confirm the reply belongs to the pending review; never fall back to an ordinary posted reply.

Before editing, deleting, or adding a comment, confirm the review is still `PENDING`. After every change, reprint the numbered list so the indexes stay current. If the user has submitted the review, do not post ordinary thread replies or start another review: draft any follow-up feedback in chat for the user instead. Every rewritten or added draft body keeps the `[AGENT:Reviewer] ` prefix and the final `<sub>Agent-assisted</sub>` line, and follows `../github-review-comments/SKILL.md`. Only the user submits the pending review.

## Report requirements

- Start with `# <PR title>`.
- Immediately follow with a quick health check: size (`S`, `M`, `L`, or `XL`) and readiness (`Ready`, `Needs Work`, or `Blocked`).
- Assess size from review complexity, blast radius, and risk, not raw line count alone.
- Exclude generated files, artifacts, and lockfile-only churn from size/risk scoring unless central to the change.
- If the PR is too large or risky for a high-quality review, say why in 1-2 bullets.
- Summarize the change in short, clear chunks.
- List actionable findings with severity and concrete diff file/area references: the issue, why it matters, and the smallest suggested change. Link or identify existing review threads when a finding overlaps, and distinguish unresolved issues from answered or outdated comments.
- Include a brief `## State coverage` section: name the significant changed states/transitions, point to tests that verify their outcomes, and call out consequential gaps. Do not substitute line or code-coverage percentages for this assessment. Flag tests whose setup or indirection obscures the behavior they should document, when it materially hinders review.
- Include a reviewer checklist using Markdown task items. Each top-level item is a non-generated changed file, with file-specific unordered sub-checks, including changed test files.
- Include thoughtful questions for the developer.
- Include `## Quick testing steps` with 3-6 actionable smoke-test steps. Prefer PR-body testing guidance, then fill gaps from the diff.
- Use short sentences, dot points, and nested lists. Avoid long paragraphs.
- Leave a blank line after every list item.
- Include the full annotated diff under `## Annotated diff` in a fenced text block, or explain why it is unavailable. The annotated diff is reference material; keep the rest of the report concise.
