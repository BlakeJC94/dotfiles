local M = {}

-- Inserts a component in lualine_c at left section
-- local function ins_left(component)
--   table.insert(config.sections.lualine_c, component)
-- end

M.setup = function()
  local diags = {
    'diagnostics',
    sources = {'nvim_lsp'},
    symbols = {error = ' ', warn = ' ', info = ' '},
  }

  -- local git_diff = {
  --   'diff',
  --   symbols = {added = ' ', modified = '柳 ', removed = ' '},
  --   color_added = "#9ece6a",
  --   color_modified = "#ff9e64",
  --   color_red = "#f7768e",
  -- }

  -- local spacing = function()
  --   return '%='
  -- end

  -- Lsp server name
  local lsp = {
    function()
    local msg = '年'
    local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
    local clients = vim.lsp.get_active_clients()
    if next(clients) == nil then return msg end
    for _, client in ipairs(clients) do
      local filetypes = client.config.filetypes
      if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
        return '力 ' .. client.name
      end
    end
    return msg
  end,
  -- icon = '力',
  separator = nil,
  -- color = {fg = '#7dcfff'},
}


  require('lualine').setup({

    options = {
    icons_enabled = true,
    theme = 'tokyonight',
    component_separators = {'', ''},
    section_separators = {'', ''},
    disabled_filetypes = {'dashboard', 'NvimTree'}
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch'},
    lualine_c = {'filename', diags},
    lualine_x = {lsp, 'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },

})
end

return M
