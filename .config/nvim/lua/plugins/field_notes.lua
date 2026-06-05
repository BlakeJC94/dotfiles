return {
    dir = vim.fn.stdpath("config") .. "/plugin/field-notes",
    lazy = false,
    opts = {
        field_notes_vert = true,
        field_notes_dir = vim.fn.expand("~/Workspace/field-notes"),
        blog_content_dir = vim.fn.expand("~/Workspace/repos/blog/content"),
    },
    keys = {
        { "<Leader>n", ":Note<CR>" },
        { "<Leader>N", ":Notes<CR>" },
    },
}
