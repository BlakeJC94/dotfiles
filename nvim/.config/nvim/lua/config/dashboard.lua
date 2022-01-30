local M = {}

M.setup = function()
  -- vim.g.dashboard_disable_at_vimenter = 0
  local default_project_dir = "$HOME/code/python/"

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
      -- a = {
      --   description = { "  New Python CLI Project  " },
      --   command = ("TermExec cmd='cookiecutter cli -o %s' direction='float'"):format(default_project_dir),
      -- },
      -- b = {
      --   description = { "  New Flask Project       " },
      --   command = "",
      -- },
      -- c = {
      --   description = { "  REST Client             "},
      --   command = ":e $HOME/code/rest/README.md | :NvimTreeToggle"
      -- },
      -- d = {
      --   description = { "..........................."},
      --   command = "",
      -- },
      a = {
        description = { "  New File                " },
        command = "DashboardNewFile",
      },
      b = {
        description = { "  Find File               " },
        command = "Telescope find_files",
      },
      c = {
        description = { "  Recently Used Files     " },
        command = "Telescope oldfiles",
      },
      d = {
        description = { "  Settings                " },
        command = ":e " .. "$MYVIMRC | :NvimTreeToggle"
      },
    }

  vim.g.dashboard_custom_footer = { ("Neovim loaded %s plugins"):format(require("utils").loaded_plugins()) }


end

return M
