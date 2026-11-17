---
name: repo-component-templates
description: Change Markdown template discovery, interpolation, date variables, or template application in field-notes.nvim. Use for `lua/field-notes/templates.lua` and template-related note behavior.
---

# Templates component

## Responsibility

`lua/field-notes/templates.lua` locates Markdown templates, renders supported variables, and returns rendered lines for new notes.

## Current behavior

- The template directory is `field_notes_templates_dir` when configured, otherwise `<field_notes_dir>/_templates`.
- Template discovery lists `.md` files and uses their filename stems as template names. Completion filters those names by prefix.
- `apply_template(name, title, context)` reads `<template_dir>/<name>.md`, renders it, and returns lines; a missing/unreadable template returns `nil`.
- Supported substitutions are `{{title}}`, `{{date}}`, `{{week}}`, `{{strftime:FORMAT}}`, and `{{strftime:FORMAT:BASE+OFFSET}}`. Date bases handled by the renderer are `today` and `monday`; offsets are in days. Unrecognized date bases fall back to the current timestamp.
- A supplied `reference_timestamp` in context makes rendering deterministic for date-related variables. Weekly log commands pass this context.
- The note module uses the first rendered `#` heading as the effective title for a new note.

## Relationships

- `notes.lua` selects templates and derives the effective title from rendered content.
- `log.lua` supplies week-specific context and configurable log/journal template names.
- Defaults and template-directory configuration are in `config.lua`.
- Bundled templates are under `_templates/`.

## Source of truth

Read `lua/field-notes/templates.lua` and `lua/field-notes/notes.lua`. Verify variable syntax against the renderer before updating examples in `README.md` or bundled templates.
