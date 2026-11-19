---
name: "herdr-pi-role-handoff"
description: "Start a Pi role agent in a new Herdr tab and hand it an approved task. Handles agent_pane_busy despite a ready shell, slash-command agent_prompt_stalled, and communication timeouts without duplicate prompts."
version: 1
created: "2026-11-19"
updated: "2026-11-19"
---
## When to Use
Use only when the user explicitly requests a Herdr agent/tab or delegates startup. Use the installed Herdr skill and CLI help as authority.

## Procedure
1. Verify HERDR_ENV=1 and Herdr readiness. Read the applicable role skill and configured role model. Confirm branch, cwd, approval and deliverable boundaries.
2. Create the requested tab with the current workspace and cwd. Use returned tab/pane IDs. Give parent and child unique workflow-specific agent names.
3. Prefer herdr agent start NAME --kind pi --pane ID. If agent_pane_busy occurs, inspect pane output and herdr pane process-info before considering any retry.
4. If process-info confirms that the only foreground process is the shell and the prompt is ready, an ordinary herdr pane run ID pi can launch Pi when agent start incorrectly rejects that shell. Never do this if another program is foreground.
5. Wait for Pi idle and rename its agent. Activate the role with a separate /agent ROLE prompt. If agent_prompt_stalled occurs, inspect output for the activation confirmation; do not resend automatically.
6. Use my_agent_communicate to send the task to the confirmed-idle, named workflow child. Include approval, plan path, role roster, branch/cwd, scope, checks, forbidden mutations, and required handoff.
7. If communication times out, inspect child status and output. A visible task and acknowledgement establish delivery even if the tool timed out waiting for the whole task. Do not resend or interrupt working agents.

## Pitfalls
- Observed with Herdr 0.9.0: agent start can report agent_pane_busy while process-info shows only an idle zsh shell.
- A synchronous /agent command may complete without the working-state transition expected by herdr agent prompt --wait.
- my_agent_communicate can time out after 120 seconds while the recipient continues legitimate work; timeout alone does not mean delivery failed.
- A coder skill can authorize normal commits/pushes by default. Explicit working-tree-only instructions must override that when the developer has not authorized Git deliverables.

## Verification
1. Confirm the child shows the intended activated role/model.
2. Confirm the task appears in the child's output and it explicitly acknowledges the task and boundaries.
3. Report the new tab/name and actual working status, not inferred implementation completion.