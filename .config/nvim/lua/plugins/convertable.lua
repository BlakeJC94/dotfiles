return {
    dir = vim.fn.stdpath("config") .. "/lua/local/convertable",
    opts = {},
    keys = {
        { "<C-t>", ":TableToggle<CR>", expr = true, mode = "v" },
        { "<C-t>", function()
            vim.o.operatorfunc = "v:lua.ToggleTableFormatOperator"
            return "g@"
        end,
        expr = true, mode = "n" },
    },
}
