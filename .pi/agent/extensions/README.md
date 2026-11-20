# Pi Extensions

This directory contains my local [Pi](https://pi.dev) extensions. Pi auto-discovers extensions here from `~/.pi/agent/extensions/` — either as directories with an `index.ts`, standalone `.ts` files with a default export, or `pi` packages with a `package.json` `pi.extensions` field.

Extensions are hot-reloadable in a running Pi session with `/reload`.

## Extensions

| Extension | Type | What it does |
|-----------|------|--------------|
| [`assistant`](./assistant/) | directory | Field-notes assistant mode: date/time stamping, check-ins, and scheduled-task setup. |
| [`btw`](./btw.ts) | file | Private `/btw` asides to the model, carried forward in memory but not saved to session history. |
| [`commands`](./commands/) | directory | `/commands` slash command that lists every registered command grouped by source. |
| [`contextual-agents`](./contextual-agents/) | directory | Auto-injects path-scoped `AGENTS.md` / `CLAUDE.md` files into the system prompt when files are read or edited. |
| [`copy-code-block`](./copy-code-block.ts) | file | `Ctrl+S` copies the last fenced code block in the last agent message to the clipboard. |
| [`herdr-agent-state`](./herdr-agent-state/) | directory | Reports Pi's lifecycle state (`idle` / `working` / `blocked`) to a parent [Herdr](https://github.com/earendil-works/herdr) terminal multiplexer. |
| [`hidden-thinking-label`](./hidden-thinking-label/) | directory | `/thinking-label` command to customize the collapsed reasoning/thinking label in the TUI. |
| [`lists-md`](./lists-md.ts) | file | Custom input editor for Markdown lists: `Shift+Enter` continues bullets, numbers, and checkboxes; `C-.` / `C-,` indent/outdent. |
| [`mono-skills`](./mono-skills/) | directory | Discovers `.agents/skills` directories inside a monorepo, prefixes their skill names, and caches them per scope. |
| [`my-agent`](./my-agent/) | directory | Herdr-managed role selection and reviewer handoff (`/agent planner|coder|reviewer|monkey`). |
| [`nextbit`](./nextbit/) | directory | Registers the [Nextbit](https://api.nextbit256.com/v1) API as a custom model provider. |
| [`pi-file-snapshots`](./pi-file-snapshots/) | pi package | Git-free file checkpoints: snapshots every `write`/`edit` and lets you restore the working tree with `/snapshots`. |
| [`planning-questionnaire`](./planning-questionnaire/) | pi package | Interactive batch clarifying questionnaire tool plus a read-only `/clarify` planning command. |
| [`prompt-injection-guard`](./prompt-injection-guard/) | directory | Scans tool inputs and outputs for prompt-injection patterns and blocks or sanitizes them. |
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
| `/assistant [on\|off\|checkin\|schedule]` | assistant | Toggle field-notes assistant mode, run a check-in, or set up schedules. |
| `/btw [text]` | btw | Private aside to the model. Use `--clear`, `--history`, `--close`, or `--add`. |
| `/commands [extension\|prompt\|skill]` | commands | List all registered slash commands, optionally filtered by source. |
| `/clarify` | planning-questionnaire | Start a read-only planning phase with batched clarifying questions. |
| `/injection-guard ...` | prompt-injection-guard | Show settings, set mode, or test a string. |
| `/snapshots` | pi-file-snapshots | List file checkpoints and restore the working tree to one. |
| `/thinking-label [text]` | hidden-thinking-label | Set or reset the collapsed thinking label. |
| `/websearch <query>` | web-search | Quick DuckDuckGo search. |

## Keybindings added

| Key | Extension | Description |
|-----|-----------|-------------|
| `Ctrl+S` | copy-code-block | Copy the last fenced code block in the last agent message (contents only, no fences). |

## Tools added

| Tool | Extension | Description |
|------|-----------|-------------|
| `my_agent_communicate` | my-agent | List and message available agents in the same Herdr workspace. |
| `my_agent_review` | my-agent | Start, follow up, or resume a separate Herdr Pi reviewer. |
| `planning_questionnaire` | planning-questionnaire | Interactive batched clarifying questions widget. |
| `web_search` / `web_fetch` / `web_research` | web-search | Search, fetch, and research the web via DuckDuckGo. |

## Configuration files

- `~/.pi/agent/my-agent.json` — model/thinking-level settings for each `my-agent` role. See [`my-agent/README.md`](./my-agent/README.md).
- `~/.pi/agent/extensions/assistant/config.toml` — field-notes directory, timezone, schedule, and Slack allowlist for the assistant.
- `~/.pi/agent/auth.json` — provider API keys, including Nextbit (`/login nextbit`).

## Development

Extensions with tests use Node's built-in test runner:

```bash
cd pi-file-snapshots && npm install && npm test && npm run typecheck
cd ../planning-questionnaire && npm install && npm test
cd ../my-agent && npm test
```

Standalone file extensions (`btw.ts`, `lists-md.ts`) and directory extensions without a `package.json` rely on Pi's built-in TypeScript loader and have no separate build step.

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
- `assistant` activates fully when launched with `PI_ASSISTANT_MODE=1`; otherwise it stays inactive unless `/assistant on` is used in a session.
- `prompt-injection-guard` is intentionally paranoid and may suppress content that looks like instruction overrides; use `/injection-guard mode warn` to allow-through with a flag, or `audit` to log only.
