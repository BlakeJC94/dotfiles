---
name: pr-description-style
description: Use when drafting or revising a GitHub pull request description, especially one that explains a cron, pipeline, or other ordered workflow. Default to scannable dot points and short, clear sentences.
---

# PR description style

Apply the writing rules from `~/.AGENTS.md` and the shared voice rules in
`~/.agents/skills/github-review-comments/SKILL.md`. This skill governs PR bodies,
not review comments. Follow the repo's PR creation workflow for required sections.

## Ground the description

- Read the current PR body before revising it. Preserve the author's wording and sections outside the requested change.
- Check the diff, relevant code, and completed checks before making claims. Do not invent behaviour, test results, links, or deployment status.
- Lead with the outcome and the context a cold reviewer needs. Add the reason for a choice only when it is not apparent from the diff.
- Name identifiers a reviewer can search for. Do not narrate files, hunks, commit history, or the conversation that produced the change.

## Default structure

- Under `## Summary`, use `**Problem**` and `**Solution**` labels, each followed by concise dot points. Problem points state the issue directly; nested points show the progression that leads to it. Solution points state the change and use "so that..." to explain its intent; nested points briefly show how it addresses the problem. Include only details that help reviewers understand the change.
- Use flat `-` dot points for substantive changes outside the summary. For a process, use one `- **Stage:** Action. Observable result.` point per stage in execution order. Do not use numbered paragraphs.
- Keep each point to one or two short sentences. Split a long stage or omit details already visible in code comments.
- Describe a concrete risk or scope boundary only when it changes what the reviewer should check. Do not pad the body with empty sections.
- After the Problem and Solution points, add an optional `### Before / After` subsection under `## Summary` with a concise fenced `mermaid` diagram when the change has a meaningful visual before-and-after comparison. Show the important high-level flow or state before and after the change, with clearly labelled Before and After sections; omit it when a diagram would be forced or add no clarity. Keep it factual, grounded in the diff, and readable at a glance.
- Put verification in the test plan. Mark a check complete only after observing it pass; leave deployment and manual checks unchecked until done.

## Voice and typography

- Write plain, direct, factual sentences. State cause and effect; cut filler, hedging, marketing language, AI jargon, and soft warnings.
- Assume the reviewer is competent. Critique the code or risk, never the author; do not imply carelessness or explain language basics.
- Be concise: every sentence must add context, an outcome, a risk, or a verification result. No greetings, praise openers, or hollow closings.
- Use ASCII: hyphens and `-` bullets, straight quotes, and three periods. No em dashes, curly quotes, ellipsis characters, Unicode bullets, or emoji.
- Do not use "just", "simply", "obviously", "of course", "you forgot", or "why didn't you". Avoid "it's not X, it's Y" constructions.

## Footer and review-only conventions

Append this exact block once at the end of every agent-written PR description:

<details>
<summary>Agent-assisted: See attached manifesto, all feedback welcome via Slack (@bcook)</summary>

```
- PRs only move out of "draft" mode after manual review (full diff and description) --- no exceptions
- All agent-assisted GitHub communication will be marked
    - Reviewed verbatim agent output prefixed with `[AGENT]` (for example, `[AGENT:Coder]`)
    - All agent-assisted text marked with `Agent-assisted`
- Agent coding guidelines:
    - Follow existing conventions and reuse abstractions
    - Prefer the simplest clear solution and smallest reviewable diff
    - clarity **always** beats brevity
- Agent messaging guidelines:
    - Use short, direct sentences; every word must earn its place
    - Prefer spaced bullets to dense paragraphs
- Check behavior, claims, and links. Cite sources and state what's unchecked.
```

</details>

Do not add another PR-description footer. Conventional Comments labels,
question-first feedback, and review states belong to review comments; do not put
them in a PR description. Keep the PR's required headings and test-plan format.
