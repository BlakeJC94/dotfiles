---
name: review
description: Review a GitHub pull request from its URL or number, then produce a concise REVIEW-{repo}-{PR NUMBER}.md report. Use when asked to review a GitHub PR or when invoked with /skill:review.
---

# GitHub PR Review

The appended user input must be either:

- A GitHub PR URL: `https://github.com/<owner>/<repo>/pull/<number>`
- A numeric PR number for the current repository

If it is neither, ask for one of those inputs and stop.

## Workflow

1. Derive the PR number. For a URL, derive the repository name from its path. For a number, use the current directory basename as the repository name.
2. Set the report path to `REVIEW-{repo}-{PR NUMBER}.md` at the project root.
3. Read the existing report if it exists.
4. Fetch the diff, PR context, and merge base. Use the PR diff as the source of truth and the title/body as supporting context:

```bash
gh pr diff <pr-url-or-number>
gh pr view <pr-url-or-number> --json title,body,baseRefName,headRefOid
```

5. Use `gh api` and the PR base ref plus head OID to get the comparison response's `merge_base_commit.sha`:

```bash
gh api "repos/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/compare/<base-ref>...<head-oid>" --jq '.merge_base_commit.sha'
```

6. Inspect `git worktree list --porcelain` to find a worktree whose checked-out `HEAD` is that merge-base SHA.
   - If found, inspect the relevant files in that worktree to add context for the PR diff. Do not modify it.
   - Otherwise, inspect the `master` or `main` branch checked out in the primary worktree for context.
   - Use `gh pr diff` for the PR comparison. Never check out the PR branch; do not clone, fetch, or switch branches.
7. Inspect only what is necessary to understand the diff and its risks.
8. Make one update to the report file. Do not modify any other file.
9. Optionally run this once after writing the report. Continue if it fails:

```bash
dprint fmt REVIEW-{repo}-{PR NUMBER}.md
```

10. Reply only with a short confirmation.

## Report requirements

- Start with `# <PR title>`.
- Immediately follow with a quick health check: size (`S`, `M`, `L`, or `XL`) and readiness (`Ready`, `Needs Work`, or `Blocked`).
- Assess size from review complexity, blast radius, and risk, not raw line count alone.
- Exclude generated files, artifacts, and lockfile-only churn from size/risk scoring unless central to the change.
- If the PR is too large or risky for a high-quality review, say why in 1-2 bullets.
- Summarize the change in short, clear chunks.
- List actionable findings with severity and concrete diff file/area references.
- Include a reviewer checklist using Markdown task items. Each top-level item is a non-generated changed file, with file-specific unordered sub-checks.
- Include thoughtful questions for the developer.
- Include `## Quick testing steps` with 3-6 actionable smoke-test steps. Prefer PR-body testing guidance, then fill gaps from the diff.
- Use short sentences, dot points, and nested lists. Avoid long paragraphs.
- Leave a blank line after every list item.
- Keep the report concise.
