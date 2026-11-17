---
name: repo-overview
description: Understand the purpose, architecture, entry points, and component relationships of the field-notes Neovim plugin. Use when orienting in this repository or changing cross-component behavior.
---

# field-notes.nvim overview

## Purpose

A lightweight Neovim plugin for creating and managing plain Markdown notes, weekly logs, templates, relative note links, image embeds, and links from web-page titles. The plugin is implemented in Lua under `lua/field-notes/`.

## Architecture

`lua/field-notes/init.lua` is the public setup and API entry point. `setup(opts)` initializes configuration, note commands, and weekly log commands. The note module coordinates note creation and uses the template, link, image, and utility modules. Weekly log commands build date context and delegate note creation to the note module.

The main components are:

- `notes.lua`: note creation/opening, rename and reference updates, grep, listing, completion, and note-related commands.
- `templates.lua`: Markdown template discovery, variable rendering, and template loading.
- `log.lua`: `:Log` and `:Journal`, with week offsets and template selection.
- `link.lua`: Markdown link insertion, last-viewed-note tracking, and `:NoteLink` argument handling.
- `images.lua`: `:NoteImage` file copying and Markdown image insertion.
- `urltitle.lua`: fetches a page title for the URL under the cursor and replaces it with a Markdown link.
- `config.lua` and `utils.lua`: options and shared path, slug, Git, copy, and image helpers.

## User-facing entry points

Call `require("field-notes").setup(opts)` from Neovim configuration. The top-level module exports `open_note`, `link_note`, and `url_title`. `notes.setup()` registers `:Note`, `:NoteSplit`, `:NoteVSplit`, `:NoteRename`, `:NoteGrep`, `:NoteLink`, and `:NoteImage`; `log.setup()` registers `:Log` and `:Journal`.

See `README.md` for the user-facing setup, options, and command reference. Confirm command details in source when editing behavior; documentation and implementation may diverge.

## Data and configuration

Notes are Markdown files in `field_notes_dir` (default `~/Workspace/field-notes`). Templates default to its `_templates/` subdirectory and can be overridden with `field_notes_templates_dir`. Image files are copied beneath an `img/<note-slug>/` path relative to the active note. See `repo-component-templates`, `repo-component-weekly-logs`, and `repo-component-media` for those flows.

The plugin has no Lua package dependencies. URL title fetching invokes the external `curl` executable. The checked-in templates are `_templates/log.md` and `_templates/journal.md`.

## Source map

- `lua/field-notes/init.lua` - setup and exported API
- `lua/field-notes/config.lua` - defaults and option lookup
- `lua/field-notes/notes.lua` - core note workflow and commands
- `lua/field-notes/templates.lua` - template loading and rendering
- `lua/field-notes/log.lua` - weekly logs and journals
- `lua/field-notes/link.lua` - note links and rename-related tracking
- `lua/field-notes/images.lua` - image import
- `lua/field-notes/urltitle.lua` - web URL title conversion
- `lua/field-notes/utils.lua` - shared helpers
- `_templates/` - bundled note templates
- `README.md` - user guide
