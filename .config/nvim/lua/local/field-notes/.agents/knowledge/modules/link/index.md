# Link Module — `lua/field-notes/link.lua`

Handles inserting markdown links between notes, resolving relative paths, and parsing `:NoteLink` arguments.

---

## Link Insertion (`link_note`)

```lua
M.link_note(title, source_path)
```

Called by:
- `:Note`, `:NoteSplit`, `:NoteVSplit` with `!` bang (inserts link before opening)
- `:NoteLink` (inserts link without opening)

### Flow

1. **Build note path**: `slugify(title) .. ".md"` → `<field_notes_dir>/<filename>`
2. **Default filepath**: `./<filename>` (relative to current directory)
3. **Resolve source path**: if `source_path` is nil/empty, use alternate file `#:p`
4. **Compute relative path**:
   - Get source file's directory: `fnamemodify(source_path, ":p:h")`
   - Compute `vim.fs.relpath(source_dir, note_path)`
   - If relative path is valid, use it instead of `./<filename>`
5. **Build markdown link**: `[title](path)`
6. **Insert at cursor** (only if current buffer is `.md`):
   - Split current line at cursor column
   - Insert `[title](path)` between before/after parts
   - Move cursor to end of inserted text

### Relative Path Examples

| Source File | Target Note | Relative Link |
|------------|-------------|---------------|
| `~/notes/foo.md` | `~/notes/bar.md` | `[bar](./bar.md)` |
| `~/notes/sub/foo.md` | `~/notes/bar.md` | `[bar](../bar.md)` |
| `~/notes/foo.md` | `~/notes/sub/bar.md` | `[bar](./sub/bar.md)` |
| `~/doc/source.md` | `~/notes/target.md` | `[target](../../notes/target.md)` |

Uses `vim.fs.relpath` (Neovim 0.10+) for reliable cross-platform relative path computation.

---

## Argument Parsing (`parse_note_link_args`)

```lua
M.parse_note_link_args(args)
```

Parses `:NoteLink [path] "title"` or `:NoteLink [path] 'title'`.

### Supported Forms

| Command | `source_path` | `title` |
|---------|--------------|---------|
| `:NoteLink "My Title"` | `#` (alternate file) | `My Title` |
| `:NoteLink ~/other.md "My Title"` | `~/other.md` | `My Title` |
| `:NoteLink My Title` | `#` (alternate file) | `My Title` (unquoted fallback) |
| `:NoteLink` | Error | — |

### Parsing Algorithm

1. Trim whitespace
2. Try to match `"..."` or `'...'` for the title
3. If quoted title found, everything before it is the optional source path (trimmed)
4. If no quotes found, treat entire args as the title and use `#` as source
5. Empty args → error

The source path defaults to `vim.fn.expand("#")` (the alternate file — the previous buffer) when omitted. This makes `:NoteLink "title"` convenient for linking from the current buffer to a note while keeping context.

---

## Link Updating on Rename

The link module has a second responsibility in `notes.lua`'s `update_note_links(old_path, new_path)` — when a note is renamed, all cross-references in the notes directory are updated.

See [modules/notes/index.md](../notes/index.md#link-updating-on-rename) for details on the link rewriting logic.

### Update Algorithm Summary

1. Scan all `.md` files in `field_notes_dir`
2. For each markdown link `[label](target)`:
   - Resolve `target` relative to the source file's directory
   - If it matches the old note path, compute new relative path
   - Preserve URL fragments/suffix
3. Skip absolute paths and external URLs
4. Write changed files

### Edge Cases Handled

- **Same-directory links**: `./foo.md` stays `./bar.md` after rename
- **Cross-directory links**: `<relative path>` recomputed when source and target are in different dirs
- **URL fragments**: `[label](path#section)` preserves `#section`
- **External URLs**: `https://...`, `mailto:...` are left untouched
- **Absolute paths**: `/home/user/notes/foo.md` is left untouched (external to the notes dir)