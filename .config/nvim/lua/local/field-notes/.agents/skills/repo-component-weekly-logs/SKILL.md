---
name: repo-component-weekly-logs
description: Change `:Log` or `:Journal`, week offsets, date context, or log-template selection in field-notes.nvim. Use for `lua/field-notes/log.lua` and its interaction with templates.
---

# Weekly logs and journals

## Responsibility

`lua/field-notes/log.lua` registers `:Log` and `:Journal` and delegates actual note creation to `notes.open_note`.

## Current behavior

- Each command accepts an optional numeric week offset; missing or nonnumeric input resolves to zero.
- The target timestamp is based on the current time, shifted by whole weeks, then anchored to Monday using `%u` (Monday is 1).
- The displayed title uses `%Y-W%W: %b %d` for that Monday.
- `:Log` uses the `log` template and `:Journal` uses `journal`, unless `default_template_log` or `default_template_journal` overrides the respective name.
- The command passes the Monday timestamp as `reference_timestamp`, so template date variables can describe the requested week rather than the current week.
- Both commands support bang behavior inherited by `notes.open_note`.

## Relationships

- `notes.lua` parses the generated quoted title/template arguments, renders the template, and opens the note.
- `templates.lua` uses the provided reference timestamp for `{{week}}` and `{{strftime:...}}` variables.
- `config.lua` defines the per-command template overrides.
- Bundled templates are `_templates/log.md` and `_templates/journal.md`.

## Source of truth

Read `lua/field-notes/log.lua`, then check the delegated flows in `lua/field-notes/notes.lua` and `lua/field-notes/templates.lua`.
