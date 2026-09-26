# Hidden Thinking Label Extension

Customizes the label shown in the TUI when a thinking/reasoning block is collapsed (hidden via Ctrl+T).

## Files

- `hidden-thinking-label.ts` — Extension source

## What it does

By default, when a model's thinking/reasoning content is hidden, pi displays a generic label like `[Reasoning] (Ctrl+T to expand)`. This extension lets you change that label to something more informative or domain-specific, and provides a `/thinking-label` command to change it at runtime.

## Commands

| Command | Args | Description |
|---------|------|-------------|
| `/thinking-label` | _(none)_ | Resets the hidden thinking label to the default. |
| `/thinking-label <text>` | Custom label text | Sets the hidden thinking label to the provided text. |

## How it works

1. On `session_start`, the extension calls `ctx.ui.setHiddenThinkingLabel()` with the current label value (default or custom).
2. The `/thinking-label` command:
   - **Without arguments** — resets the internal label to `[Reasoning] (Ctrl+T to expand)` and calls `setHiddenThinkingLabel()` with no argument (restoring default).
   - **With arguments** — sets the internal label to the provided text and calls `setHiddenThinkingLabel(label)`.

## API Surface Used

- `ctx.ui.setHiddenThinkingLabel(label?: string)` — sets the collapsed thinking label. Called without arguments to reset to the default.
- `pi.on("session_start", ...)` — re-applies the label when a new session starts.
- `pi.registerCommand()` — registers the `/thinking-label` command.

## Default Label

```
[Reasoning] (Ctrl+T to expand)
```

## Use Cases

- Shortening the label to save screen space.
- Making it context-specific (e.g., `[Deep Reasoning]`, `[Chain-of-Thought]`).
- Branding or theming the agent.