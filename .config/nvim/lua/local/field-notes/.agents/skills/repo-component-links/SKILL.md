---
name: repo-component-links
description: Change Markdown note-link insertion, `:NoteLink` parsing, last-viewed-note behavior, or link updates on rename in field-notes.nvim. Use for `lua/field-notes/link.lua` and related note flows.
---

# Note links

## Responsibility

`lua/field-notes/link.lua` builds Markdown links to note files, parses `:NoteLink` arguments, and tracks the last viewed note. Rename-time link rewriting is implemented in `notes.lua`.

## Current behavior

- `link_note(title, source_path)` slugifies the title to form the target filename under `field_notes_dir`.
- Links are inserted only when the current buffer extension is `md`. The source path defaults to the alternate file (`#`); when available, `vim.fs.relpath` computes the path from that source file's directory to the target.
- `:NoteLink` with no arguments links to the last field note observed during `BufLeave`, using its first `#` heading as link text. Missing, unreadable, or heading-less last notes report an error.
- With arguments, `parse_note_link_args` accepts an optional source path and a quoted title, or a plain title. The default source path is the alternate file.
- Link insertion edits the current line at the cursor and advances the cursor past the inserted Markdown.
- `notes.lua` updates matching relative Markdown links when a note is renamed; that rewrite logic is not in this module.

## Relationships

- `notes.lua` calls `link_note` for bang commands and handles `:NoteLink` registration and rename rewriting.
- `utils.lua` provides slugification; `config.lua` provides the notes directory.
- `init.lua` exports `link_note` at the plugin top level.

## Source of truth

Read `lua/field-notes/link.lua` and the rename logic in `lua/field-notes/notes.lua`.
