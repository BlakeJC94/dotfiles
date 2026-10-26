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
| `:Note ["title"] [-t template]` | 0-1 title | Yes | Open or create a note in the current window. Title supports template vars like `{{date}}`. With `!`, also inserts a link at cursor. |
| `:NoteSplit ["title"] [-t template]` | 0-1 title | Yes | Open or create a note in a horizontal split. Use `:vert` for vertical. With `!`, also inserts a link. |
| `:NoteVSplit ["title"] [-t template]` | 0-1 title | Yes | Open or create a note in a vertical split. With `!`, also inserts a link. |
| `:NoteLink [path] "title"` | 0-2 | No | Insert a markdown link without opening a note. With no arguments, link to the last viewed field note using its first `#` heading as the title. With a title, the optional source path defaults to `expand("#")`. |
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

### URL titles

`url_title` does for web URLs what `:NoteLink` does for notes: with the cursor on an `http(s)://` URL it fetches the page's `<title>` with `curl` and replaces the URL with a markdown link `[title](url)`.

It is exposed as `M.url_title` rather than a command so it can be bound in your config:

```lua
vim.keymap.set("n", "gX", require("field-notes").url_title, { desc = "Fetch URL title" })
```

The fetch is asynchronous (via `vim.system`), so slow pages do not block the editor. If the URL has no `<title>` or the fetch fails, the buffer is left untouched.

### Bang behavior

Bang (`!`) means "insert a link at the cursor before opening." This applies consistently to `:Note`, `:NoteSplit`, and `:NoteVSplit`.

Without `!`, notes open normally without inserting a link. `:Note` opens in the current window, `:NoteSplit` in a horizontal split, `:NoteVSplit` in a vertical split. `:vert NoteSplit` also opens vertically.

With a line range and no quoted title (for example, `:'<,'>Note` or `:'<,'>Note -t meeting`), `:Note` uses the first nonblank selected line as the title and copies the selected lines into the note. The source stays unchanged. Existing notes receive the selection at the end. New notes ignore the default template, but honor an explicit `-t`.

## Auto-title

When no title is provided to `:Note`, the title is derived from context:

- **In a git repo:** `<parent_dir>: <dir>`, where `<dir>` is the directory containing Git's common directory (e.g. `Workspace: myapp`). In a linked worktree, append the worktree directory name unless it is `main` or `master`: `Workspace: myapp (feature-x)`. New notes link existing note filenames whose stems are substrings of the new note's stem.
- **Outside a git repo:** `<parent_dir>: <cwd_dir>` (e.g. `Workspace: notes`). Git context is determined from the current working directory.

## Completion

- `:Note "`, `:NoteSplit "`, `:NoteVSplit "` complete with existing note filenames (slugified titles)
- After `-t`, template names are completed (before or after the title)
- `:NoteLink "` completes with existing note filenames (path arg optional)

## Templates

Templates are `.md` files in the templates directory (default: `<field_notes_dir>/_templates/`).

Template variables also work in the quoted note title itself. Example:

```
:Note "Standup {{date}}" -t meeting
```

When creating a new note, specify a template with `-t`:

```
:Note -t meeting "Standup"
```

Use `-t` before or after the quoted title to select a template, or omit the title to derive it from context: `:Note -t meeting`. Positional template names are no longer accepted.

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
