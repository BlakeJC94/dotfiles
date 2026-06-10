return {
    "https://gitlab.com/BlakeJC/llm.nvim",
    cmd = {
        "LLM",
        "LLMToggle",
        "LLMOpen",
        "LLMClose",
        "LLMStop",
    },
    opts = {
        autoscroll = false,
        split = {
            direction = "horizontal",
            size = 14,
            position = "bottom",
        },
    },
    keys = {
        {
            "<Leader>S",
            ":LLM ",
            mode = { "n", "v" },
        },
        {
            "<Leader>s",
            ":LLMToggle<CR>",
            mode = "n",
        },
    },
}
