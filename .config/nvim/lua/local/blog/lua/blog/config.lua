local M = {}

M.defaults = {
    blog_content_dir = vim.fn.expand("~/Workspace/repos/blog/content"),
}

M.options = {}

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get(key)
    return M.options[key] or M.defaults[key]
end

return M
