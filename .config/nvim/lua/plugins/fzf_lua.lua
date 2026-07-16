return {
    "https://github.com/ibhagwan/fzf-lua",
    lazy = false,
    cmd = "FzfLua",
    opts = {
        fzf_bin = "sk",
        winopts = { border = "none" },
        grep = { hidden = true },
        files = { raw_cmd = vim.env.SKIM_DEFAULT_COMMAND },
    },
    keys = {
        {
            "<C-S-s>",
            "i<C-g>u<Esc>[s:FzfLua spell_suggest<CR>",
            remap = false,
        },
        {
            "<C-S-s>",
            "<C-g>u<Esc>[s:FzfLua spell_suggest<CR>",
            mode="i",
            remap = false,
        },
        { "z=", [[v:count ? v:count . 'z=' : ':FzfLua spell_suggest<CR>']], expr = true },
        { "<C-r><C-r>", "<cmd>FzfLua registers<CR>", mode = "i" },
        { "<Leader><BS>", "<cmd>FzfLua files<CR>", mode = "n" },
        { "<Leader><CR>", "<cmd>FzfLua buffers<CR>", mode = "n" },
        { "<Leader>ff", "<cmd>FzfLua resume<CR>", mode = "n" },
        { "<Leader>fF", "<cmd>FzfLua<CR>", mode = "n" },
        { "<Leader>fd", ":FzfLua lsp_workspace_diagnostics<CR>" },
        { "<Leader>fD", ":FzfLua lsp_document_diagnostics<CR>" },
        { "<Leader>fr", ":FzfLua lsp_references<CR>" },
        { "<Leader>fv", ":FzfLua lsp_document_symbols<CR>" },
        { "<Leader>fa", ":FzfLua lsp_code_actions<CR>" },
        { "<Leader>fo", ":FzfLua oldfiles cwd_only=true<CR>" }, -- Recently changed files
        { "<Leader>fO", ":FzfLua oldfiles<CR>" }, -- Recently changed files
        { "<Leader>f/", ":FzfLua lgrep_curbuf<CR>" },
        { "<Leader>fg", ":FzfLua live_grep_native<CR>" }, -- Jumping with livegrep
        { "<Leader>fh", ":FzfLua help_tags<CR>" },
        { "<Leader>fH", ":FzfLua man_pages<CR>" },
        { "<Leader>fq", ":FzfLua quickfix<CR>" },
        { "<Leader>fl", ":FzfLua loclist<CR>" },
    },
    config = function(_, opts)
        require("fzf-lua").setup(opts)

        vim.api.nvim_create_user_command("Notes", function(opts)
            local notes = require("field-notes")
            local dir = require("field-notes.config").get("field_notes_dir")
            require("fzf-lua").files({
                cwd = dir,
                cmd = "ls -1t",
                actions = {
                    ["default"] = function(selected)
                        if not selected or #selected == 0 then
                            return
                        end
                        local stem = selected[1]:gsub("%.md$", "")
                        notes.open_note(opts.bang, stem)
                    end,
                },
            })
        end, {
            bang = true,
            desc = "Browse field notes",
        })
    end,
}
