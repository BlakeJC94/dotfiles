return {
    "https://gitlab.com/blakejc/gitreview",
    lazy = false,
    dependencies = {
        "https://github.com/tpope/vim-fugitive",
        "https://github.com/ibhagwan/fzf-lua",
    },
    opts = {},
    config = function(_, opts)
        require("gitreview").setup(opts)

        -- AIDEV-NOTE: gitreview owns the file selector; fzf-lua just hosts the
        -- registered extension. Use :GitReviewPick or :FzfLua gitreview.
        local fzf = require("fzf-lua")
        fzf.register_extension("gitreview", function(o)
            o = fzf.config.normalize_opts(o, "gitreview")
            if not o then
                return
            end
            local state = require("gitreview.state").get()
            if not state then
                require("gitreview.util").notify("no active review")
                return
            end
            require("gitreview.diff").fzf_pick(state, fzf, o)
        end, {
            prompt = "GitReview> ",
        })
    end,
}
