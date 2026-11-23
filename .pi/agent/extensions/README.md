# Pi Extensions

This directory contains my local [Pi](https://pi.dev) extensions. Pi auto-discovers extensions here from `~/.pi/agent/extensions/` — either as directories with an `index.ts`, standalone `.ts` files with a default export, or `pi` packages with a `package.json` `pi.extensions` field.

Extensions are hot-reloadable in a running Pi session with `/reload`.

## Extensions

| Extension | Type | What it does |
|-----------|------|--------------|
| [`btw`](./btw.ts) | file | Private `/btw` asides to the model, with `/btw-add`, `/btw-clear`, `/btw-history`, and `/btw-close` management commands. |
| [`commands`](./commands/) | directory | `/commands` slash command that lists every registered command grouped by source. |
| [`contextual-agents`](./contextual-agents/) | directory | Auto-injects path-scoped `AGENTS.md` / `CLAUDE.md` files into the system prompt when files are read or edited. |
| [`copy-code-block`](./copy-code-block.ts) | file | `Alt+X` opens a filterable picker of code blocks from recent agent messages, with a live preview, and copies the selected one. |
| [`custom-editor`](./custom-editor/) | directory | Custom input editor: mnemonic and full-name prompt snippets, Markdown-list editing, and prompt history. |
| [`herdr-agent-state`](./herdr-agent-state/) | directory | Reports Pi's lifecycle state (`idle` / `working` / `blocked`) to a parent [Herdr](https://github.com/earendil-works/herdr) terminal multiplexer. |
| [`hidden-thinking-label`](./hidden-thinking-label/) | directory | `/thinking-label` command to customize the collapsed reasoning/thinking label in the TUI. |
| [`mono-skills`](./mono-skills/) | directory | Discovers `.agents/skills` directories inside a monorepo, prefixes their skill names, and caches them per scope. |
| [`my-agent`](./my-agent/) | directory | Herdr-managed role selection, fresh-agent tab/workspace/pane summoning, and reviewer handoff. |
| [`nextbit`](./nextbit/) | directory | Registers the [Nextbit](https://api.nextbit256.com/v1) API as a custom model provider. |
| [`nvim-editor-improved`](./nvim-editor-improved/) | directory | Context-aware nvim prompt editor: read-only conversation snapshot above the editable prompt, submit with `:wqa`. |
| [`pi-file-snapshots`](./pi-file-snapshots/) | pi package | Git-free file checkpoints: snapshots every `write`/`edit` and lets you restore the working tree with `/snapshots`. |
| [`planning-questionnaire`](./planning-questionnaire/) | pi package | Interactive batch clarifying questionnaire tool plus a read-only `/clarify` planning command. |
| [`prompt-injection-guard`](./prompt-injection-guard/) | directory | Scans tool inputs and outputs for prompt-injection patterns and blocks or sanitizes them. |
| [`skill-reload`](./skill-reload/) | directory | After a compaction, nudges the model to reload skills whose instructions were summarized away. |
| [`tips`](./tips/) | directory | Shows configurable Pi usage tips at session start and every three completed turns. |
| [`web-search`](./web-search/) | directory | Web search/fetch/research tools (`web_search`, `web_fetch`, `web_research`) and a `/websearch` command. |

## Loading an extension manually

```bash
# Load a directory extension
pi --extension ./my-agent/index.ts

# Load a standalone file extension
pi --extension ./btw.ts
```

## Commands added

| Command | Extension | Description |
|---------|-----------|-------------|
| `/agent [planner\|coder\|reviewer\|monkey]` | my-agent | Activate a Herdr-managed role. |
| `/agent summon-tab <role> [message]` | my-agent | Start a fresh role agent in another tab in this workspace. |
| `/agent summon-workspace <role> [--dir PATH] [message]` | my-agent | Start a fresh role agent in another workspace; directory defaults to the caller's. |
| `/agent summon-pane [-v] <role> [message]` | my-agent | Start a fresh role agent to the right, or below with `-v`; preserve caller focus. |
| `/btw <text>` | btw | Private aside to the model. |
| `/btw-add` | btw | Add the private conversation to session history and clear it. |
| `/btw-clear` | btw | Clear the private conversation. |
| `/btw-history` | btw | Show the number of prior private turns. |
| `/btw-close` | btw | Close the private conversation widget. |
| `/commands [extension\|prompt\|skill]` | commands | List all registered slash commands, optionally filtered by source. |
| `/clarify` | planning-questionnaire | Start a read-only planning phase with batched clarifying questions. |
| `/injection-guard ...` | prompt-injection-guard | Show settings, set mode, or test a string. |
| `/snapshots` | pi-file-snapshots | List file checkpoints and restore the working tree to one. |
| `/thinking-label [text]` | hidden-thinking-label | Set or reset the collapsed thinking label. |
| `/vim` | nvim-editor-improved | Edit the prompt in nvim with a read-only conversation snapshot above it. |
| `/websearch <query>` | web-search | Quick DuckDuckGo search. |

## Keybindings added

| Key | Extension | Description |
|-----|-----------|-------------|
| `Alt+X` | copy-code-block | Pick a code block from recent agent messages (filterable, with preview) and copy its contents (no fences). |
| `Shift+Enter` | custom-editor | Continue the current Markdown list item (bullet, numbered, or checkbox); on an empty item, end the list. |
| `Ctrl+.` / `Ctrl+,` | custom-editor | Indent / outdent the current list line by 4 spaces (requires enhanced key events). |
| `Up` / `Down` | custom-editor | With an empty input (or the cursor at the start), cycle prompts from recent sessions. |
| `Ctrl+Shift+End` | custom-editor | Move the cursor to the end of the current input. |
| `Alt+G` | nvim-editor-improved | Edit the prompt in nvim with a read-only conversation snapshot above it. |

## Prompt snippets

| Token | Extension | Description |
|-------|-----------|-------------|
| `:r` / `:review`, `:d` / `:debug`, `:t` / `:test`, `:e` / `:explain`, `:p` / `:plan`, `:v` / `:verify` | custom-editor | Type the token followed by a space to expand an editable prompt. |

## Tools added

| Tool | Extension | Description |
|------|-----------|-------------|
| `my_agent_communicate` | my-agent | List and message available agents in the same Herdr workspace. |
| `my_agent_summon` | my-agent | Planner/coder tool to summon an authorized fresh role agent in a tab, workspace or pane. |
| `my_agent_review` | my-agent | Start, follow up, or resume a separate Herdr Pi reviewer. |
| `planning_questionnaire` | planning-questionnaire | Interactive batched clarifying questions widget. |
| `web_search` / `web_fetch` / `web_research` | web-search | Search, fetch, and research the web via DuckDuckGo. |

## Configuration files

- `~/.pi/agent/my-agent.json` - model/thinking-level settings and optional `defaultMessage` for each `my-agent` role. See [`my-agent/README.md`](./my-agent/README.md).
- `~/.pi/agent/auth.json` — provider API keys, including Nextbit (`/login nextbit`).

## Tips

The `tips` extension shows one tip at session start and every three completed turns, then cycles through the list. Edit the single `pi-tips` block below and run `/reload` to apply changes.

```pi-tips
Use /tree to explore another approach without losing the current conversation branch.
Use /fork to branch from an earlier user message; use /clone to branch from the current point.
In /tree, select an earlier user message to edit and resubmit it as a new branch.
Give /compact instructions when the summary must preserve specific decisions or constraints.
Use /tree's no-tools filter to navigate long sessions by prompts and responses instead of tool output.
Use /commands extension to browse installed extension commands and inspect their source paths.
Use /clarify to batch planning questions; its planning phase stays read-only.
Use /snapshots to restore files changed by Pi's /write/ and /edit/ tools; bash edits are not captured.
Type :r, :d, :t, :e, :p, or :v followed by a space to expand a review, debug, test, explain, plan, or verify prompt.
Press /Alt+G/ or run /vim to edit a prompt in nvim with recent conversation context visible.
Press /Alt+X/ to search recent assistant code blocks and copy one without fences.
Use /btw for a side question; run /btw-add to bring the aside into the main session.
Use /websearch <query> for quick web lookup; /web_research/ can search and fetch several pages.
In Herdr, /agent summon-pane reviewer ... starts a fresh reviewer with only the message you provide.
In Markdown lists, /Shift+Enter/ continues the item; /Ctrl+./ and /Ctrl+,/ indent and outdent it.
In a monorepo, run /refreshskills after changing nested .agents/skills; cached skills load in a new session.
Use /agents_dirs(path)/ to find nested AGENTS.md and .agents guidance that applies before editing a file.
In Git repos, contextual-agents automatically loads path-specific AGENTS.md or CLAUDE.md as files are read or edited.
With my-coder active, use /my_agent_review/ to start, follow up, or resume a separate reviewer.
Use /my_agent_communicate/ to find or message idle or done agents in your Herdr workspace.
Use /login nextbit, then /model, to authenticate and select a Nextbit model.
For prompt-injection-guard false positives, /injection-guard mode warn allows flagged content through; audit only logs it.
After compaction, reread any skill named by skill-reload if its instructions still apply; the extension does not reload it automatically.
With an empty prompt, /Up/ and /Down/ browse prompts from recent sessions via custom-editor.
Use /skill:my-planner for repo-verified Jira plans; use /skill:my-coder only to implement an approved plan section.
Use /skill:my-reviewer for read-only diff review, or /skill:my-monkey to probe edge cases without edits.
Use /skill:my-workflow for the gated planner-to-PR-review process.
For a Buildkite failure URL, use /skill:ci-results for structured root-cause data.
For Python setup, dependency, lint, or type work, use /skill:uv-python-workflow and the repo's uv workflow.
Use /skill:field-notes-assistant for check-ins or questions grounded in your notes and requested work context.
Use /skill:dotfiles for home-config changes or syncing; /skill:git-aliases can surface existing Git shortcuts.
Use /skill:session-transfer to move this Pi session to another Herdr machine or workspace.
Use /skill:find-skills when you want to discover an installable skill for a workflow.
Use /skill:split-stacked-prs for large PRs that need a docs-first base and reviewable stack.
Use /skill:my-reviewer-pr with a PR URL to prepare a report and pending review comments.
Use /skill:my-reviewer-response to triage unresolved review threads, make approved fixes, and draft author replies.
Use /skill:github-review-comments for concise Conventional Comments review feedback.
Use /skill:pr-description-style for scannable PR descriptions, especially ordered workflows.
```

## Development

Extensions with tests use Node's built-in test runner:

```bash
cd pi-file-snapshots && npm install && npm test && npm run typecheck
cd ../planning-questionnaire && npm install && npm test
cd ../my-agent && npm test
```

Standalone file extensions (`btw.ts`) and directory extensions without a `package.json` rely on Pi's built-in TypeScript loader and have no separate build step.

## Adding a new extension

When editing extensions, use the `pi-extend` skill (`/skill:pi-extend`) to keep this README and the per-extension READMEs in sync and to commit via `git dotfiles`.

1. Create a directory with `index.ts` (or a standalone `.ts` file) that exports a default function taking `ExtensionAPI`.
2. Register commands, tools, providers, event handlers, or prompt sections as needed.
3. Add a per-extension `README.md` if it has user-facing commands or configuration.
4. Update this README to include the new extension, its commands/tools, and any configuration.
5. Run `git dotfiles add .pi/agent/extensions/<name>` to track it.

See the [Pi extensions documentation](https://pi.dev/docs/extensions) and the example extensions bundled with Pi for patterns.

## Notes

- `herdr-agent-state` and `my-agent` only activate when `HERDR_ENV=1`, `HERDR_SOCKET_PATH`, and `HERDR_PANE_ID` are present.
- `prompt-injection-guard` is intentionally paranoid and may suppress content that looks like instruction overrides; use `/injection-guard mode warn` to allow-through with a flag, or `audit` to log only.
