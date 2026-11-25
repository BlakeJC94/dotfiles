# Custom Editor Extension

A single input editor that combines inline prompt snippets, Markdown-list editing,
and cross-session prompt history. Pi's `ctx.ui.setEditorComponent` is **last-wins**
and replaces the editor rather than composing with it, so all editor behavior
lives here.

## Files

- `index.ts` — extension source (editor class, prompt snippets, list helpers, prompt-history loader)

## Keybindings

| Key | Action |
|-----|--------|
| `Shift+Enter` | Continue the current Markdown list item (bullet, numbered, or checkbox). On an empty item, strip the marker and insert a plain newline to end the list. |
| `Ctrl+;` | Add `* ` at the start of the current line or remove an existing leading `* `. |
| `Ctrl+.` | Indent the current list line right by 4 spaces. |
| `Ctrl+,` | Indent the current list line left, snapped to a multiple of 4 spaces. |
| `Up` | With an empty input (or the cursor at the very start), load the previous prompt from recent sessions. |
| `Down` | While browsing history, move to the next prompt. |
| `Ctrl+Shift+End` | Move the cursor to the end of the current input (registered Pi shortcut, not an editor method). |

List continuation examples:

```
- item          ->  Shift+Enter  ->  - 
* [ ] item      ->  Shift+Enter  ->  * [ ] 
1. item         ->  Shift+Enter  ->  2. 
a. item         ->  Shift+Enter  ->  b. 
```

Bullets (`-` `*` `+`), numbered (`1.`), and single-letter (`a.` / `A.`) ordered
markers are supported; lettered markers advance to the next letter and wrap
`z -> a`. A checkbox (`[ ]` / `[x]`) is carried over onto the new item.

`Ctrl+;`, `Ctrl+.` and `Ctrl+,` require a terminal that reports enhanced key
events (Kitty keyboard protocol or modifyOtherKeys), because their raw control
characters collide with legacy terminal input.

## Prompt snippets

Type a token followed by a space to replace it with an editable prompt:

| Token | Prompt |
|-------|--------|
| `:r` / `:review` | Review changes without editing; optional focus at the end. |
| `:d` / `:debug` | Diagnose a symptom without editing; type the symptom at the end. |
| `:t` / `:test` | Run relevant tests; optionally specify a command or suite at the end. |
| `:e` / `:explain` | Explain a file or symbol; optionally specify a target at the end. |
| `:p` / `:plan` | Plan a goal without editing; type the goal at the end. |
| `:v` / `:verify` | Verify a claim against code; type the claim at the end. |

Expansion happens only when the exact token follows the start of input or whitespace.
It does not submit the prompt; continue editing and press Enter when ready.

## Prompt history

On `session_start`, the extension reads up to 100 unique user prompts from the
most recently modified sessions in the current working directory, newest first,
and preloads them. It is separate from Pi's own in-session history. When the
`tui.editor.historyPrevious` / `tui.editor.historyNext` keybindings are bound,
they also drive this history.

## Notes

- Requires an interactive UI; the `session_start` handler no-ops when `ctx.hasUI`
  is false.
- The history loader skips sessions that fail to open, logging a warning.
