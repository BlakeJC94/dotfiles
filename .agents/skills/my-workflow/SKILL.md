---
name: my-workflow
description: Coordinate the full planner-to-merge workflow with explicit developer gates and Herdr-managed role agents. Use when the developer asks to run a feature from planning through PR review.
---

# my-workflow: coordinate a feature from idea to merge readiness

Invoke this standalone skill with `/skill:my-workflow`. It coordinates the role
agents but does not add a `/agent workflow` role. The role skills own their
work:

- `my-planner` researches the request and appends a `##` plan section to this
  worktree's field note.
- `my-coder` implements the approved plan, runs checks, and uses the managed reviewer loop.
- `my-reviewer` reviews changes read-only and reports actionable findings.
- `my-monkey` probes likely bugs read-only; this stage is optional.
- The developer approves the plan and draft PR. The external PR reviewer approves or requests changes after the PR enters its train.

Pass this workflow context to every agent you start, along with its exact task,
its parent agent name, and the required handoff. Agents must not assume other
roles' responsibilities or skip a user gate.

## 1. Preconditions and coordination

- Run only in the current Herdr-managed session. Verify `HERDR_ENV=1` and
  Herdr readiness before controlling agents. If unavailable, stop and report
  that this workflow requires Herdr.
- Use the current branch, worktree, and working directory for every role. Never
  create or switch branches, stash, discard work, or close sessions you did not
  create.
- Read `~/.pi/agent/my-agent.json` and use the configured model for each role.
  Do not invent a model or continue if a role has no available, authenticated
  configuration.
- Assign a short workflow ID. Ensure the coordinator and every child agent
  have unique Herdr names containing that ID and their role, such as
  `wf7-coord`, `wf7-planner`, and `wf7-coder`. Rename the coordinator's
  current pane with `herdr agent rename` if needed so child agents can message
  it. Create sibling panes with `herdr pane split --current`, preserve the
  current working directory, and use `--no-focus`. Read pane and agent IDs from
  Herdr responses; do not predict them.
- Activate a role with a separate `/agent <role>` prompt and wait for it to
  settle before sending its task. Do not append task text to the role command.
- Role agents use `my_agent_communicate` to discover and message exact peer
  names in the same Herdr workspace. The coordinator may use the Herdr CLI
  directly when that tool is not active. Message only named workflow
  participants, and only when idle or done. If a peer is busy or blocked,
  inspect its state and output; do not inject a second task or repeat a
  possibly delivered prompt. Relay through the coordinator when direct delivery
  is not safe.
- Agents share a worktree. Serialize edits: the coder must be idle while the
  reviewer or monkey inspects changes. Reviewers and monkeys never edit.
- On interruption, inspect existing named agents and their output before
  starting or prompting another agent. Preserve the same agents for follow-up
  work where possible.

## 2. Workflow context and handoffs

Give each agent the current workflow identifier, coordinator name, known peer
names, phase, and this role map, adapting only the details needed for its task.
The extension injects `ORG_CONTEXT.md` before each active role skill; keep the
dynamic roster and phase in the task handoff.

- Planner: produce the plan; implementation starts only after the developer
  approves it.
- Coder: implement the approved plan, run checks, resolve internal findings,
  optionally receive monkey findings, and prepare the draft PR.
- Reviewer: internal, read-only code review. When the coder uses
  `my_agent_review`, the extension manages this agent and returns its findings
  to the coder.
- Monkey: optional, read-only adversarial probing after implementation and
  internal review. Send actionable findings to the coder; do not fix them.
- Developer: approves the plan before coding and the draft PR before the PR
  train.
- External PR reviewer: reviews after the PR enters the train. Route requested
  changes to the coder; do not treat internal review as external approval.

Every agent's handoff must include status, artifact or diff scope, checks and
results, unresolved findings, and blockers. Keep the planner agent available
through implementation. The coder sends its implementation handoff directly
to the planner and the workflow coordinator; monkey findings go directly to
the idle coder. If a recipient is busy or blocked, return the handoff to the
caller for relay. Use `my_agent_communicate` for direct role-to-role messages
when available. The recipient must acknowledge the handoff. Do not infer completion from an
idle status alone.

