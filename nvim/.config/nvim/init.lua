-- disable built_in plugins --
local disabled_built_ins = {
  'gzip',
  'man',
  'shada_plugin',
  'tarPlugin',
  'tar',
  'zipPlugin',
  'zip',
  'netrwPlugin',
  'tutor_mode_plugin',
  'remote_plugins',
  'spellfile_plugin',
  '2html_plugin'
}

for _, i in pairs(disabled_built_ins) do
  vim.g['loaded_' .. i] = 1
end

-- detect if we are on Windows and set global variable
if (vim.loop.os_uname().sysname == "Windows_NT") then
  vim.g.windows = true
else
  vim.g.windows = false
end

require("plugins")

require("settings").load_options()

require("settings").load_commands()

require "keymappings"
