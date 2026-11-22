return {
    "https://github.com/saghen/blink.cmp",
    dependencies = { "https://github.com/rafamadriz/friendly-snippets" },
    version = "1.*",
    opts = {
        keymap = {
            ["<C-x>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-u>"] = { "scroll_documentation_up", "fallback" },
            ["<C-d>"] = { "scroll_documentation_down", "fallback" },
            ["<CR>"] = {
                function(cmp)
                    if cmp.snippet_active() then
                        return cmp.accept()
                    else
                        return cmp.select_and_accept()
                    end
                end,
                "snippet_forward",
                "fallback",
            },
            ["<S-CR>"] = { "snippet_backward", "fallback" },

            ["<Esc>"] = {
                function(cmp)
                    if cmp.is_menu_visible() then
                        return cmp.hide()
                    end
                end,
                "fallback",
            },
            ["<C-e>"] = { "cancel", "fallback" },

            ["<Tab>"] = {
                function(cmp)
                    if cmp.snippet_active() then
                        return cmp.accept()
                    else
                        return cmp.select_and_accept()
                    end
                end,
                "snippet_forward",
                "fallback",
            },
            ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
            ["<C-n>"] = { "select_next", "fallback_to_mappings" },

            ["<C-b>"] = { "scroll_documentation_up", "fallback" },
            ["<C-f>"] = { "scroll_documentation_down", "fallback" },

            ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
        },
        completion = {
            documentation = { auto_show = true },
            list = {
                selection = { preselect = true, auto_insert = false },
            },
        },
        cmdline = { enabled = false },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        fuzzy = { implementation = "lua" },
    },
    opts_extend = { "sources.default" },
}
