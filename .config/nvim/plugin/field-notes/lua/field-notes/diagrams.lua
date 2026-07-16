local utils = require('field-notes.utils')
local M = {}

function M.new_diagram(...)
  local args = {...}
  local title = table.concat(args, ' ')

  if #title == 0 then
    title = os.date('%Y_%m_%d_%H%M')
  end

  local dest_dir, img_subdir, dest_parent = utils.get_note_image_dir()
  local dest_filename = utils.slugify(title) .. '.svg'
  local dest_path = dest_dir .. '/' .. dest_filename

  if vim.fn.isdirectory(dest_dir) == 0 then
    vim.fn.mkdir(dest_dir, 'p')
  end

  local template_path = dest_parent .. '/templates/template.svg'

  local ok, copy_error = utils.copy_file(template_path, dest_path)
  if not ok then
    print('Error copying file: ' .. copy_error)
    return
  end

  local relative_path = './img/' .. img_subdir .. '/' .. dest_filename
  local markdown_text = utils.markdown_image_link(title, relative_path)
  vim.fn.append(vim.fn.line('.'), markdown_text)

  print('Created new canvas at: ' .. dest_path)
end

return M
