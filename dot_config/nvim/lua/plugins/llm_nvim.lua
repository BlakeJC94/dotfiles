return {
    "https://github.com/BlakeJC94/llm.nvim",
    cmd = {
        "LLM",
        "LLMToggle",
        "LLMOpen",
        "LLMClose",
        "LLMStop",
    },
    opts = {
        autoscroll = false,
        llm_path = "~/.local/bin/lm",
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
