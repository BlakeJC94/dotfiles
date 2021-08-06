local M = {}

devicons_config = {
  override = {
    py = {
      icon = "",
      color = "#FFD845",  -- change color to yellow
      name = "Python",
    },
    css = {
      icon = "",
      color = "#3B7BF4",
      name = "CSS",
    },
    html = {
      icon = "",
      color = "#FF7F50",
      name = "HTML",
    },
    Dockerfile = {
      icon = " ",
      color = "#088DA5",
      name = "Dockerfile",
    },
  },
}

M.setup = function()
  require("nvim-web-devicons").setup(devicons_config)
end

return M
