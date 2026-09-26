# field-notes.nvim — Knowledge Base

A lightweight note-taking plugin for Neovim, written in Lua. Notes are plain Markdown files in a flat directory, named by slugified title. Supports weekly logs, templates with variable interpolation, image embedding, SVG diagrams, and relative linking.

**Language / Runtime:** Lua 5.1 (Neovim 0.9+), targeting `vim.system` / `vim.uv` APIs (Neovim 0.10+ features used where available).

**High-Level Architecture:**

The plugin is organized as a set of small, focused Lua modules beneath `lua/field-notes/`, orchestrated by a thin `init.lua` entrypoint. User-facing functionality is exposed exclusively through Neovim user commands (`:Note`, `:Log`, `:NoteLink`, `:NoteRename`, `:NoteGrep`, `:NoteImage`, `:Slugify`, `:Asciiflow`). No Lua API is required for daily use, though `M.open_note` and `M.link_note` are exported for integration.

Configuration is flat (a few options in `config.lua`), merged via `vim.tbl_deep_extend`. Notes live in a configurable flat directory (`field_notes_dir`), and templates live in a `_templates/` subdirectory. Weekly logs are a special case of notes with Monday-based week-date naming (`YYYY-WWW: Mon DD`). The template system supports `{{title}}`, `{{date}}`, `{{week}}`, and `{{strftime:FORMAT}}` with optional date arithmetic (`base+offset`).

Image handling copies files into a per-note `img/<slug>/` directory. The link module computes relative paths from the source file's directory to the target note.

**Key Files:**

| Path | Responsibility |
|------|---------------|
| `lua/field-notes/init.lua` | Entry point; registers all user commands; exports `open_note` and `link_note` |
| `lua/field-notes/config.lua` | Flat options with defaults; `setup(opts)` merges user config |
| `lua/field-notes/notes.lua` | Core note creation, opening, renaming, grep, listing, completion |
| `lua/field-notes/link.lua` | Markdown link insertion (`[title](path)`) with relative path resolution |
| `lua/field-notes/log.lua` | Weekly log commands (`:Log`, `:ThisWeek`, `:NextWeek`, `:LastWeek`) |
| `lua/field-notes/templates.lua` | Template directory scanning, variable rendering, template application |
| `lua/field-notes/utils.lua` | Slugification, git detection, auto-title derivation, file copy, image dir helpers |
| `lua/field-notes/images.lua` | `:NoteImage` — copy image into note's `img/` dir and insert markdown link |
| `_templates/log.md` | Default weekly log template (quests, daily sections, checkboxes) |
| `README.md` | Plugin-level documentation (commands, config, templates reference) |

**External Dependencies:** None. Only depends on Neovim's built-in Lua APIs (`vim.api`, `vim.uv`, `vim.system`, `vim.fn`).

**Commands Summary:**

| Command | Description |
|---------|-------------|
| `:Note "title" [template]` | Open/create note (bang: insert link) |
| `:NoteSplit "title" [template]` | Open in horizontal/vertical split |
| `:NoteVSplit "title" [template]` | Open in vertical split |
| `:NoteLink [path] "title"` | Insert link without opening |
| `:NoteRename` | Rename file to match `# heading` |
| `:NoteGrep <pattern>` | Search notes via `:grep` |
| `:Log [offset]` | Open weekly log (0=this week) |
| `:ThisWeek` / `:NextWeek` / `:LastWeek` | Log aliases |
| `:NoteImage <path>` | Copy image and insert markdown link |
| `:Slugify <text>` | Print slugified text |
| `:Asciiflow` | Open asciiflow.com |

## Suggested Deep-Dives

- [x] **modules/notes/** — Note opening flow, auto-title derivation, rename with link updating, grep, completion system
- [x] **modules/templates/** — Template variable rendering (`{{strftime}}` with date arithmetic), template discovery and application
- [x] **modules/link/** — Relative link generation, `:NoteLink` argument parsing, link updating on rename
- [x] **modules/log/** — Weekly log date math, command set, template context
- [x] **modules/images/** — Image copy, directory management, markdown link insertion
- [x] **modules/utils/** — Slugification, git detection (including home bare repo edge case), file operations
- [x] **data-model/** — Note file naming convention, directory layout, template structure