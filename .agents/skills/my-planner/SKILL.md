---
name: my-planner
description: Write a concise, repo-verified PLAN.md feature specification before implementation. Use when the user asks to plan a Jira ticket, or to write a spec/plan/PLAN.md for a feature or fix. For Jira tickets, crawl linked tickets and PRs via the Codex Atlassian/GitHub connectors; for prose, start with a clarifying questionnaire. Ask targeted questions about definition of done and verification commands before drafting.
---

# my-planner: pre-implementation feature specifications

Produce a PLAN.md the user can review, fill gaps in, and hand to a coding
agent. The spec separates what is verified fact from what needs the user's
decision. The development loop lives in `../my-coder/SKILL.md`; specs never
carry it.

## Process

1. Detect input mode: Jira ticket (key/URL) or feature/fix description.
2. Gather context: crawl tickets + PRs (ticket mode) or questionnaire
   (description mode). See below.
3. Verify every ticket claim against the current tree. Tickets carry stale
   paths (pre-migration, moved packages). Verify paths, symbols, and line
   numbers with grep/read before writing them down.
4. Before drafting, batch unresolved decisions into one `planning_questionnaire`.
   Ask explicitly what "done" means and which commands or manual checks prove
   it when the ticket or repo does not settle them. Prefer options grounded in
   verified repo commands. Do not ask for facts the tree already answers.
5. Write PLAN.md from the template below, in the repo root (or where the user
   points). If an answer is deferred, put a `* **QUESTION**` dotpoint in
   **Ask before**, with the reason and options; leave a following
   `* **ANSWER**` dotpoint for the developer to fill in. Do not guess.
6. Report the unanswered questions to the user: count, where they are, one
   line each.

## Input mode A: Jira ticket

Crawl order:

- `atlassian.getAccessibleAtlassianResources` once per session. Cache the
  cloudId. Pass it on every call.
- Main ticket: `atlassian.getJiraIssue`, view "evidence" (returns issue links).
- Linked tickets: follow `issuelinks`. Fetch tickets that gate the work
  (blocks / is blocked by), define its fixtures, tolerances, or pricing. Use
  view "compact" unless central to the plan. Skip backlog parents and
  unrelated relates unless cited.
- Comments: `atlassian.discover` to find `listJiraIssueComments`, then run it
  via `atlassian.executeRead`. Probe results, smoke results, and decisions
  often live here, not in the ticket body.
- PRs: check the Development field (merged/open counts). Then
  `github.search_prs` (query the ticket key, repo `Canva/canva`, state all) and
  `github.get_users_recent_prs_in_repo` if the dev panel is stale. PR bodies
  hold test evidence, merged-PR status, and what was deliberately left out.
- Verify in-tree: does the merged code exist in this checkout? Are ticket
  paths current? Are claimed gaps real (grep for the missing thing)?
- Extract explicit acceptance and verification evidence from the ticket and
  PRs. If the observable definition of done, required commands, or manual
  verification are absent or ambiguous, ask the developer before drafting.
  Offer the commands found in the tree as options, not invented commands.

## Input mode B: feature/fix description

Before writing anything, run one `planning_questionnaire` batch. Cover:

- The problem: who has it, what happens today, why it matters.
- Desired observable outcome after the change.
- Scope boundaries: in scope, out of scope.
- Hard constraints: API contracts, performance, dependencies, data handling.
- Deliverable: working-tree changes, commit, draft PR?
- Definition of done: what must be observable, what must not regress, and
  whether partial or unverified outcomes are acceptable.
- Verification: exact test/lint/build commands, manual checks, and any
  credentials, network access, cost, or environment needed to run them.

Offer discrete options where possible; allow custom answers. Then verify repo
paths and existing patterns as in ticket mode. If the repo contradicts an
answer or reveals a missing verification decision, batch those questions once
before drafting; otherwise do not ask again.

## Writing rules

Style (all learned the hard way):

