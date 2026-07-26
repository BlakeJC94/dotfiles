return {
    dir = vim.fn.stdpath("config") .. "/lua/local/blog",
    lazy = false,
    opts = {
        blog_content_dir = vim.fn.expand("~/Workspace/repos/blog/content"),
    },
}
