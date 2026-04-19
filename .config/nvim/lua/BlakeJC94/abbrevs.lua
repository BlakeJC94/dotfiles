local M = {}

-- Setup insert mode abbreviations for snippets
M.setup_snippets = function()
    -- Date/time snippets
    vim.cmd([[iabbrev <expr> @@D strftime('%Y-%m-%d %a')]])
    vim.cmd([[iabbrev <expr> @@T strftime('%Y-%m-%dT%T%z')[:21] . ':00']])

    vim.cmd([[inoreabbrev <expr> xxtoday "strftime(\"%Y-%m-%d %a\", localtime() + (0 * 86400))"]])
    vim.cmd([[inoreabbrev <expr> xxyesterday strftime("%Y-%m-%d %a", localtime() + (-1 * 86400))]])
    vim.cmd([[inoreabbrev <expr> xxtomorrow strftime("%Y-%m-%d %a", localtime() + (1 * 86400))]])

    -- UUID generator
    vim.cmd([[inoreabbrev <expr> ,u system('uuidgen')->trim()->tolower()]])

    -- TODO markers
    vim.cmd([[inoreabbrev rbm # TODO: remove before merging]])
    vim.cmd([[inoreabbrev cbm # TODO: change before merging]])
    vim.cmd([[inoreabbrev ubm # TODO: uncomment before merging]])

    -- Expand `%%` as current filename in command mode
    vim.keymap.set("c", "%%", function()
        return vim.fn.getcmdtype() == ":" and vim.fn.expand("%:h") .. "/" or "%%"
    end, { expr = true })
end

-- Setup command mode abbreviations for common typos
M.setup_command_typos = function()
    vim.cmd([[cnoreabbrev W! w!]])
    vim.cmd([[cnoreabbrev Q! q!]])
    vim.cmd([[cnoreabbrev Qall! qall!]])
    vim.cmd([[cnoreabbrev Wq wq]])
    vim.cmd([[cnoreabbrev Wa wa]])
    vim.cmd([[cnoreabbrev wQ wq]])
    vim.cmd([[cnoreabbrev WQ wq]])
    vim.cmd([[cnoreabbrev W w]])
    vim.cmd([[cnoreabbrev Q q]])
    vim.cmd([[cnoreabbrev Qa qa]])
    vim.cmd([[cnoreabbrev Qall qall]])
end

return M
