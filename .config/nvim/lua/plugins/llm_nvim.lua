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
        template = "default",
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
            "<C-Tab>",
            ":LLMToggle<CR>",
            mode = "n",
        },
    },
}
