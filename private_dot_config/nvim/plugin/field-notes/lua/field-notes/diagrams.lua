local utils = require('field-notes.utils')
local M = {}

function M.new_diagram(...)
  local args = {...}
  local title = table.concat(args, ' ')

  if #title == 0 then
    title = os.date('%Y_%m_%d_%H%M')
  end

  local dest_parent = vim.fn.expand('%:p:h')
  local dest_stem = vim.fn.expand('%:t:r')

  local img_subdir = utils.slugify(dest_stem)
  local dest_dir = dest_parent .. '/img/' .. img_subdir
  local dest_filename = utils.slugify(title) .. '.svg'
  local dest_path = dest_dir .. '/' .. dest_filename

  if vim.fn.isdirectory(dest_dir) == 0 then
    vim.fn.mkdir(dest_dir, 'p')
  end

  local template_path = dest_parent .. '/templates/template.svg'

  local copy_cmd = string.format('cp "%s" "%s"', template_path, dest_path)
  local result = vim.fn.system(copy_cmd)
  if vim.v.shell_error ~= 0 then
    print('Error copying file: ' .. result)
    return
  end

  local relative_path = './img/' .. img_subdir .. '/' .. dest_filename
  local markdown_text = '![' .. title .. '](' .. relative_path .. ')'
  vim.fn.append(vim.fn.line('.'), markdown_text)

  print('Created new canvas at: ' .. dest_path)
end

return M
