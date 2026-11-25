# plugin-help

A local index of installed Pi extensions with concise, manually maintained TL;DR pages.

## Commands

| Command | Description |
|---------|-------------|
| `/plugin-help` | List extensions found in the user and current project extension directories, plus packages reported by `pi list --no-approve`. |
| `/plugin-help <name>` | Show the local TL;DR page for an installed extension. |

The list combines filesystem discovery with Pi's package list. Package listing uses `--no-approve` so the command never grants project trust; project-local extension files are still found by scanning `.pi/extensions/`.

## Maintaining pages

Edit [`pages.ts`](./pages.ts) to add or update TL;DR pages. Keys match the names shown by `/plugin-help`; every page should briefly explain the extension and give its main usage examples. Extensions without a page are marked in the list.
