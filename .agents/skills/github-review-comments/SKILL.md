---
name: github-review-comments
description: Write clear, useful, and kind GitHub / pull request review comments using Conventional Comments. Use when drafting or editing PR review feedback, replying to review threads, or reviewing a diff and deciding what to say. Covers tone, structure, severity labels, and when to stay silent.
---

# Writing GitHub Review Comments

Produce review comments that a colleague can act on in one read. Every comment should
answer: **what** you noticed, **why** it matters, and **what to do about it**. If a
comment doesn't change the code or the author's understanding, don't post it.

## Voice

Terse and technical. State the problem and the fix; stop.

- Default shape is a **short bullet list**: one point per line, not a paragraph.
  Exceptions: `nitpick` and `praise` are a single sentence, no bullets.
- Cut filler: no greetings, no "I might be wrong, but...", no restating the diff.
- No hedging. "This breaks X" beats "this could potentially maybe cause issues with X".
  If you're genuinely unsure, ask a `question` instead of hedging a claim. A leading
  question that frames a concrete claim is not hedging; a question with no claim is.
- No emoji. No "Great job!" without a specific technical reason.
- No `just`, `simply`, `obviously`, `of course`, `as I mentioned` - they read as
  condescending and carry no information.
- Assume competence. Don't explain language basics or what the diff already shows.

## Tone: lead with a question

The reliable way to raise an `issue` or `suggestion` without putting the author on the
defensive is to open with a question, then give the substance.

- `issue`: "Does `sum([])` ever run? It returns `None`, and the caller does `total + 1`,
  so the export job throws on empty input."
- `suggestion`: "Could this reuse `parseHeader`? The same three lines are in
  `parseFooter`, so the next fix has to land twice."

The question is framing, not softening. The concrete failure mode or reason must follow
in the same comment. A question with no claim is the hedging this skill bans.

Skip the question opener when:

- the label is `nitpick` or `praise` (already a single sentence).
- the label is `todo`, which wants a direct instruction.
- you have already established the problem earlier in the thread.

## Respect: critique the code, not the author

Assume the author had a reason. You see the diff, not the deadline, the upstream API, the
product decision, or the incident they are working around. A choice you disagree with may
still be correct under a constraint you can't see.

- Never imply the work is careless, lazy, or thoughtless. Comment on the artifact, not on
  the effort.
- Treat an omission as unknown, not as a mistake: "Is X handled elsewhere?" not "You
  forgot X."
- Ask about the constraint before insisting on the change: "Is this deliberate to avoid
  touching the shared cache?" If there is a reason, the comment becomes a `note`, not an
  `issue`.
- Make it easy to decline: "Ignore if this is intentional." "No action needed if this is
  deliberate." Give the author room to say no.
- Frame optional work as optional: "if there's time", "follow-up", "not for this PR".
- Don't relitigate a decision that is already made and recorded. Add a `note` for the
  record, or let it go.
- Defer on the author's domain. State your uncertainty as uncertainty, not as their error.

Respect does not mean softening into vagueness. Keep the concrete claim, drop the blame.

| Instead of | Say |
| --- | --- |
| "You forgot to handle null." | "Is null handled upstream? If not, this line throws." |
| "Why didn't you reuse `parseHeader`?" | "Could this reuse `parseHeader`? Same three lines as `parseFooter`." |
| "This is wrong." | "Does this case ever run? It looks like it returns `None` here." |
| "This needs tests." | "Any tests covering the retry path? Fine as a follow-up if not." |
| "Why is this hardcoded?" | "Is 30s fixed here or configurable upstream?" |

## House style

Rules borrowed from `~/.AGENTS.md`; they apply to review comments verbatim.

**Token efficiency**

- Compress. Every sentence in a comment must earn its place.
- No redundant context. Don't repeat what the diff or an earlier thread established.
- No soft warnings: no "Note that...", "Keep in mind that...", "It's worth mentioning...".

**Output**

- No preamble, no hollow closings. No "Let me know if you need anything!".
- No restating the prompt or the diff.
- Structured output only: bullets, tables, code blocks. Prose only when a single sentence
  is clearer.
- No "it's not X, it's Y" constructions.
- No unsolicited suggestions. Flag what the PR needs, not what you'd also like to see.

**Typography - ASCII only**

- Hyphens, not em dashes. Straight quotes, not curly. Three dots, not the ellipsis
  character. Hyphen or asterisk bullets, not Unicode bullets. No non-breaking spaces.
- Never modify content inside backticks; it is a literal example.

