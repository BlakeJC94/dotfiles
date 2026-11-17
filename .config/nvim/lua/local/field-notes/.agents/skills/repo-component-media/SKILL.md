---
name: repo-component-media
description: Change `:NoteImage`, image file copying, image directory naming, or generated Markdown image links in field-notes.nvim. Use for `lua/field-notes/images.lua` and its utility helpers.
---

# Image import

## Responsibility

`lua/field-notes/images.lua` implements the `:NoteImage <path>` flow. It validates and expands the input path, copies the image beside the note under an `img/<note-slug>/` directory, and inserts a Markdown image link.

## Current behavior

- The source path is expanded and must be readable.
- The destination directory and subdirectory name come from `utils.get_note_image_dir()`, based on the current buffer's parent directory and filename stem.
- The copied filename is the slugified source basename (without its extension) plus the original extension.
- Copy errors are reported and stop link insertion.
- On success, the module appends a Markdown image link after the current line. The relative link format is `./img/<note-slug>/<filename>`.

## Relationships

- `notes.lua` registers the `:NoteImage` command.
- `utils.lua` provides destination path construction, copying, slugification, and Markdown image syntax.
- `config.lua` does not determine this destination; it is based on the active buffer path.

## Source of truth

Read `lua/field-notes/images.lua` and the related helpers in `lua/field-notes/utils.lua`.
