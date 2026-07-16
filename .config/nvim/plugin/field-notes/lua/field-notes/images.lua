local utils = require('field-notes.utils')
local M = {}

function M.move_image(target_image_path)
  if not target_image_path or #target_image_path == 0 then
    print("Error: Target image path required")
    return
  end

  local target_path = vim.fn.expand(target_image_path)

  if vim.fn.filereadable(target_path) == 0 then
    print("Error: Target image file does not exist: " .. target_path)
    return
  end

  local target_stem = vim.fn.fnamemodify(target_path, ':t:r')
  local target_ext = vim.fn.fnamemodify(target_path, ':e')

  local dest_dir, img_subdir = utils.get_note_image_dir()

  if vim.fn.isdirectory(dest_dir) == 0 then
    vim.fn.mkdir(dest_dir, 'p')
  end

  local slugified_target_stem = utils.slugify(target_stem)
  local dest_filename = slugified_target_stem .. '.' .. target_ext
  local dest_path = dest_dir .. '/' .. dest_filename

  local ok, copy_error = utils.copy_file(target_path, dest_path)
  if not ok then
    print("Error copying file: " .. copy_error)
    return
  end

  local relative_path = './img/' .. img_subdir .. '/' .. dest_filename
  local markdown_text = utils.markdown_image_link(target_stem, relative_path)
  vim.fn.append(vim.fn.line('.'), markdown_text)

  print("Image moved to: " .. dest_path)
end

return M
