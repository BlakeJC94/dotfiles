local M = {}

-- Inserts a component in lualine_c at left section
-- local function ins_left(component)
--   table.insert(config.sections.lualine_c, component)
-- end

M.setup = function()
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
}


  require('lualine').setup({

    options = {
      icons_enabled = true,
      theme = 'auto',
      -- component_separators = {'', ''},
      -- section_separators = {'', ''},
      disabled_filetypes = {'dashboard', 'NvimTree', 'toggleterm'},
      always_divide_middle = true,
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diagnostics'},
      lualine_c = {'filename'},
      lualine_x = {lsp, 'encoding', 'fileformat', 'filetype'},
      lualine_y = {'progress'},
      lualine_z = {'location'}
    },
    inactive_sections = {
      -- lualine_a = {},
      -- lualine_b = {'diff'},
      -- lualine_c = {'filename'},
      -- lualine_x = {'location'},
      -- lualine_y = {},
      -- lualine_z = {}
    },
    tabline = {},
    extensions = {}
  })
end

return M
