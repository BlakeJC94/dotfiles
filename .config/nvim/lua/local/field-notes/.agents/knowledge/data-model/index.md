# Data Model — File Naming, Directory Layout, and Structure

---

## Notes Directory Layout

```
~/Workspace/field-notes/              # field_notes_dir (configurable)
├── my-note-title.md                  # Notes — slugified filenames
├── another-note.md
├── 2025-w39-sep-22.md                # Weekly logs — date-based slugs
├── img/                              # Media directory
│   ├── my-note-title/
│   │   ├── screenshot.png            # Copied via :NoteImage
│   │   └── my-diagram.svg            # Created via :Diagram
│   └── another-note/
│       └── diagram.svg
└── _templates/                       # Template directory
    ├── meeting.md                    # Custom note templates
    ├── weekly.md
    └── log.md                        # Default log template
```

### Key Principles

- **Flat**: All notes are in a single directory (no subdirectories for notes themselves)
- **Markdown only**: Every note is an `.md` file
- **Slugified names**: Derived from the title via `utils.slugify()`

---

## Note Naming Convention

### Regular Notes

```
utils.slugify("My Note Title: Part 2")
→ "my-note-title-part-2"
→ "my-note-title-part-2.md"
```

Slugification rules:
1. Lowercase the string
2. Replace all non-word characters (`[^%w]+`) with `-`
3. Strip leading `-`
4. Strip trailing `-`

### Weekly Logs

Logs use a date-based slug derived from the template's `# heading`:

- `:Log` uses the `log` template. Default heading: `# {{week}}` → `# 2025-W39: Sep 22` → slug `2025-w39-sep-22.md`
- `:Journal` uses the `journal` template. Default heading: `# Journal: {{week}}` → `# Journal: 2025-W39: Sep 22` → slug `journal-2025-w39-sep-22.md`

The filename is determined by the template's first `# heading`, not by the command's title argument. This keeps filenames in sync with what the note actually displays.

Monday is computed as `now - ((weekday - 1) * 86400)` where `weekday = %u` (Monday=1). Offset support: `:Log 1` adds 7 days, `:Log -1` subtracts 7 days from the Monday anchor.

### Auto-Titled Notes (no title argument)

When `:Note` is called without a title, the title is derived from context:

| Condition | Title Pattern | Example |
|-----------|--------------|---------|
| In git repo (non-home) | `<project>: <branch>` | `myapp: feature-x` |
| Not in git repo | `<parent_dir>: <cwd_dir>` | `Workspace: notes` |
| Home dotfiles repo detected | Falls to non-git pattern | — |

Hardcoded detection of the dotfiles bare repo (`~/.dotfiles` with worktree=`$HOME`, used via `git dotfiles` alias):
- `get_git_dir()` explicitly checks for `~/.dotfiles` when standard `git rev-parse` finds nothing
- `get_note_title()` hardcodes `git_dir_path == <dotfiles_dir>` to skip the git auto-title
- This replaces a previous generic heuristic that tried to detect any home-level bare repo dynamically

### Existing Note Linking (Auto-Title)

When an auto-titled note is created in a git repo, existing notes whose slugs are substrings of the new slug get linked in a "## Related plans" section. Example: creating `myapp: feature-x` would link an existing note named `feature-x`.

---

## Images & Media

Per-note image directory: `<field_notes_dir>/img/<note-slug>/`

- Created automatically when `:NoteImage <path>` is called
- Slugified note stem ensures safe directory names
- Links are relative: `./img/<note-slug>/<filename>.png`

---

## Templates

Located at `<field_notes_dir>/_templates/` (or custom `field_notes_templates_dir`).

- All template files are `.md`
- Template names are the file stem (e.g. `meeting.md` → template name `meeting`)
- Selected via `:Note "Title" template_name` or `field_notes_default_template`
- Template variables are rendered at creation time (not stored in the template file itself)

### Variable Substitution Order

1. `{{title}}` → The note title
2. `{{date}}` → `YYYY-MM-DD`
3. `{{week}}` → `YYYY-WW: Mon DD`
4. `{{strftime:fmt:base+offset}}` → Date arithmetic
5. `{{strftime:fmt}}` → Simple date format

---

## Configuration Schema

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `field_notes_dir` | string (path) | `~/Workspace/field-notes` | Root notes directory |
| `field_notes_default_template` | string \| nil | `nil` | Template applied when no template arg given |
| `field_notes_templates_dir` | string (path) \| nil | `nil` | Custom templates dir (defaults to `<dir>/_templates/`) |

Configuration is merged via `vim.tbl_deep_extend("force", defaults, opts)` in `config.setup()`.