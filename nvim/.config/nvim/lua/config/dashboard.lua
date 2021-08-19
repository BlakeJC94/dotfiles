local M = {}

dashboard_config = {
    search_handler = "telescope",
    custom_header = {
"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
"                                                     ",
"                                                     ",

      },
    custom_section = {
      -- a = {
      --   description = { "  New Project          " },
      --   command = "",
      -- },
      c = {
        description = { "  Find File          " },
        command = "Telescope find_files",
      },
      d = {
        description = { "  Recently Used Files" },
        command = "Telescope oldfiles",
      },
      -- e = {
      --   description = { "  Load Last Session  " },
      --   command = "SessionLoad",
      -- },
      f = {
        description = { "  Settings           " },
        command = ":e " .. "$MYVIMRC | :NvimTreeToggle"
      },
    },
}

M.setup = function()
  vim.g.dashboard_disable_at_vimenter = 0

  vim.g.dashboard_custom_header = dashboard_config.custom_header

  vim.g.dashboard_default_executive = dashboard_config.search_handler

  vim.g.dashboard_custom_section = dashboard_config.custom_section

end

return M
