# my-agent: persistent roles and automatic reviewer handoffs

Paths verified against the current tree on 2026-10-30.
`E` = `/Users/bcook/.pi/agent/extensions`; `S` = `/Users/bcook/.agents/skills`.
`P` = `/opt/homebrew/Cellar/pi-coding-agent/1.0.3/libexec/lib/node_modules/@earendil-works/pi-coding-agent`.
0 unanswered questions.
This directory is not a usable Git worktree. This session delivers this plan only.

## 1. Task and desired outcome

**Problem**

* Full skill instructions currently enter conversation context on demand.
* Compaction summarizes older conversation messages rather than retaining them verbatim.
* Reviewer routing still depends on the coder executing the summon instructions correctly.
* Roles need different models without repeatedly selecting them by hand.
* Existing skills remain the instruction source; duplicating them would create drift.

**Local extension and role persistence**

* R1: Add a local extension named `my-agent` under `E/my-agent/`.
* R2: Require Herdr. Outside Herdr, log why my-agent is inactive and register no workflow capabilities.
* R3: Provide `/my-agent <skill-name>` to select the active role explicitly.
  Support `my-planner`, `my-coder`, `my-reviewer`, and `my-monkey` in v1.
* R4: Load the selected skill body into a dedicated effective system-prompt section.
  Preserve the source filename and directory so relative references remain meaningful.
  Do not embed every skill or replace Pi's base prompt and project instructions.
* R5: Persist the selected role as session metadata and reconstruct it on resume/reload.
  Compaction must not remove the role instructions. Session-tree navigation must restore that branch's role.
* R6: Read role model settings from `getAgentDir()/my-agent.json`.
  Require an exact provider, model ID, and thinking level per activated role.
  Planner/reviewer can use powerful models and coder a simpler model; do not invent defaults.
  Missing, invalid, or unauthenticated settings must stop role activation, not select a fallback.
* R7: Show the active skill and configured model. Invalid commands leave the previous role intact.
  Role changes happen at an idle boundary, not halfway through an active tool batch.

**Workflow seams**

* R8: Planner -> coder remains manual. Finishing a plan never starts implementation.
* R9: Provide a coder-invoked review tool that owns Herdr spawn/prompt/wait/read for a separate Pi reviewer.
  Pass the goal, approved plan path, exact diff scope, decisions, constraints, and check results.
  Return the completed feedback as the tool result without requiring the developer to copy it.
  My-coder instructions require tool invocation at review boundaries; no lifecycle-driven review enforcement.
* R10: Reuse the same reviewer for follow-up rounds, with at most three rounds per review cycle.
  Coder evaluates findings, makes authorized fixes, reruns checks, and requests confirmation.
  Third-round fixes without another review remain explicitly unconfirmed.
* R11: Coder <-> monkey transitions remain manual. Never launch monkey or resume coder from monkey automatically.
  Preserve reviewer and monkey read-only/non-destructive instructions.
* R12: Commit each coherent, verified coder increment and normal-push it before the next increment.
  Work only on the developer's existing branch and worktree. Never force-push or include unrelated work.
  Pause on ambiguous push destinations, rejected pushes, or branch/worktree changes.
* R13: Open a PR only when the developer explicitly requests it. Every created PR is a draft.
  Finishing implementation, passing review, pushing, or a plan's Deliverable line is not a PR trigger.
* R14: Update existing skills where needed to express these policies without duplicating their bodies.
  Apply auto-push and explicit-only PR creation to standalone my-coder too.
  Managed sessions delegate reviewer transport to my-agent; standalone sessions retain summon support.

**Out of scope**

* Implementation in this planning session, installing packages, publishing a package, or moving skills.
* PR train management, external-review polling, automatic PR creation, readiness changes, and merging.
* Automatic planner approval, monkey execution, branch creation, or repository trust approval.
* Arbitrary third-party skill loading, model classifiers, cost-based routing, and model fallback chains.

## 2. Constraints and decisions

**Hard**

* Skills remain source of truth. Load their actual bodies, not compiled-in copies or abridged paraphrases.
* A selected skill is not a blanket authorization to implement an unapproved plan.
* Preserve API contracts, dependency approvals, and repository-specific restrictions.
* Preserve or strengthen tests. Never skip tests, relax assertions, narrow discovery, or weaken checks for green.
* Test meaningful behavior states/transitions with simple setup, action, and observable outcome.
* Explicit user approval authorizes the new standalone auto-push policy, replacing my-coder's current
  "push only when instructed" default. Do not silently override a target repository's conflicting policy.