- Target 150-230 lines. Short sentences. Every word earns its place.
- Dotpoints over prose. Semicolon lists become bullets.
- No tables. Users read raw markdown. ACs are dotpoints.
- ASCII only. Hyphens, not em dashes.
- Define shorthands once: a path abbreviation in the header, "Unit" for the
  main bazel test target, then reuse.
- Cite evidence: file paths with line numbers, ticket statuses, PR numbers,
  dates. Verified facts get their line refs.
- Header preamble states: paths verified against current tree, path
  abbreviation, and a question index line ("N unanswered questions: ...")
  so the user sees their workload at a glance.
- Use exactly `* **QUESTION** <question>` for unresolved decisions and a
  following `* **ANSWER**` dotpoint for the developer's response. Keep them
  together in **Ask before**, including questions about commands, done criteria,
  PR scope, public API, naming, and spend. Refer to the decision from
  **Commands** or **Done** instead of adding ambiguous placeholders there.
  Never silently resolve a decision the user owns. A question answered in the
  questionnaire becomes a concrete requirement, not another open question.
- Ensure **Done** states observable outcomes and **Commands** lists exact
  verified commands (or says why a check cannot run). Ask before drafting if
  either depends on an unmade developer decision. Include a hard constraint to
  preserve or strengthen tests; test updates following approved behavior need
  no separate approval, but weakening tests or checks to get green is forbidden.
  Define verification around meaningful behavior states and transitions, not
  code coverage percentages; favor tests simple enough to document behavior.
- Map ACs to requirements: `AC1 (R1,R3,R5): scenario. Expected. Verify: ...`.
- References section at the bottom, academic style: every ticket and PR the
  doc cites, one line each, status + URL.
- Respect repo AGENTS.md for the deliverable (draft PRs by default, formatter,
  push only when asked).

## Template

```
# [TICKET-KEY]: [summary]

Paths verified against the current tree. Ticket paths are pre-migration;
[package] lives under [real path] ([abbrev] below).
N unanswered questions for you: all in section 2 (or 0 if resolved).

## 1. Task and desired outcome

**Problem**

* [bullets: what happens today, why it fails, who it hits]

**[PR 1 / stage name]**

* R1: [behaviour]
* R2: [behaviour]

**[PR 2 / later stage, gated on X]**

* R6: [behaviour]
* R7: [behaviour]

**Out of scope**

* [items with ticket keys]

## 2. Constraints and decisions

**Hard**

* [testable constraints: defaults, hermetic tests, gating, no-conditionals]

**Preferences**

* [tradeable guidance]

**Agent may decide**

* [implementation freedom]

**Ask before**

* **QUESTION** [Decision needed? Cite evidence, options, and blast radius.]
* **ANSWER**
* **QUESTION** [What observable result counts as done, if still undecided?]
* **ANSWER**
* **QUESTION** [Which verified command or manual check is required, if still undecided?]
* **ANSWER**

## 3. Relevant context

**Files (line refs current)**

* [path] - [symbols + line numbers + why it matters]
* [path] - [why]

**Preserve**

* [contracts that must keep working]

**Pitfalls**

* [verified gotcha + evidence]
* [expected observations that look like failures]

**Known unknowns**

* [Non-blocking unknown and where the answer lives; move developer-owned decisions to Ask before.]

## 4. Acceptance criteria

"Unit" = [main test target].

* AC1 (R1,R3): [scenario]. [expected]. Verify: [how].
* AC2 (R1): ...

**Commands**

* Unit: [target]. If [other lib] touched: [target].
* Smoke (needs [key], real spend): [command and verified invocation, or explicit reason not run].
* Formatter before push.

**Done**

* [Observable definition of done agreed with the developer; no generic checklist substituted for it.]
* Every R has evidence. Required checks pass. No blocking review findings.
* Unverified behaviour reported explicitly.

**Deliverable**: [working tree / commit / draft PR, as decided in section 2]

## 5. References

* [KEY] - [one-line descriptor] ([status]). [URL]
* [PR #] - [title] ([state, date]). [URL]
```
