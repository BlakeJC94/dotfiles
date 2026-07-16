return {
    dir = vim.fn.stdpath("config") .. "/plugin/field-notes",
    lazy = false,
    opts = {
        field_notes_vert = true,
        field_notes_dir = vim.fn.expand("~/Workspace/field-notes"),
        field_notes_templates_dir = vim.fn.stdpath("config") .. "/plugin/field-notes/_templates",
    },
    keys = {
        { "<Leader>n", ":Note<CR>" },
    },
}
