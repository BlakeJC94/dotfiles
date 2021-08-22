local M = {}

M.setup = function()
  -- vim.g.dashboard_disable_at_vimenter = 0

  vim.g.dashboard_custom_header = {
"                                                     ",
"                                                     ",
"                                                     ",
"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
"                                                     ",
"                                                     ",
"                                                     ",
"                                                     ",

      }


  vim.g.dashboard_default_executive = "telescope"

  vim.g.dashboard_custom_section = {
      a = {
        description = { "  New Project             " },
        command = "",
      },
      b = {
        description = { "  Load Recent Session     " },
        command = ":lua require('session-lens').search_session()",
      },
      c = {
        description = { "  New File                " },
        command = "DashboardNewFile",
      },
      d = {
        description = { "  Find File               " },
        command = "Telescope find_files",
      },
      e = {
        description = { "  Recently Used Files     " },
        command = "Telescope oldfiles",
      },
      f = {
        description = { "  Settings                " },
        command = ":e " .. "$MYVIMRC | :NvimTreeToggle"
      },
    }


end

return M
