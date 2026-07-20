# field-notes.nvim

A lightweight note-taking plugin for Neovim. Notes are plain markdown files in a flat directory, named by slugified title. Weekly logs, templates, image embedding, and SVG diagrams included.

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
| `field_notes_templates_dir` | `nil` | Custom template directory (defaults to `<field_notes_dir>/_templates/`) |

## Commands

### Notes

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:Note "title" [template]` | 1-2 | Yes | Open or create a note in the current window. With `!`, also inserts a link at cursor. |
| `:NoteSplit "title" [template]` | 1-2 | Yes | Open or create a note in a horizontal split. Use `:vert` for vertical. With `!`, also inserts a link. |
| `:NoteVSplit "title" [template]` | 1-2 | Yes | Open or create a note in a vertical split. With `!`, also inserts a link. |
| `:NoteLink "title"` | 1 | No | Insert a markdown link to a note without opening it |
| `:NoteRename` | 0 | No | Rename current note file based on its `# heading` |
| `:NoteGrep <pattern>` | 1 | No | Search notes with `:grep` and open quickfix list |

### Weekly Logs

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:Log [offset]` | 0-1 | Yes | Open a weekly log note. Offset in weeks (0=this, 1=next, -1=last). Title: `YYYY-WWW: Mon DD` (`W` + Monday-based `%W`). New notes use the `log` template. |
| `:ThisWeek` | 0 | Yes | Alias for `:Log 0` |
| `:NextWeek` | 0 | Yes | Alias for `:Log 1` |
| `:LastWeek` | 0 | Yes | Alias for `:Log -1` |

### Media

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:Image <path>` | 1 | No | Copy image into note's `img/` dir and insert markdown link |
| `:Diagram [title]` | 0-1 | No | Create new SVG diagram from template and insert markdown link |

### Utilities

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:Slugify <text>` | 1 | No | Print slugified version of text |
| `:Asciiflow` | 0 | No | Open asciiflow.com in browser |

### Bang behavior

Bang (`!`) means "insert a link at the cursor before opening." This applies consistently to `:Note`, `:NoteSplit`, and `:NoteVSplit`.

Without `!`, notes open normally without inserting a link. `:Note` opens in the current window, `:NoteSplit` in a horizontal split, `:NoteVSplit` in a vertical split. `:vert NoteSplit` also opens vertically.

## Auto-title

When no title is provided to `:Note`, the title is derived from context:

- **In a git repo:** `<project>: <branch>` (e.g. `myapp: main`)
- **Outside a git repo:** `<parent_dir>: <cwd_dir>` (e.g. `Workspace: notes`)

## Completion

- `:Note "`, `:NoteSplit "`, `:NoteVSplit "` complete with existing note filenames (slugified titles)
- After the quoted title, a second argument completes with template names
- `:NoteLink "` completes with existing note filenames

## Templates

Templates are `.md` files in the templates directory (default: `<field_notes_dir>/_templates/`). When creating a new note, specify a template as the second argument:

```
:Note "Standup" meeting
```

Or set `field_notes_default_template` to apply a template to all new notes automatically. If the note file or buffer already exists, any supplied/default template is ignored.

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

When a note is opened, `:lcd` is set to the notes directory so relative paths resolve. Images and diagrams are stored per-note:

```
~/Workspace/field-notes/
  img/
    my-note-title/
      screenshot.png                 # :Image copies here
      my-diagram.svg                 # :Diagram creates here
```

## Renaming

`:NoteRename` reads the first `# heading` in the current note, slugifies it, and renames the file. Prompts before overwriting an existing file.

## Renaming
