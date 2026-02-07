local field_notes = require('field-notes')

-- Note commands
vim.api.nvim_create_user_command('Note', function(opts)
  field_notes.open_note(opts.bang, opts.args)
end, {
  nargs = '*',
  bang = true,
  desc = 'Open or create a field note',
})

vim.api.nvim_create_user_command('Notes', function(opts)
  field_notes.open_notes_dir(opts.bang)
end, {
  bang = true,
  desc = 'Open the field notes directory',
})

-- Log commands
vim.api.nvim_create_user_command('Log', function(opts)
  local offset = tonumber(opts.args) or 0
  local timestamp = os.time()
    + (offset * 7 * 86400)
    - ((os.date('%u', os.time()) - 1) * 86400)
  local title = os.date('%Y-%W: %b %d', timestamp)
  field_notes.open_note(opts.bang, title)
end, {
  nargs = '?',
  bang = true,
  desc = 'Open weekly log note',
})

vim.api.nvim_create_user_command('ThisWeek', function(opts)
  vim.cmd((opts.bang and 'Note!' or 'Note') .. ' 0')
end, {
  bang = true,
  desc = 'Open this week log',
})

vim.api.nvim_create_user_command('NextWeek', function(opts)
  vim.cmd((opts.bang and 'Note!' or 'Note') .. ' 1')
end, {
  bang = true,
  desc = 'Open next week log',
})

vim.api.nvim_create_user_command('LastWeek', function(opts)
  vim.cmd((opts.bang and 'Note!' or 'Note') .. ' -1')
end, {
  bang = true,
  desc = 'Open last week log',
})

-- Utility commands
vim.api.nvim_create_user_command('Asciiflow', function()
  vim.fn.system('open https://asciiflow.com/')
end, {
  nargs = '*',
  desc = 'Open Asciiflow in browser',
})

vim.api.nvim_create_user_command('Diagram', function(opts)
  field_notes.new_diagram(opts.args)
end, {
  nargs = '*',
  desc = 'Create a new diagram',
})

vim.api.nvim_create_user_command('Image', function(opts)
  field_notes.move_image(opts.args)
end, {
  nargs = 1,
  complete = 'file_in_path',
  desc = 'Move image to structured directory',
})

vim.api.nvim_create_user_command('Slugify', function(opts)
  print(field_notes.slugify(opts.args))
end, {
  nargs = '*',
  desc = 'Convert text to slug format',
})

vim.api.nvim_create_user_command('Link', function(opts)
  local pos = vim.fn.getpos('.')
  local cword = vim.fn.expand('<cWORD>')
  local escaped_cword = cword:gsub('([/\\])', '\\%1')
  local escaped_args = opts.args:gsub('([/\\])', '\\%1')
  vim.cmd('s/' .. escaped_cword .. '/[' .. escaped_cword .. '](' .. escaped_args .. ')/')
  vim.fn.setpos('.', pos)
end, {
  nargs = 1,
  desc = 'Link word under cursor',
})

-- Blog commands
vim.api.nvim_create_user_command('BlogHeader', function()
  field_notes.blog_header()
end, {
  desc = 'Add Hugo front matter to blog post',
})

vim.api.nvim_create_user_command('BlogWrite', function(opts)
  field_notes.blog_write(opts.args)
end, {
  nargs = 1,
  desc = 'Write blog post to content directory',
})

-- Rename command
vim.api.nvim_create_user_command('RenameNote', function()
  field_notes.rename_note()
end, {
  desc = 'Rename note based on heading',
})