* Preserve `[AGENT:Coder]` commit subjects and existing outward-facing attribution/privacy rules.
* No model call may run under a newly selected role if that role's configured model cannot be applied.
* Do not modify the Herdr-managed integration at `E/herdr-agent-state/index.ts`.
* No new dependencies without approval. Prefer Node and Pi's host-provided APIs.
* Do not infer reviewer success from idle state, missing output, timeout, or a failed wait.
* Do not automatically answer reviewer approval/question dialogs or resend an ambiguously delivered prompt.
* Never edit concurrently with a reviewer reading the shared worktree. Serialize the review/fix cycle.
* Log inactive startup once with a useful reason. Non-Herdr Pi use must otherwise remain unaffected.

**Preferences**

* Local extension, not a published Pi package. A normal `index.ts` directory is already discoverable.
* Explicit role selection, not natural-language role guessing or automatic planner-to-coder transitions.
* Use structured system-prompt sections rather than rewriting the complete system prompt.
* Keep only the selected role's body in the prompt; do not load all my-* skills permanently.
* Keep controls and status small. No custom dashboard, general workflow engine, or dependency framework.

**Agent may decide**

* Internal names, minimal config validation, and file boundaries within the new extension directory.
* Strip frontmatter while preserving the complete skill body and its source-directory context.
* Re-read skill files on activation and reload; preserve them unchanged through compaction.
* Implement behavior tests using the existing Node built-in test pattern if tests are added.

**Agreed decisions**

* Use a coder-invoked review tool for reviewer transport; my-coder owns the three-round fix loop.
* Invocation depends on the coder following its skill instructions, not lifecycle enforcement.

**Ask before**

* None.

## 3. Relevant context

**Files (line refs current)**

* `S/my-coder/SKILL.md:18-27,136-167` - current summon transport, same-reviewer loop, three-round bound.
* `S/my-coder/SKILL.md:35-39,110-129` - existing branch/worktree rule and verified incremental commits.
* `S/my-coder/SKILL.md:177-181,320-322` - current push/PR rules that need policy changes.
* `S/my-coder/SKILL.md:183-254` - preserve PR content, attribution, and private-plan vocabulary rules.
* `S/my-reviewer/SKILL.md:46-51` - read-only review contract and explicit "No further notes." response.
* `S/my-monkey/SKILL.md:10-15` - no file mutations, live requests, or expensive probes without approval.
* `S/summon/SKILL.md:11-17` - current Herdr transport, handoff context, output recovery, pane retention.
* `S/herdr/SKILL.md:9-17` - environment gate before any Herdr control command.
* `E/contextual-agents/index.ts:69-74` - existing extension also modifies the effective system prompt.
* `E/herdr-agent-state/index.ts:1-3,10-19,225-256` - managed integration, environment checks, settled reporting.
* `E/planning-questionnaire/package.json:14-18` - existing Node built-in TypeScript test command pattern.
* `P/docs/skills.md:39-53` - relative references, descriptions-only startup, full skill invocation as user input.
* `P/docs/compaction.md:45-79` - summarized history plus a separate system prompt in rebuilt context.
* `P/docs/extensions.md:46,59-67,103,222-235` - discovery, lifecycle, structured prompt mutation, durable metadata.
* `P/dist/core/system-prompt.d.ts:5-23` - `sections` and opaque `forceSystemPrompt` fields.
* `P/dist/core/extensions/types.d.ts:699-709,764-772,1235,1261` - prompt event, settlement, appendEntry, setModel.
* `P/examples/extensions/preset.ts` - existing role-like model/thinking/instruction configuration example.
* `P/docs/virtual-models.md:3-29` - virtual models route requests; unnecessary for fixed per-role selection.

**Preserve**

* Existing skills remain directly usable through `/skill:...`, including outside Herdr.
* Standalone my-coder retains its documented no-Herdr review fallback, clearly labeled as self-review.
* Plugin-managed review requires Herdr and never silently substitutes self-review.
* Developer owns transitions into implementation and monkey probing, and all PR creation requests.
* Shared-worktree review, same reviewer across rounds, substantive findings only, and explicit review status.

**Pitfalls**

* A skill description in the system prompt does not preserve its complete instructions.
  A dedicated role section does; compaction is not a reason to disable summarization.
* Persist role identity/config references separately from summarized chat; do not infer them from summaries.
  Restore branch-local state with `getBranch()`, not all session entries, including abandoned branches.
