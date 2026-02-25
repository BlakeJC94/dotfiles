return {
    "https://github.com/chrisgrieser/nvim-various-textobjs",
    opts = { keymaps = { useDefaults = false } },
    keys = {
        { "av", '<cmd>lua require("various-textobjs").subword("outer")<CR>', mode = { "o", "x" } },
        { "iv", '<cmd>lua require("various-textobjs").subword("inner")<CR>', mode = { "o", "x" } },
    },
}

