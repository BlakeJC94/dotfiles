---
name: repo-component-notes
description: Work on note creation, opening, renaming, searching, listing, completion, or commands in field-notes.nvim. Use for changes to `lua/field-notes/notes.lua` or the note command flow.
---

# Notes component

## Responsibility

`lua/field-notes/notes.lua` owns note argument parsing and title resolution, opening or creating note buffers, note renaming, link updates after rename, grep, listing, completion, and registration of note-related user commands.

## Current behavior

- `:Note` accepts a quoted title and optional `-t template`; template selection can precede or follow the title. With no title, the title comes from `utils.get_note_title()`.
- New notes use the first rendered template `#` heading as their effective title when present, so the filename follows the heading. Otherwise a new buffer starts with `# <title>`.
- `:Note!`, `:NoteSplit!`, and `:NoteVSplit!` insert a note link before opening. Split commands pass the selected split mode to `open_note`.
- A range passed to `:Note` without a quoted title uses the first nonblank selected line as the title and appends the selected lines to the note. Range-created notes skip the default template, but an explicit `-t` template is applied.
- For untitled notes in a Git repo, matching existing note stems can be added under `## Related plans`.
- `:NoteRename` uses the first `#` heading, renames the current file to its slug, then updates relative Markdown links in Markdown files under the configured notes directory. External URLs and absolute paths are skipped.
- `:NoteGrep`, note listing, and completion use the configured notes directory.

## Relationships

- Uses `templates.lua` for template rendering and template completion.
- Uses `link.lua` for bang insertion, `:NoteLink`, and last-note tracking setup.
- Uses `images.lua` to register `:NoteImage`.
- Uses `config.lua` and `utils.lua` for directory, title, slug, and file behavior.
- `init.lua` exposes `notes.open_note` as the public `open_note` function.

## Source of truth

Read `lua/field-notes/notes.lua` first. Related command setup is in `lua/field-notes/init.lua`; template behavior is in `lua/field-notes/templates.lua`; link behavior is in `lua/field-notes/link.lua`.
