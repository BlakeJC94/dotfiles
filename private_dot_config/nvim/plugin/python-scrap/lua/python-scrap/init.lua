local M = {}

-- Global variable to track last created PyScrap filename
M.last_filename = ''

-- Main PyScrap function
function M.pyscrap_function(bang, line1, line2, ...)
  local args = {...}
  
  -- Get the selected lines from the current buffer before switching
  local selected_lines = {}
  if line1 ~= line2 or line1 ~= vim.fn.line('.') then
    selected_lines = vim.fn.getline(line1, line2)
  end
  
  -- If no bang and no args, try to open last PyScrap file
  if not bang and #args == 0 and M.last_filename ~= '' then
    vim.cmd('split ' .. M.last_filename)
    -- If we have selected lines, copy them to the file
    if #selected_lines > 0 then
      vim.fn.setline(1, selected_lines)
    end
    return
  end
  
  -- Create new filename based on arguments or default
  local custom_name = 'scratch'
  if #args > 0 then
    custom_name = table.concat(args, '_')
  end
  local filename = vim.fn.getcwd() .. '/scrap/' .. custom_name .. '_' .. vim.fn.strftime('%Y-%m-%d-%H%M') .. '.py'
  
  -- Update last filename when creating new file
  M.last_filename = filename
  
  vim.cmd('split ' .. filename)
  
  -- If we have selected lines, copy them to the new file
  if #selected_lines > 0 then
    vim.fn.setline(1, selected_lines)
  end
end

-- PyScrap operator function
function M.pyscrap_operator(type)
  local saved_unnamed_register = vim.fn.getreg('"')
  
  if type == 'v' then
    vim.cmd("normal! `<v`>y")
  elseif type == 'char' then
    vim.cmd("normal! `[v`]y")
  elseif type == 'line' then
    vim.cmd("normal! '[V']y")
  else
    return
  end
  
  local selected_text = vim.split(vim.fn.getreg('"'), '\n')
  vim.fn.setreg('"', saved_unnamed_register)
  
  local filename = vim.fn.getcwd() .. '/scrap/scratch_' .. vim.fn.strftime("%Y-%m-%d-%H%M") .. '.py'
  vim.cmd('split ' .. filename)
  
  if #selected_text > 0 then
    vim.fn.setline(1, selected_text)
  end
end

-- DtoK function (Dictionary to Keyword arguments)
function M.dtok(line1, line2)
  vim.cmd(string.format('%d,%ds/^\\(\\s*\\)"\\(.*\\)"\\s*:\\s*\\(.*\\),\\s*$/\\1\\2=\\3,/', line1, line2))
end

-- KwtoD function (Keyword arguments to Dictionary)
function M.kwtod(line1, line2)
  vim.cmd(string.format('%d,%ds/^\\(\\s*\\)\\(.*\\)\\s*=\\s*\\(.*\\)\\s*$/\\1"\\2": \\3,/', line1, line2))
end

-- Create commands
vim.api.nvim_create_user_command('PyScrap', function(opts)
  local bang = opts.bang
  local line1 = opts.line1
  local line2 = opts.line2
  M.pyscrap_function(bang, line1, line2, unpack(opts.fargs))
end, {
  bang = true,
  range = true,
  nargs = '*',
})

vim.api.nvim_create_user_command('DtoK', function(opts)
  M.dtok(opts.line1, opts.line2)
end, {
  range = true,
})

vim.api.nvim_create_user_command('KwtoD', function(opts)
  M.kwtod(opts.line1, opts.line2)
end, {
  range = true,
})

-- Set up operator mappings
vim.keymap.set('n', '<Plug>PyScrapOperator', function()
  vim.o.operatorfunc = 'v:lua.require("python-scrap").pyscrap_operator'
  return 'g@'
end, { expr = true, silent = true })

vim.keymap.set('v', '<Plug>PyScrapOperator', function()
  M.pyscrap_operator(vim.fn.visualmode())
end, { silent = true })

-- Default mappings
vim.keymap.set('n', 'gS', '<Plug>PyScrapOperator', { remap = true })
vim.keymap.set('v', 'gS', '<Plug>PyScrapOperator', { remap = true })

return M
