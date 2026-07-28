return {
    dir = vim.fn.stdpath("config") .. "/lua/local/lists-md",
    config = function()
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "markdown",
            callback = function(event)
                vim.keymap.set({ "n", "i" }, "<C-.>", function()
                    require("lists-md").indent_item_right()
                end, { buffer = event.buf })

                vim.keymap.set({ "n", "i" }, "<C-,>", function()
                    require("lists-md").indent_item_left()
                end, { buffer = event.buf })

                vim.keymap.set({ "n", "i" }, "<C-;>", function()
                    require("lists-md").toggle_checkbox()
                end, { buffer = event.buf })

                vim.keymap.set({ "n", "i" }, "<CR>", function()
                    return require("lists-md").next_item()
                end, {
                    expr = true,
                    buffer = event.buf,
                })
            end,
        })
    end,
}
