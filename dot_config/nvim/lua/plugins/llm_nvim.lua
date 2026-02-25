return {
    "https://github.com/BlakeJC94/llm.nvim",
    commands = {
        "LLM",
        "LLMToggle",
        "LLMOpen",
        "LLMClose",
        "LLMStop",
    },
    opts = {
        split = {
            direction = "horizontal",
            size = 14,
            position = "bottom",
        },
    },
    keys = {
        {
            "<Leader>s",
            ":LLM ",
            mode = { "n", "v" },
        },
        {
            "<Leader>S",
            ":LLMToggle<CR>",
            mode = "n",
        },
    },
}
