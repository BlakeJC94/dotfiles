# Utils Module — `lua/field-notes/utils.lua`

Shared utility functions used across all other modules. Covers slugification, git detection, auto-title derivation, file operations, and image directory helpers.

---

## Slugification (`slugify`)

```lua
M.slugify("Hello World! #2")
→ "hello-world-2"
```

Algorithm:
1. `str:lower()` — lowercase
2. `gsub("%W+", "-")` — all non-word characters → hyphens
3. `gsub("^-+", "")` — strip leading hyphens
4. `gsub("-+$", "")` — strip trailing hyphens

Used for: note filenames, image subdirectory names, image file slugs.

---

## Git Detection (`get_git_dir`)

```lua
M.get_git_dir()
```

Returns the git directory path (e.g., `.git`) or `""` if not in a git repo.

Checks `vim.fn.executable("git")` first. Runs `git -C <file_dir> rev-parse --git-dir`.

### Underlying Git Helper (`get_git_output`)

Two implementation paths:

1. **Neovim 0.10+** (preferred): Uses `vim.system({ "git", "-C", dir, ... }, { text = true })`
2. **Fallback**: Uses `vim.fn.system("git -C <dir> ...")`

Both trim trailing newlines and return empty string on non-zero exit code.

---

## Auto-Title Derivation (`get_note_title`)

```lua
M.get_note_title(...)
```

If arguments are provided, joins them as the title. Otherwise, derives a contextual title:

### Flow

```
get_note_title()
│
├─ Check git status via get_git_dir()
│
├─ Detect home bare repos
│   Condition: is_bare_repo AND git_dir is under $HOME
│              AND (worktree is unset OR worktree == $HOME)
│   → If matched, treat as non-git (skip project:branch title)
│
├─ If valid git repo:
│   project = basename of parent of .git dir
│   branch = git -C <dir> branch --show-current --quiet
│   title = "<project>: <branch>"
│
└─ If not git (or home bare repo):
    cwd_parts = parent_dir (t) and cwd_dir (t)
    title = "<parent_dir>: <cwd_dir>"
```

### Home Bare Repo Detection (Hardcoded)

The dotfiles bare repo (`~/.dotfiles`, worktree=`$HOME`, used via `git dotfiles` alias) is detected in two places:

1. **`get_git_dir()`**: After standard `git rev-parse --git-dir` fails (no `.git` in `$HOME`), explicitly checks if the current file is under `$HOME` and `~/.dotfiles` exists as a bare repo. Returns `~/.dotfiles` as the git dir.

2. **`get_note_title()`**: When the resolved git dir matches `~/.dotfiles`, sets `git_dir = ""` to fall through to the non-git auto-title (`parent_dir: cwd_dir`).

This prevents files under `$HOME` from getting `<project>: <branch>` titles when only the dotfiles repo would apply.

---

## File Operations

### `copy_file(source_path, dest_path)`

Copies a file from source to destination.

```lua
local ok, err = M.copy_file("/path/src.png", "/path/dst.png")
```

Two implementations:
1. **Neovim 0.10+**: `vim.system({ "cp", source, dest }, { text = true })`
2. **Fallback**: `vim.fn.system(string.format("cp %s %s", shellescape(src), shellescape(dest)))`

Returns `(true, nil)` on success, `(nil, error_message)` on failure.

Used by `images.move_image` to copy images into the note's `img/` directory.

---

## Image Directory Helpers

### `get_note_image_dir()`

```lua
local img_dir, img_subdir, note_parent_dir, note_stem = M.get_note_image_dir()
```

Returns based on the current buffer:
- `img_dir` — `<current_file_dir>/img/<slugified_stem>/` (e.g. `~/notes/img/my-note/`)
- `img_subdir` — the slugified stem (e.g. `my-note`)
- `note_parent_dir` — directory of the current file
- `note_stem` — current file's stem (before slugification)

### `markdown_image_link(alt_text, relative_path)`

```lua
M.markdown_image_link("Screenshot", "./img/my-note/scr.png")
→ "![Screenshot](./img/my-note/scr.png)"
```

Simple string interpolation for markdown image syntax.

---

## Usage Across Modules

| Function | Called By | Purpose |
|----------|-----------|---------|
| `slugify` | notes, link, images, log | Filename/dirname generation |
| `get_git_dir` | notes (via utils auto-title) | Contextual title derivation |
| `get_note_title` | notes | Auto-title when no title given |
| `copy_file` | images | Copy image to note's img dir |
| `get_note_image_dir` | images | Determine image destination |
| `markdown_image_link` | images | Insert markdown image reference |