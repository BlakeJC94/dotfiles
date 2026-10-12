---
name: my-reviewer-response
description: Respond to GitHub review feedback on the user's own pull request from a PR URL or number: fetch unresolved review threads, triage each finding, fix the accepted ones (asking per finding), and draft an author reply for every thread, posted only after approval. Use when asked to respond to, address, or work through review comments on a PR, or when invoked with /skill:my-reviewer-response.
---

# Responding to PR review feedback

## Input and guardrails

The appended user input must be either a GitHub PR URL (`https://github.com/<owner>/<repo>/pull/<number>`) or a numeric PR number for the current repository. If it is neither, ask for one of those inputs and stop.

- Verify the local checkout before touching code: compare `git branch --show-current` and `git rev-parse HEAD` against `gh pr view <pr> --json headRefName,headRefOid`. If the branch differs, stop and ask; never switch, fetch, or pull branches without approval. If only HEAD is behind the PR head, ask before pulling.
- Draft everything in chat; post, commit, and push only after the user approves. Never resolve threads or dismiss reviews unprompted.
- Replies post as the user, so write them in the author's voice, never as an agent.
- This skill does not override approval requirements for test edits, API changes, or dependencies.

## Fetch the review threads

Derive owner and repo from the PR URL, or from `gh repo view --json nameWithOwner --jq .nameWithOwner` for a bare number. Then list the threads:

```bash
gh api graphql -f query='
query {
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <pr-number>) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 50) {
            nodes { id path line originalLine side body author { login } }
          }
        }
      }
    }
  }
}'
```

- If there are no unresolved threads, say so and stop.
- Read every comment in a thread, not only the first: the finding may be refined, answered, or withdrawn further down.
- Triage only unresolved threads (`isResolved: false`); list resolved ones in one line and skip them. Judge every finding against the current code, even when the thread is outdated (`line` is null there; `originalLine` shows where it landed).
- Read review bodies as context. If a body carries actionable feedback with no matching thread, surface it and offer a draft PR comment (`gh pr comment`), posted only after approval.

Present the unresolved threads in chat numbered `1..N`: index, `path:line`, author, and a one-line summary of the finding. The index is chat-only and never appears in a reply; keep the session mapping from index to thread ID. If the mapping is lost, re-query and renumber.

## Triage

Work the threads in index order, unless the user limits the scope to specific threads or findings. For each, read the finding and enough surrounding code to judge it, then classify:

- `fix` - a real bug, regression, correctness risk, or clearly worthwhile improvement within task scope.
- `decline` - the claimed failure is not reachable, conflicts with task scope or requirements, is pure preference, or is already handled. State the concrete reason.
- `clarify` - the reviewer asked a question; answer it with evidence.

Verify the claimed failure is reachable before accepting; never blindly apply findings. Do not assume business logic: when a finding turns on an unknown requirement, ask the user which way to go. Give declines and clarifications evidence; a snippet that disproves or answers the claim beats prose.

## Fixes

For each accepted finding, ask the user whether to apply it or hand it back. Ask per finding.

When applying:

- Make the smallest change that fixes the finding.
- No test edits, new dependencies, or API changes without the required approval.
- After edits, check LSP diagnostics and run relevant permitted checks.
- Ask before committing; never push without approval. If the user pushes, capture the short SHA for the replies.

## Replies

Every unresolved thread gets exactly one reply. Follow `../github-review-comments/SKILL.md` voice rules verbatim: terse and technical, no hedging, no filler, no emoji, ASCII only. Author replies carry no Conventional Comments label - they are responses, not findings. Shapes:

| Outcome | Reply |
| --- | --- |
| Fixed and pushed | `Fixed in <short-sha>: <what changed>.` |
| Fixed, not pushed yet | `Fix coming in the next push: <what will change>.` |
| Handed back | `Taking this one: <plan>.` |
| Declined | The concrete reason; a snippet if it disproves the claim. Leave the reviewer room to push back. |
| Clarify | The answer; a snippet when it hinges on code. |

Sequence: fixes first, then replies - a reply references a pushed SHA only after the user has pushed it.

Draft every reply and show them numbered by thread index. The user approves, edits by index, or rejects each; reprint the list after every change so the indexes stay current. Post only approved replies:

```bash
gh api graphql -f query='
mutation {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: "<thread-id>"
    body: "<approved reply>"
  }) { comment { url } }
}'
```

To edit a reply after it posts: `updatePullRequestReviewComment` with `{pullRequestReviewCommentId, body}`.

## Completion

Report: threads replied to; findings fixed, handed back, and declined (with reasons); checks run; and anything left for the user. Never claim a reply was posted that was not.
