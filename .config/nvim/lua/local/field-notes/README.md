# field-notes.nvim

A lightweight note-taking plugin for Neovim. Notes are plain markdown files in a flat directory, named by slugified title. Weekly logs, templates, and image embedding included.

## Setup

```lua
require("field-notes").setup({
    field_notes_dir = "~/Workspace/field-notes",
    field_notes_default_template = nil,
    field_notes_templates_dir = nil,
})
```

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `field_notes_dir` | `~/Workspace/field-notes` | Directory where notes are stored as flat `.md` files |
| `field_notes_default_template` | `nil` | Template name applied to all new notes when no template arg is given |
| `default_template_log` | `nil` | Override template for `:Log` (default: `log`) |
| `default_template_journal` | `nil` | Override template for `:Journal` (default: `journal`) |
| `field_notes_templates_dir` | `nil` | Custom template directory (defaults to `<field_notes_dir>/_templates/`) |

## Commands

### Notes

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:Note "title" [template]` | 1-2 | Yes | Open or create a note in the current window. Title supports template vars like `{{date}}`. With `!`, also inserts a link at cursor. |
| `:NoteSplit "title" [template]` | 1-2 | Yes | Open or create a note in a horizontal split. Use `:vert` for vertical. Title supports template vars like `{{date}}`. With `!`, also inserts a link. |
| `:NoteVSplit "title" [template]` | 1-2 | Yes | Open or create a note in a vertical split. Title supports template vars like `{{date}}`. With `!`, also inserts a link. |
| `:NoteLink [path] "title"` | 1-2 | No | Insert a markdown link to a note without opening it. If path is omitted, uses `expand("#")`. |
| `:NoteRename` | 0 | No | Rename current note file based on its `# heading` |
| `:NoteGrep <pattern>` | 1 | No | Search notes with `:grep` and open quickfix list |

### Weekly Logs

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:Log [offset]` | 0-1 | Yes | Open a weekly log note. Offset in weeks (0=this, 1=next, -1=last). Title and filename derived from the template's `# heading`. Default template: `log`. |
| `:Journal [offset]` | 0-1 | Yes | Open a weekly journal note. Same offset semantics as `:Log`. Default template: `journal`. |
| `:ThisWeek` | 0 | Yes | Alias for `:Log 0` |
| `:NextWeek` | 0 | Yes | Alias for `:Log 1` |
| `:LastWeek` | 0 | Yes | Alias for `:Log -1` |

### Media

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:NoteImage <path>` | 1 | No | Copy image into note's `img/` dir and insert markdown link |

### Bang behavior

Bang (`!`) means "insert a link at the cursor before opening." This applies consistently to `:Note`, `:NoteSplit`, and `:NoteVSplit`.

Without `!`, notes open normally without inserting a link. `:Note` opens in the current window, `:NoteSplit` in a horizontal split, `:NoteVSplit` in a vertical split. `:vert NoteSplit` also opens vertically.

## Auto-title

When no title is provided to `:Note`, the title is derived from context:

- **In a git repo:** `<project>: <branch>` (e.g. `myapp: main`) — skips the dotfiles bare repo (`~/.dotfiles` with worktree=`$HOME`). New notes link existing note filenames whose stems are substrings of the new note's stem.
- **Outside a git repo:** `<parent_dir>: <cwd_dir>` (e.g. `Workspace: notes`)

## Completion

- `:Note "`, `:NoteSplit "`, `:NoteVSplit "` complete with existing note filenames (slugified titles)
- After the quoted title, a second argument completes with template names
- `:NoteLink "` completes with existing note filenames (path arg optional)

## Templates

Templates are `.md` files in the templates directory (default: `<field_notes_dir>/_templates/`).

Template variables also work in the quoted note title itself. Example:

```
:Note "Standup {{date}}" meeting
```

When creating a new note, specify a template as the second argument:

```
:Note "Standup" meeting
```

Or set `field_notes_default_template` to apply a template to all new notes automatically. If the note file or buffer already exists, any supplied/default template is ignored.

**Filename from template heading:** When a template is applied to a new note, the filename is derived from the template's first `# heading` rather than the command's title argument. This keeps the filename in sync with what actually appears in the note. For example, a template with `# Journal: {{week}}` produces `journal-2025-w39-sep-22.md`.

### Template variables

| Variable | Description |
|----------|-------------|
| `{{title}}` | The note title |
| `{{date}}` | Current date (`YYYY-MM-DD`) |
| `{{week}}` | Current week title (`YYYY-WW: Mon DD`, Monday-based `%W`) |
| `{{strftime:FORMAT}}` | Arbitrary `os.date` format (e.g. `{{strftime:%Y}}`) |
| `{{strftime:FORMAT:base+offset}}` | Date arithmetic. `base` is `today` or `monday`, `offset` is days (e.g. `{{strftime:%A:monday+2}}` for Wednesday) |

### Example: weekly log template

`_templates/weekly.md`:

```markdown
# {{week}}

## {{strftime:%A - %b %d:monday+0}}
## {{strftime:%A - %b %d:monday+1}}
## {{strftime:%A - %b %d:monday+2}}
## {{strftime:%A - %b %d:monday+3}}
## {{strftime:%A - %b %d:monday+4}}
## {{strftime:%A - %b %d:monday+5}}
## {{strftime:%A - %b %d:monday+6}}
```

## File structure

```
~/Workspace/field-notes/
  my-note-title.md                  # Notes (slugified filenames)
  2025-w29-jul-14.md                # Weekly logs
  _templates/
    meeting.md                       # Note templates
    weekly.md
```

Opening a note preserves the existing working directory. Images are stored per-note:

```
~/Workspace/field-notes/
  img/
    my-note-title/
      screenshot.png                 # :NoteImage copies here
```

## Renaming

`:NoteRename` reads the first `# heading` in the current note, slugifies it, and renames the file. Prompts before overwriting an existing file.
