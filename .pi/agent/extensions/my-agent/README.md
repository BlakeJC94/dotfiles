# my-agent

Local, Herdr-managed role selection, agent summoning and reviewer handoff for Pi.

## Install

Load this directory from `~/.pi/agent/extensions/` or run Pi with:

~~~sh
pi --extension ./my-agent/index.ts
~~~

The extension registers no commands or tools unless `HERDR_ENV=1`, `HERDR_SOCKET_PATH`, and `HERDR_PANE_ID` are present. It checks Herdr server readiness on session start.

## Configure models

Create `~/.pi/agent/my-agent.json` with explicit model settings for each role you intend to activate:

~~~json
{
  "my-planner": { "provider": "<provider>", "model": "<exact-model-id>", "thinkingLevel": "high" },
  "my-coder": { "provider": "<provider>", "model": "<exact-model-id>", "thinkingLevel": "medium" },
  "my-reviewer": { "provider": "<provider>", "model": "<exact-model-id>", "thinkingLevel": "high" },
  "my-monkey": { "provider": "<provider>", "model": "<exact-model-id>", "thinkingLevel": "high" }
}
~~~

There are no default models. The selected model must be available and authenticated before a role is activated.

The config file is optional: if it is absent, a role still activates its skill on the current model and thinking level instead of failing, and a review runs on the active model. A config file that is present but invalid, missing the requested role, or unauthenticated still stops activation.

## Use

- `/agent planner`
- `/agent coder`
- `/agent reviewer`
- `/agent monkey`

Role arguments may also use their full `my-*` skill names. Skill names and config keys retain the `my-` prefix.

## Summon a fresh agent

~~~text
/agent summon-tab <role> [message]
/agent summon-workspace <role> [--dir PATH] [message]
/agent summon-pane [-v] <role> [message]
~~~

- `summon-tab` creates a tab in the caller's workspace.
- `summon-workspace` creates a workspace. `--dir` defaults to the caller's current directory, not Pi's install directory. Relative paths, `~` and quoted paths with spaces are supported.
- `summon-pane` splits the caller's pane to the right; `-v` splits below it.
- All variants preserve the caller's focus and Pi profile. They never create Git branches or worktrees.
- Each child starts a fresh session, activates the requested role/model, then receives only the supplied or default message. Parent conversation history and approvals are not copied.
- Trailing message text overrides `defaultMessage` in that role's `my-agent.json` settings. Put `--` before a message beginning with an option.
- A missing config file uses the caller's active model/thinking level and the built-in role message. An invalid config or unavailable model fails before creating a location.
- Startup or delivery errors identify the child when available. Inspect it before repeating a summon; the command never resends a task, answers approvals or closes a possibly running child.

~~~text
/agent summon-tab coder Read PLAN.md and implement the approved work; do not commit or push.
/agent summon-workspace reviewer --dir "~/Workspace/my repo" Review the current changes read-only.
/agent summon-pane monkey
/agent summon-pane -v planner Plan the next change without implementing it.
~~~

Add an optional `defaultMessage` to each role in `~/.pi/agent/my-agent.json`:

~~~json
{
  "my-coder": {
    "provider": "<provider>",
    "model": "<exact-model-id>",
    "thinkingLevel": "high",
    "defaultMessage": "Read the approved plan and implement it, respecting every unresolved gate. Do not commit or push."
  }
}
~~~

Keep the other role entries when editing the file. Built-in messages ask the planner to plan without implementing, the coder to implement an identifiable approved plan without bypassing gates or publishing, the reviewer to review read-only, and the monkey to probe read-only. A fresh agent cannot infer an unstated task; include task details in the message or make them available in its directory.

## Summon from an agent

Planner and coder roles also get the model-callable `my_agent_summon` tool. Reviewer, monkey and sessions with no active role do not. Existing sessions need `/reload` to load it; the active role is restored automatically.

~~~json
{
  "layout": "tab",
  "role": "reviewer",
  "message": "Review the approved changes read-only. Do not edit files or publish anything."
}
~~~

- `layout`: `tab`, `workspace` or `pane`.
- `role`: `planner`, `coder`, `reviewer` or `monkey`.
- `directory`: optional, workspace-only; defaults to caller cwd.
- `direction`: optional, pane-only; `right` by default or `down` for the `-v` layout.
- `message`: optional; uses the same configured and built-in defaults as the slash commands.
- The tool and commands share model/auth checks, startup safeguards and a single in-progress guard. Cancellation stops further launch steps; an already-created child is left available for inspection.
- Tool availability does not grant delegation or approval authority. The developer or active workflow must authorize delegation and layout. Children do not inherit parent approvals.
- Coders still use `my_agent_review` for the managed review loop.

Run `/reload` in an existing Pi session to load command or tool changes. Already-running children keep their loaded extension until reloaded.

Role state follows the active session branch. The selected skill body is reloaded from `~/.agents/skills/<skill-name>/SKILL.md` and added as the `my-agent-role` system-prompt section, after the shared `my-agent-org` context loaded from `~/.agents/skills/my-workflow/ORG_CONTEXT.md`. Relative references remain anchored to the role skill's directory. Every active role gets `my_agent_communicate` to list and message available agents in the same Herdr workspace; messages are accepted only for idle or done agents.

## Reviewer handoff

When `my-coder` is active, `my_agent_review` starts or resumes a separate Herdr Pi reviewer, activates it with `/agent reviewer`, and returns its output. Use `action=start` for the first round, `action=follow_up` after fixes, and `action=resume` after interruption. A pending review prompt is never resent automatically; rounds are limited to three.

The spawned reviewer pane carries `MY_AGENT_WORKER_ROLE=my-reviewer`. A worker with that marker keeps reporting `working` at the managed integration's source with a saturated `seq`, so the integration's later `idle` report is ignored and Herdr never marks the reviewer done. That suppresses the finish notification (popup and sound) for the reviewer while leaving normal agents alone. `my_agent_review` therefore detects completion from the reviewer's completion marker in the pane output instead of the agent lifecycle state.
