# Images Module — `lua/field-notes/images.lua`

Handles importing images into a note's media directory and inserting a markdown image reference. The single public function `move_image` is invoked by the `:NoteImage` command.

---

## Command: `:NoteImage <path>`

Registered in `notes.lua` (not `images.lua` itself), but handled entirely by this module.

| Aspect | Detail |
|--------|--------|
| Args | 1 (required) — path to an image file |
| Bang | No |
| Completion | None |
| Error | Prints error if path is empty or file doesn't exist |

---

## Image Import Flow (`move_image`)

```
:NoteImage ~/Downloads/screenshot.png
  │
  ├─ Expand path: vim.fn.expand("~/Downloads/screenshot.png")
  ├─ Validate: filereadable check → error if missing
  │
  ├─ Extract target components:
  │   target_stem = "screenshot"          (fnamemodify ":t:r")
  │   target_ext  = "png"                 (fnamemodify ":e")
  │
  ├─ Compute destination:
  │   utils.get_note_image_dir()
  │     ├─ note_parent_dir = <dir of current buffer>
  │     ├─ note_stem       = <current file's stem>  (e.g. "my-note-title")
  │     ├─ img_subdir      = slugify(note_stem)     (e.g. "my-note-title")
  │     └─ dest_dir        = <note_parent_dir>/img/<img_subdir>/
  │
  ├─ Ensure directory exists:
  │   if not isdirectory(dest_dir): mkdir(dest_dir, "p")  (creates parents)
  │
  ├─ Build destination filename:
  │   slugified_stem = utils.slugify("screenshot")  → "screenshot"
  │   dest_filename  = "screenshot.png"
  │   dest_path      = <dest_dir>/screenshot.png
  │
  ├─ Copy file: utils.copy_file(target_path, dest_path)
  │   Uses vim.system({"cp", ...}) or vim.fn.system fallback
  │   → Error if copy fails
  │
  ├─ Insert markdown reference:
  │   relative_path = "./img/<img_subdir>/<dest_filename>"
  │                 = "./img/my-note-title/screenshot.png"
  │   markdown_text = "![screenshot](./img/my-note-title/screenshot.png)"
  │   vim.fn.append(line("."), markdown_text)
  │   → Inserts the markdown line below the current cursor line
  │
  └─ Print confirmation: "Image moved to: <dest_path>"
```

### Resulting Directory Structure

```
<field_notes_dir>/
├── my-note-title.md                     # Current note
└── img/
    └── my-note-title/                   # Auto-created per-note dir
        └── screenshot.png               # Copied image
```

---

## Directory Path Logic

### `utils.get_note_image_dir()`

```lua
function M.get_note_image_dir()
    local note_parent_dir = vim.fn.expand("%:p:h")     -- Current file's parent dir
    local note_stem = vim.fn.expand("%:t:r")            -- Current file's stem (no ext)
    local img_subdir = M.slugify(note_stem)              -- Slugified for safety
    local img_dir = note_parent_dir .. "/img/" .. img_subdir
    return img_dir, img_subdir, note_parent_dir, note_stem
end
```

Returns four values:
1. `img_dir` — full path to the per-note image directory
2. `img_subdir` — slugified directory name (used for relative links)
3. `note_parent_dir` — the directory containing the current note
4. `note_stem` — the unslugified stem

### Why Slugify the Subdirectory

The slugification of the note stem for the directory name ensures:
- No spaces or special chars in paths
- Consistency between the directory name and how the note filename was derived
- Safe cross-platform filesystem behavior

---

## Relative Link Construction

The markdown image link always uses the `./img/<subdir>/<filename>` convention:

```lua
local relative_path = "./img/" .. img_subdir .. "/" .. dest_filename
local markdown_text = utils.markdown_image_link(target_stem, relative_path)
vim.fn.append(vim.fn.line("."), markdown_text)
```

This assumes the note `.md` file is at the same level as the `img/` directory. The link is **not** recomputed as a true relative path from source to destination — it's always `./img/<slug>/<file>`.

The `alt_text` is the original (un-slugified) stem of the source file, preserving a readable description.

---

## Integration Points

| Component | Role |
|-----------|------|
| `notes.lua` | Registers the `:NoteImage` user command |
| `utils.get_note_image_dir` | Computes destination directory (shared with potential future media features) |
| `utils.slugify` | Sanitizes image filename and directory name |
| `utils.copy_file` | Performs the actual file copy |
| `utils.markdown_image_link` | Formats `![alt](path)` |

