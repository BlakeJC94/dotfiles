local M = {}

M.defaults = {
    field_notes_dir = vim.fn.expand("~/Workspace/field-notes"),
    field_notes_vert = true,
    field_notes_default_template = nil,
}

M.options = {}

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get(key)
    return M.options[key] or M.defaults[key]
end

return M