* Persist pending reviewer identity, diff scope, and round before waiting. On recovery, reconcile live state
  before spawning, sending, or resuming; cancellation of a wait does not cancel the reviewer.
* Reused reviewer feedback can become stale after new commits. Bind it to the reviewed scope/revision.
* `contextual-agents` returns a full prompt override. Check effective prompt composition so it cannot hide
  my-agent's structured section. Keep any necessary compatibility change narrow and documented.
* Herdr startup needs both the managed environment and usable caller/server context.
  Avoid spawning processes in the extension factory; perform CLI readiness checks from session startup.
* Skills' relative references must resolve from `S/<skill-name>/`, not the task repository or extension.
* Raw terminal output may be incomplete. Missing feedback blocks review completion; it is not a clean review.
* Automatic push needs a known destination and must not accidentally create/update a PR through a wrapper.

**Known unknowns**

* Exact model IDs and credentials are runtime configuration supplied by the developer, not plan defaults.
* There is no existing my-agent implementation or extension-wide test/build manifest in `E`.
* Implementation ownership/repository for this standalone extension must be established before commits.

## 4. Acceptance criteria

* AC1 (R1,R2): Load outside Herdr. One inactive reason is logged; no my-agent role/model/handoff behavior runs.
  Verify: inspect registrations and startup output with Herdr variables absent.
* AC2 (R3-R7): Select each supported skill. Its full body/source context and configured model become active.
  Invalid skill/config/auth leaves no partial new-role activation. Verify: effective prompt and selected model.
* AC3 (R4,R5): Compact, reload, resume, and navigate session branches after role selection.
  Correct role instructions remain effective without duplication. Verify: branch metadata and effective prompt.
* AC4 (R8,R11): Finish planning or review; no coder/monkey transition starts without the developer's command.
  Verify: role and Herdr agent activity before/after each boundary.
* AC5 (R9,R10): Review requests deliver completed feedback to coder; fixes return to the same reviewer.
  Three rounds stop with truthful status. Verify: review tool results and review lifecycle evidence.
* AC6 (R9,R10): Interrupt a wait, block reviewer, or lose output. No duplicate prompt/reviewer or false clean result.
  Verify: pending identity/scope, reconciled state, and visible blocked/unconfirmed result.
* AC7 (R12,R14): Plugin and standalone coder commit/push verified coherent increments only.
  Ambiguous destination, unrelated work, rejected push, or failing checks causes a pause without force-push.
  Verify: Git command sequence and skill instructions, using an isolated repository if exercised.
* AC8 (R13,R14): Completion/push never opens a PR. An explicit request can create only a draft.
  Verify: skill policies and PR command path; no live PR creation is required to review this plan.

**Commands**

* Discovery verified here: `pi --help`, `herdr --help`, `herdr agent`, and `herdr status`.
* Installed Herdr client/server: 0.9.0, compatible; `pi` is a supported agent kind.
* Explicit future load from `E`: `pi --extension ./my-agent/index.ts` once the proposed file exists.
* Manual Pi checks: `/my-agent my-planner`, `/compact`, `/reload`, `/resume`, `/tree` after implementation.
* No my-agent test/lint/build command exists yet. Do not claim neighboring package tests validate new code.
* Developer waived verification requirements for this plan ("dont worry about this, yolo").
  AC checks above describe observable evidence, not mandatory execution. Report checks not run explicitly.

**Done**

* Local extension expresses the agreed role, persistence, model, manual-gate, and reviewer-routing behavior.
* Existing skills express automatic commit/push and explicit-only draft PR policy, including standalone use.
* Required model configuration and any unresolved decision are visible; no silent fallback or invented approval.
* Evidence or an explicit unverified gap accompanies each requirement; verification waiver is not a pass result.

**Deliverable**: This `E/PLAN.md` only. No implementation, skill edits, commits, pushes, installs, or PR.

## 5. References

* Developer questionnaire, 2026-10-30 - local extension, persistent skill command, required model config (agreed).
* Developer questionnaire, 2026-10-30 - manual planner/monkey transitions, automatic reviews/commits/pushes (agreed).
* Developer questionnaire, 2026-10-30 - standalone policy updates and verification waiver (agreed).
* Pi 1.0.3 local documentation and examples - source paths cited in section 3 (installed, inspected).
* Herdr 0.9.0 CLI help/status and local Herdr/summon skills (installed, inspected).
