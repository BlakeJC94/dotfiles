# Commands Extension

Lists all available slash commands in the current session via the `pi.getCommands()` API.

## Files

- `commands.ts` — Extension source

## What it does

Registers a `/commands` slash command that queries every registered command — from extensions, prompts, and skills — and displays them grouped by source in an interactive selector.

## Commands

| Command | Args | Description |
|---------|------|-------------|
| `/commands` | _(none)_ | Shows all available slash commands grouped by source (extensions, prompts, skills). |
| `/commands extension` | source name | Filters display to only commands from the given source. Valid filters: `extension`, `prompt`, `skill`. |

## How it works

1. **Argument completions** — typing `/commands ` triggers autocomplete suggestions: `extension`, `prompt`, `skill`.
2. **Source filtering** — if a source argument is provided, the list is filtered to only commands whose `cmd.source` matches. Uses `"extension" | "prompt" | "skill"`.
3. **Grouped display** — commands are shown via `ctx.ui.select()` grouped under headers like `--- Extensions ---`, `--- Prompts ---`, `--- Skills ---`.
4. **Source path inspection** — when a user selects a specific command (not a group header), a confirmation prompt offers to show the file path the command was loaded from (`cmd.sourceInfo.path`).

## API Surface Used

- `pi.getCommands()` — returns an array of `SlashCommandInfo` objects, each with `name`, `description`, `source` (`"extension" | "prompt" | "skill"`), and `sourceInfo` (including `path`).
- `pi.registerCommand()` — registers the `/commands` command itself.
- `ctx.ui.select()` — shows the interactive picker.
- `ctx.ui.confirm()` — asks whether to show the source path.
- `ctx.ui.notify()` — displays the path.

## Dependencies

- `@earendil-works/pi-coding-agent` (types: `ExtensionAPI`, `SlashCommandInfo`)