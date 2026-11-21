# nvim-editor-improved

Edit Pi's prompt in real nvim, with the conversation visible above the input.

Pi's built-in external editor (`Ctrl+G`) hands nvim only the current prompt, so
you lose all context while typing a reply. This extension opens nvim with a
read-only, condensed snapshot of the conversation in a split above the editable
prompt buffer. Pi is suspended while nvim runs, so your own `init.lua`, plugins,
keymaps, and options all apply — nvim owns the terminal, and there is no
embedded-terminal emulation involved.

## Usage

- `/vim` — open the context-aware editor.
- `Alt+G` — same thing.

The window layout is:

```
┌─ context.md (read-only, scrolled to newest) ─┐
│ ## 🧑 user                                   │
│ ...                                           │
│ ## 🤖 assistant                               │
│ ...                                           │
├─ prompt.md (editable) ────────────────────────┤
│ your reply here                               │
└───────────────────────────────────────────────┘
```

## Outcomes

| Action | Result |
|--------|--------|
| `:wqa` (or `ZZ`) | Submit the edited text as the next prompt. |
| `:PiSubmit` | Same as `:wqa`. |
| `:PiEdit` | Return the edited text to Pi's editor without submitting. |
| `:cq` (or `:PiCancel`) | Cancel; Pi's editor keeps its previous contents. |

When the agent is streaming, a submission is delivered as a **steer** message
(it reaches the model after the current turn's tool calls). When idle, it starts
a new turn immediately. A submitted prompt is sent with prompt-template expansion
enabled, so `/commands`, skills, and prompt templates typed in nvim behave like
normal input.

## What the context window contains

Compaction and branch summaries, plus user and assistant messages since the
last compaction (`buildContextEntries()`), rendered as Markdown. Tool calls,
tool results, bash executions, and thinking blocks are omitted to keep it
readable. The snapshot is capped at 4000 lines; if it overflows, the oldest
messages are dropped and a note is left behind.

The context window never folds, even if your nvim config folds Markdown by
default. This is a transient scratch editor, not a document.

The snapshot is frozen when nvim launches. If the agent produces new output
while you are editing, it will not appear until you reopen the editor.

## Files

- `index.ts` — extension: trigger, temp-file plumbing, context renderer.
- `pi-context.lua` — nvim shim: opens the read-only context split, defines the
  `:PiSubmit` / `:PiEdit` / `:PiCancel` commands, and persists the prompt on exit.

## Notes

- Requires `nvim` on `PATH`. If it is missing, the command reports an error and
  leaves the prompt unchanged.
- The built-in `Ctrl+G` (`app.editor.external`) is intentionally left as-is. Pi
  reserves that keybinding for extensions, so an extension shortcut bound to it
  is silently skipped. Use `/vim` or `Alt+G` for the context-aware flow, and
  keep `Ctrl+G` for the plain external-editor handoff.
- Attachments and images are not part of the text handoff, matching the stock
  external editor.
- To change the key from `Alt+G`, edit the `pi.registerShortcut(...)` call in
  `index.ts`; `/vim` always works.
