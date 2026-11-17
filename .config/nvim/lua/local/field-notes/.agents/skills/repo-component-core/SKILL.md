---
name: repo-component-core
description: Change field-notes.nvim configuration, slug/path helpers, Git context detection, or shared file operations. Use for `lua/field-notes/config.lua` and `lua/field-notes/utils.lua`.
---

# Configuration and shared utilities

## Configuration

`lua/field-notes/config.lua` defines defaults for `field_notes_dir`, `field_notes_default_template`, `default_template_log`, `default_template_journal`, and `field_notes_templates_dir`. `setup(opts)` deep-merges user options over defaults; `get(key)` returns the configured value, falling back to the default.

## Utilities

`lua/field-notes/utils.lua` centralizes:

- `slugify`: lowercase text, replace groups of non-word characters with `-`, and strip leading/trailing hyphens.
- Git command execution, preferring `vim.system` and falling back to `vim.fn.system`.
- Git directory lookup from the current buffer's directory, including an explicit check for the user's `~/.dotfiles` bare repo.
- Default note-title generation from the current working directory and Git common directory; non-main/master worktrees can add a worktree name.
- File copying, per-note image path generation, and Markdown image-link formatting.

## Relationships

- `notes.lua`, `link.lua`, `images.lua`, and `templates.lua` use these shared facilities.
- `init.lua` invokes `config.setup(opts)` before setting up the modules.
- Note storage and template paths are configured independently; image paths are derived from the active buffer.

## Source of truth

Read `lua/field-notes/config.lua` and `lua/field-notes/utils.lua`. Check callers before changing helper semantics, especially path resolution and the distinction between current buffer directory and current working directory.
