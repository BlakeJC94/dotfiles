local M = {}

M.setup = function()
  require'nvim-web-devicons'.setup {
    override = {
        py = {
          icon = "",
          color = "#FFD845",  -- change color to yellow
          name = "py",
        },
        css = {
          icon = "",
          color = "#3B7BF4",
          name = "css",
        },
        html = {
          icon = "",
          color = "#e34c26",
          name = "html",
        },
        Dockerfile = {
          icon = "",
          color = "#088DA5",
          name = "Dockerfile",
        },
        sql = {
          icon = "",
          color = "#ff409f",
          name = "sql",
        }
    }
}
end

return M
