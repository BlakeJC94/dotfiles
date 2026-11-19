---
name: pi-extend
description: Edit, create, or maintain Pi extensions under ~/.pi/agent/extensions. Use when the user changes an extension, adds a command/tool/provider/event, fixes a bug, or asks to keep the extensions README in sync. Commits via the git dotfiles alias.
---

# pi-extend: maintain local Pi extensions

This skill guides changes to the local Pi extensions in `~/.pi/agent/extensions/`. It keeps the top-level README accurate and commits everything through the `git dotfiles` alias that manages this dotfiles repo.

## When to use

- Creating a new extension under `~/.pi/agent/extensions/`.
- Modifying an existing extension's commands, tools, providers, event handlers, or system-prompt sections.
- Renaming, removing, or reworking any user-facing surface of an extension.
- Fixing bugs in extension code or tests.
- The user asks to "update the extensions README", "commit the extension changes", or mentions `pi-extend`.

## Extension forms

Choose the simplest form that fits:

| Form | Location | Use for |
|------|----------|---------|
| Directory extension | `~/.pi/agent/extensions/<name>/index.ts` | Multi-file extensions with helpers, tests, or assets. |
| Standalone file extension | `~/.pi/agent/extensions/<name>.ts` | Small input/editor extensions or single-purpose hooks. |
| Pi package | `~/.pi/agent/extensions/<name>/package.json` with `pi.extensions` | Extensions with npm scripts, tests, or published/distributed intent. |

All forms should export a default function accepting Pi's `ExtensionAPI`.

## Workflow

1. **Identify the target extension** in `~/.pi/agent/extensions/`. Read its source and per-extension `README.md` (if any).
2. **Make the minimal change.** Use `registerCommand`, `registerTool`, `registerProvider`, `pi.on(...)`, or system-prompt sections as appropriate. Prefer Node built-ins and Pi's host APIs; avoid new npm dependencies unless approved.
3. **Run tests / typecheck** if the extension is a pi package with scripts:
   ```bash
   cd ~/.pi/agent/extensions/<name>
   npm install
   npm test
   npm run typecheck
   ```
4. **Update the top-level README** at `~/.pi/agent/extensions/README.md` whenever the public surface changes:
   - Add/remove rows in the **Extensions** table.
   - Add/remove rows in the **Commands** table.
   - Add/remove rows in the **Tools** table.
   - Update **Configuration files**, **Development**, **Adding a new extension**, or **Notes** sections as needed.
   - Keep descriptions concise and consistent with existing rows.
5. **Update the per-extension README** if the extension has one and its behavior, commands, tools, configuration, or usage changed.
6. **Review the diff** with `git dotfiles diff` or `git dotfiles diff --cached`. Ensure no secrets or generated artifacts are staged.
7. **Stage changes** with `git dotfiles add <paths>`.
8. **Commit** with a Conventional Commit message scoped to `pi-ext`, for example:
   - `feat(pi-ext): add /foo command to web-search`
   - `fix(pi-ext): guard against empty query in commands`
   - `docs(pi-ext): update README with new assistant schedules`
9. **Push** if the user asks: `git dotfiles push`.

## What not to commit

- `~/.pi/agent/auth.json` (secrets)
- `~/.pi/agent/my-agent.json` (runtime config with credentials)
- `~/.pi/agent/sessions/`
- `~/.pi/agent/file-snapshots/`
- `node_modules/`, `dist/`, `.tsbuildinfo`

If unsure, check `~/.pi/agent/extensions/<name>/.gitignore` or the global dotfiles `.gitignore`.

## Verification

- [ ] The top-level `~/.pi/agent/extensions/README.md` accurately reflects every command, tool, provider, and configuration change.
- [ ] `git dotfiles status --short` shows only the intended files.
- [ ] `npm test` / `npm run typecheck` pass for any pi package that was modified.
- [ ] The modified extension loads without errors after `/reload` or on a fresh Pi start.
