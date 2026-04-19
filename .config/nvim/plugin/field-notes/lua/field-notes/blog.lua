local config = require('field-notes.config')
local M = {}

function M.blog_header()
  local title = ''
  local heading_line_num = 0
  local line_count = vim.fn.line('$')

  for line_num = 1, line_count do
    local line_content = vim.fn.getline(line_num)
    if line_content:match('^# ') then
      title = line_content:gsub('^# ', '')
      heading_line_num = line_num
      break
    end
  end

  if #title == 0 then
    print("Error: No heading found (line starting with '# ')")
    return
  end

  local date_str = os.date('%Y-%m-%dT%T%z')
  date_str = date_str:gsub('([+-]%d%d)(%d%d)$', '%1:%2')

  local front_matter = {
    '+++',
    "date = '" .. date_str .. "'",
    "draft = true",
    "title = '" .. title .. "'",
    '+++',
  }

  vim.fn.append(0, front_matter)

  local adjusted_line_num = heading_line_num + #front_matter
  vim.cmd(adjusted_line_num .. 'delete')

  print('Added blog header with title: ' .. title)
end

function M.blog_write(subdir)
  local target = vim.fn.expand(config.get('blog_content_dir')) .. '/' .. subdir .. '/' .. vim.fn.expand('%:t')

  if vim.fn.filereadable(target) == 1 then
    local choice = vim.fn.confirm("File already exists:\n" .. target .. "\nOverwrite?", "&Yes\n&No", 2)
    if choice ~= 1 then
      print('Aborted: file not written.')
      return
    end
  end

  vim.cmd('write ' .. vim.fn.fnameescape(target))
  vim.cmd('edit ' .. vim.fn.fnameescape(target))
  print('File written to: ' .. target)
  M.blog_header()
end

return M