## 3. Plan and approval gate

1. Start `my-planner` and provide the idea or ticket, user context, current
   branch/worktree, and the workflow role map.
2. Require a repo-verified plan section in this worktree's field note (path from
   `git fieldnote`), headed `## <TICKET-KEY> <short description>`, with scope,
   constraints, acceptance criteria, exact verification commands, and open
   decisions. The plan lives outside the repo; it is never staged, committed,
   or included in a PR.
3. Get the planner's handoff. Present the field-note path and plan heading, a
   concise summary, and unresolved decisions to the developer.
4. If the planner finds unresolved decisions, have it send concise questions
   to the workflow coordinator; the coordinator batches them for the developer
   and relays the answers. Stop until the developer explicitly approves the
   plan and answers required decisions. Do not start the coder before approval.
   If the plan changes, return it to the planner and repeat this gate.

## 4. Implementation and internal review

1. After plan approval, start `my-coder` in the same worktree. Provide the
   approved plan heading and field-note path, approval, role map, and the
   planner's unique Herdr agent name. Activate it with `/agent coder`. Keep the
   planner available for the coder's direct completion handoff. Instruct the
   coder to implement and complete internal review, then stop before creating
   the draft PR. This workflow invocation authorizes a draft PR after later
   gates pass; it does not authorize a merge.
2. Let `my-coder` follow `../my-coder/SKILL.md`: preflight, small verified
   increments, required checks, commits and pushes, managed reviewer rounds,
   and per-acceptance-criterion evidence. Do not duplicate or bypass its review
   loop.
3. The coder's managed reviewer is a separate read-only agent activated with
   `/agent reviewer`; `my_agent_review` owns its startup, follow-up, and
   recovery. The reviewer returns findings to the coder. Do not start a second
   reviewer for the same internal review round.
4. Wait for the coder's implementation handoff before deciding whether to run
   the optional monkey stage. The coder must not create the draft PR until the
   monkey stage is complete or explicitly skipped.

## 5. Optional monkey stage

Run `my-monkey` when the developer requests it or when the coder or reviewer
identifies concrete edge-case risk that merits an adversarial pass. Otherwise
skip it and record why.

- Start the monkey only after the coder has finished editing and internal
  review is complete. Give it the approved plan, exact diff scope, checks,
  constraints, and the coder's handoff.
- Require read-only investigation and evidence for reproduced bugs. No edits,
  test changes, or speculative findings.
- Send actionable findings to the coder and wait for its fix-and-check handoff
  before further probing. Keep the reviewer loop with the coder.
- Once findings are resolved, or the monkey reports no credible issue, prompt
  the same coder to create the draft PR. If the monkey was skipped, do this
  only after recording the skip reason.

## 6. Draft PR and developer approval gate

1. The coder prepares the draft PR according to `../my-coder/SKILL.md`, links
   it in the handoff, and reports checks, internal review confirmation, monkey
   result or skip reason, and any unverified criteria.
2. Present the draft PR and wait for the developer's explicit approval before
   it enters the PR train.
3. If the developer requests changes, send the feedback and PR context to the
   same coder. Require fixes, relevant checks, and an updated draft PR, then
   repeat this gate. Do not mark the PR ready or publish it.

## 7. PR train and external review

- After developer approval, use the repository's documented process to add
  the PR to its train. If that process is unclear or needs a separate user
  action, ask the developer and wait. Confirm that external review has been
  requested. Do not assume internal review or developer approval substitutes
  for that review.
- If external feedback requests changes, route it to the coder. Follow the
  coder's review-response gate: propose changes first where required, wait for
  developer direction, then implement approved fixes, run checks, and update
  the PR. Repeat external review as needed.
- After external approval, report that the PR is ready to merge. The developer
  merges it; this skill never merges automatically.

## 8. Final report

Report, in order:

- Plan path and developer approval.
- Draft PR link and current train/external-review status.
- Implementation summary, commits, and check results.
- Internal reviewer confirmation and monkey result or skip reason.
- Remaining unverified criteria, findings, and blockers.
- Whether the PR is ready for the developer to merge.
