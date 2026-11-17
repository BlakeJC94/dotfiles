# my-agent

Local, Herdr-managed role selection and reviewer handoff for Pi.

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

## Use

- `/agent planner`
- `/agent coder`
- `/agent reviewer`
- `/agent monkey`

Role arguments may also use their full `my-*` skill names. Skill names and config keys retain the `my-` prefix.

Role state follows the active session branch. The selected skill body is reloaded from `~/.agents/skills/<skill-name>/SKILL.md` and added as the `my-agent-role` system-prompt section, after the shared `my-agent-org` context loaded from `~/.agents/skills/my-workflow/ORG_CONTEXT.md`. Relative references remain anchored to the role skill's directory. Every active role gets `my_agent_communicate` to list and message available agents in the same Herdr workspace; messages are accepted only for idle or done agents.

When `my-coder` is active, `my_agent_review` starts or resumes a separate Herdr Pi reviewer, activates it with `/agent reviewer`, and returns its output. Use `action=start` for the first round, `action=follow_up` after fixes, and `action=resume` after interruption. A pending review prompt is never resent automatically; rounds are limited to three.
