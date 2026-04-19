vim.api.nvim_create_user_command('DotPull', '!chezmoi update', {})
vim.api.nvim_create_user_command('DotPush', '!chezmoi git sync', {})


local function add_changes_to_dotfiles()
  local current_file = vim.fn.expand('%')
  local managed_result = vim.fn.systemlist('chezmoi managed ' .. vim.fn.shellescape(current_file))
  local diff_result = vim.fn.systemlist('chezmoi diff ' .. vim.fn.shellescape(current_file))

  if not vim.tbl_isempty(managed_result) and not vim.tbl_isempty(diff_result) then
    vim.fn.system('chezmoi re-add')
  end
end

local add_changes_group = vim.api.nvim_create_augroup('add_changes_to_dotfiles', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = add_changes_group,
  pattern = '*',
  callback = add_changes_to_dotfiles,
})


local function apply_changes_from_dotfiles()
  local target_path = vim.fn.systemlist('chezmoi target-path ' .. vim.fn.shellescape(vim.fn.expand('%')))
  if not vim.tbl_isempty(target_path) then
    vim.fn.system('chezmoi apply ' .. vim.fn.shellescape(target_path[1]))
    vim.cmd('redraw!')
    print('Applied from dotfiles')
  end
end

local apply_changes_group = vim.api.nvim_create_augroup('apply_changes_from_dotfiles', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = apply_changes_group,
  pattern = '~/.local/share/chezmoi/*',
  callback = apply_changes_from_dotfiles,
})


local function dotfiles_set_filetype()
  local realpath = vim.fn.trim(vim.fn.system('chezmoi target-path ' .. vim.fn.shellescape(vim.fn.expand('%:p'))))
  vim.cmd('setfiletype ' .. vim.fn.fnameescape(vim.fn.fnamemodify(realpath, ':t')))
end

local dotfiles_filetype_group = vim.api.nvim_create_augroup('dotfiles_set_filetype', { clear = true })
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = dotfiles_filetype_group,
  pattern = '~/.local/share/chezmoi/*',
  callback = dotfiles_set_filetype,
})
