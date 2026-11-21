# Custom Editor Extension

A single input editor that combines Markdown-list editing and cross-session prompt
history. Both features previously lived in separate editor-replacing extensions
(`lists-md.ts` and `persistent-prompt-history.ts`); Pi's
`ctx.ui.setEditorComponent` is **last-wins** and replaces the editor rather than
composing with it, so only one extension may own it. They are merged here.

## Files

- `index.ts` — extension source (editor class, list helpers, prompt-history loader)

## Keybindings

| Key | Action |
|-----|--------|
| `Shift+Enter` | Continue the current Markdown list item (bullet, numbered, or checkbox). On an empty item, strip the marker and insert a plain newline to end the list. |
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

`Ctrl+.` and `Ctrl+,` require a terminal that reports enhanced key events (Kitty
keyboard protocol or modifyOtherKeys), because the raw control characters for `.`
and `,` collide with legacy terminal input.

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
