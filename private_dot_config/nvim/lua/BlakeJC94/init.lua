M = {}

-- === Global Namespace Functions ===

M.custom_fold_text = function()
    local line = vim.fn.getline(vim.v.foldstart)

    local indent_str = string.rep(" ", vim.fn.indent(vim.v.foldstart - 1))
    local fold_str = indent_str .. line .. string.rep(" ", vim.bo.textwidth)

    local fold_size = vim.v.foldend - vim.v.foldstart + 1
    local fold_size_str = " (" .. fold_size .. ") "

    return string.sub(fold_str, 0, vim.bo.textwidth - #fold_size_str) .. fold_size_str
end

M.toggle_quickfix_list = function()
    local has_qf = #vim.fn.filter(vim.fn.getwininfo(), "v:val.quickfix") > 0

    if has_qf then
        pcall(vim.cmd.cclose)
    else
        local ok = pcall(vim.cmd.copen)
        if not ok then
            vim.notify("No quickfix list available", vim.log.levels.WARN)
        end
    end
end

M.toggle_local_list = function()
    local has_loc = #vim.fn.filter(vim.fn.getwininfo(), "v:val.loclist") > 0

    if has_loc then
        pcall(vim.cmd.lclose)
    else
        local ok = pcall(vim.cmd.lopen)
        if not ok then
            vim.notify("No location list available", vim.log.levels.WARN)
        end
    end
end

-- === Main Setup Function ===

M.setup = function(opts)
    local m = require("BlakeJC94")
    _G.BlakeJC94 = m

    -- Configure diagnostics
    vim.diagnostic.config({
        virtual_text = false,
        signs = false,
        underline = true,
        update_in_insert = false,
        severity_sort = false,
    })

    -- Setup UI/editor utilities
    local utils = require("BlakeJC94.utils")
    utils.set_custom_fold_text()
    utils.set_grep_rg_backend()
    utils.set_undo_maps()
    utils.set_arrow_maps()

    -- Load motions module and add functions to global namespace
    local motions = require("BlakeJC94.motions")
    m._reverse_lines = motions._reverse_lines
    m.reverse_op = motions.reverse_op
    m.reverse_vis = motions.reverse_vis
    m.sort_lines = motions.sort_lines
    motions.setup_reverse()
    motions.setup_sort()

    -- Setup autocommands
    local autocmds = require("BlakeJC94.autocmds")
    autocmds.setup_create_parent_dirs()
    autocmds.setup_trim_spaces()
    autocmds.setup_info_buffer_opts()
    autocmds.setup_jump_to_last_edit()

    -- Setup abbreviations
    local abbrevs = require("BlakeJC94.abbrevs")
    abbrevs.setup_snippets()
    abbrevs.setup_command_typos()

    -- Setup LSP
    local lsp = require("BlakeJC94.lsp")
    lsp.set_lspconfigs()

end

return M
