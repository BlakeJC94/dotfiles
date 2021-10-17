local M = {}

M.setup = function()
  require'nvim-web-devicons'.setup {
    override = {
        py = {
          icon = "",
          color = "#FFD845",  -- change color to yellow
          name = "Py",
        },
        css = {
          icon = "",
          color = "#3B7BF4",
          name = "CSS",
        },
        html = {
          icon = "",
          color = "#e34c26",
          name = "HTML",
        },
        Dockerfile = {
          icon = "",
          color = "#088DA5",
          name = "Dockerfile",
        },
        http = {
          icon = "",
          name = "http",
        },
        md = {
          icon = "",
          name = "markdown",
        }
    }
}
end

return M