**Sycophancy - zero tolerance**

- Never validate the author before giving feedback. No "Great catch!", "Nice work!" as a
  preamble.
- Disagree when wrong. State the correction directly.
- `praise` is reserved for work you find genuinely impressive, which is rare. It is not a
  softening device around a critical review.

## Labels

Format: `label: subject`, followed by at most a short discussion. Multiple points become
bullets, one per line.

```
suggestion: Could this reuse `parseHeader`? The same three lines are in `parseFooter`,
so the next fix has to land twice.
```

Only these labels are used:

| Label | Use for |
| --- | --- |
| `issue` | A real problem: bug, regression, security hole, data loss. |
| `suggestion` | A better approach, not a defect. |
| `todo` | Small, concrete change expected before merge. |
| `nitpick` | Trivial style/preference. Post sparingly. |
| `question` | You don't understand something and can't resolve it from the diff. |
| `note` | Context future readers of the thread will want. |
| `praise` | Rare. Only for work you genuinely find impressive, not routine correctness. |

Not used: `thought`, `chore`, and `(blocking)` / `(non-blocking)` decorations.

## Blocking

Merge-blocking is signalled by the **review state** (`Request Changes`), not by a label
or decoration in the comment text. Keep comment text plain.

- `Request Changes` -> the review contains at least one unresolved `issue` or `todo`.
- `Comment` -> feedback that doesn't gate the merge.
- `Approve` -> no blocking items.

Because the state carries the weight, nothing you flag has to be loud. Don't inflate a
`suggestion` to `issue` to justify blocking.

## Depth scales with severity

| Label | Shape |
| --- | --- |
| `nitpick` | One sentence. Often skip it. |
| `suggestion`, `question` | One or two sentences: the change, plus the reason. Bullets if several points. |
| `note` | One or two sentences of context. |
| `issue`, `todo` | Name the failure mode concretely (what input/state triggers it, what breaks), then the minimal fix. Code snippet if shorter than prose. |
| `praise` | One sentence naming the specific impressive thing. |

When a short fix exists, the bullet ends with a code block rather than more prose.

## Fixes: bullets, then code

Keep it to a few bullets. Each bullet names one change and its reason.

If the fix is short and concrete, include it as a code block the author can copy. Use a
GitHub `suggestion` block whenever the change is confined to the lines you're commenting
on; GitHub renders it as an "Apply suggestion" button:

````
```suggestion
return sum(values) or 0
```
````

Rules:

- A `suggestion` block replaces exactly the lines you selected. Reproduce them verbatim
  (including indentation) and only use it for a drop-in replacement of that range. It
  can't apply a fix that also touches unchanged context around it.
- Use a plain fenced code block with the right language tag when the fix is partial,
  spans several locations, or is only a sketch.
- Don't write out a long implementation. If the fix needs more than a few lines, describe
  the approach in one bullet and stop.

## What you comment on

- **Correctness and bugs**: the priority.
- **Naming and readability**: where the name misleads or the structure hides intent.
- **Architecture and design**: put cross-cutting critique in the review body, not on a
  random line.
- **PR size / splitting**: say so in the review body, early, before line-by-line review.
- **Praised highlights**: rare. Only when something is genuinely impressive (a subtle bug
  found, an elegant simplification, a non-obvious edge case handled). Routine correctness
  gets no comment.

## When not to comment

- Formatting and lint. That's the formatter's job; never hand-comment it.
- Pure preference with no convention or lint rule behind it.
- Anything you'd resolve by re-reading the diff.
- A point already made in another thread: react or follow up instead of piling on.

## Never

- No emoji.
- No `just` / `simply` / `obviously` / `of course`.
- No "you forgot" / "why didn't you" / "why is this" phrasing, or any wording that implies
  carelessness, laziness, or oversight.
- No restating what the diff does.
- No formatting or lint comments.
- No AI-sounding hedging ("It's worth noting that...", "One might consider...",
  "This could potentially be improved").
- No sycophantic openers or validation of the author before feedback.
- No unsolicited broad refactors. Out-of-scope work gets a `note` pointing at a
  follow-up issue, not a thread.
- No em dashes, curly quotes, ellipsis characters, or Unicode bullets. ASCII only.

## Before you post

1. Re-read for the failure mode you claim: is it actually reachable?
2. Every `issue` / `todo` states what "done" looks like.
3. Cut the nitpicks; keep only the ones that change the code.
4. Set the right review state (`Request Changes` only if something blocks).
5. The best review is the shortest one that still catches the real problems.
