# Notes Module — `lua/field-notes/notes.lua`

The core module. Handles note creation, opening, renaming, grep, listing, and command-line completion.

---

## Note Opening Flow (`open_note`)

This is the central function called by `:Note`, `:NoteSplit`, and `:NoteVSplit`.

```
open_note(bang, args, opts)
  │
  ├─ resolve_note_title(args, opts)
  │   ├─ If opts.require_quoted_arg (user commands): parse_quoted_note_arg(args)
  │   │   Parses "title" [template] or 'title' [template]
  │   │   Returns (title, template_name, error)
  │   │
  │   └─ Else (programmatic call without quotes): utils.get_note_title(args)
  │       Falls through to auto-title derivation (git project/branch or parent:cwd)
  │
  ├─ Pre-render template (if given) and extract first # heading → becomes title
  │   This ensures the filename matches the rendered heading in the note.
  │   Template lines are saved for buffer population.
  │
  ├─ Render template variables in extracted title (e.g. {{date}}, {{strftime:...}})
  ├─ If bang (!): insert a markdown link at cursor via link.link_note(title)
  ├─ Build slugified filename: utils.slugify(title) .. ".md"
  ├─ Check if file exists on disk or in buffers
  ├─ Open file with split_cmd (edit / split / vsplit)
  │
  └─ If new note (not on disk, not in buffer):
      ├─ Use pre-rendered template lines if available
      └─ Otherwise create "# title\n\n" heading
      └─ If untitled AND in git repo: append "## Related plans" section
          with links to existing notes whose slug is a substring of current slug
```

### Related Note Links (auto-linking)

When an auto-titled note is created in a git repo, `related_note_links(filename)` scans all existing note stems and finds any that are substrings of the current stem. These are appended as a "## Related plans" section with markdown links. This creates an automatic web of references for context-aware scratchpad notes.

### Title Resolution Details

| Scenario | Title Source | Filename |
|----------|-------------|----------|
| `:Note "My Title"` | Quoted literal | `my-title.md` |
| `:Note "Standup {{date}}" meeting` | Template heading `# {{title}}` → `Standup 2025-09-24` | `standup-2025-09-24.md` |
| `:Log 0` | Template heading `# {{week}}` → `2025-W39: Sep 22` | `2025-w39-sep-22.md` |
| `:Journal 0` | Template heading `# Journal: {{week}}` → `Journal: 2025-W39: Sep 22` | `journal-2025-w39-sep-22.md` |
| `:Note` (in git repo) | Auto: `<project>: <branch>` | `<project>-<branch>.md` |
| `:Note` (outside git) | Auto: `<parent_dir>: <cwd_dir>` | `<parent>-<cwd>.md` |
| `:Note` (home bare repo) | Falls through to non-git auto-title | Handles `~/.dotfiles` with `$HOME` worktree |

---

## Rename Flow (`rename_note`)

1. Read first `# heading` from current buffer
2. Slugify the heading text
3. Build new path in same directory with same extension
4. If target exists and differs, prompt to confirm overwrite
5. `:write` → `:saveas <new_path>` → delete old file
6. Call `update_note_links(old_path, new_path)` to fix all cross-references

### Link Updating on Rename (`update_note_links`)

Scans every `.md` file in the notes directory. For each markdown link `[label](target)`:

1. Resolves `target` relative to the source file's directory
2. If it matches the *old* note path, recomputes a relative path from source → new path
3. Preserves URL fragments (`#section`) and query strings if present
4. Skips absolute paths and external URLs (e.g. `http://...`, `/absolute/path`)
5. Writes updated files back to disk

This ensures cross-note references remain valid after renaming.

---

## Grep (`grep_notes`)

Runs `:grep! <pattern> <notes_dir>` and opens the quickfix window. Uses `vim.fn.shellescape` for safe pattern handling. Pattern is a single required argument.

---

## Listing & Completion

### `list_notes()`
- Uses `vim.uv.fs_scandir` to walk `field_notes_dir`
- Filters for `.md` files, strips extension
- Returns alphabetically sorted list of stems

### `note_complete(arg_lead)`
- Filters `list_notes()` by prefix match on `arg_lead`
- Wraps results in double quotes for command-line completion

### Command Completion Logic

For `:Note`, `:NoteSplit`, `:NoteVSplit`:
- **First argument**: complete note filenames
- **After a quoted title**: complete template names (delegates to `templates.template_complete`)

For `:NoteLink`: always completes note filenames.

---

## Commands Registered

| Command | Handler | Split | Bang Support |
|---------|---------|-------|-------------|
| `:Note` | `M.open_note` | `edit` | Yes (inserts link) |
| `:NoteSplit` | `M.open_note` | `split` or `vsplit` (via `:vert`) | Yes |
| `:NoteVSplit` | `M.open_note` | `vsplit` | Yes |
| `:NoteRename` | `M.rename_note` | — | No |
| `:NoteGrep` | `M.grep_notes` | — | No |
| `:NoteLink` | `link.link_note` | — | No |
| `:NoteImage` | `images.move_image` | — | No |

> **Note:** `NoteVSplit` is registered *twice* in `setup()` (a harmless duplicate).

---

## Exported API

```lua
-- Stable top-level API exposed in init.lua
M.open_note = notes.open_note    -- for programmatic use / external config
M.link_note = link.link_note
```