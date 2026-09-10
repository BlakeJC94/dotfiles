local M = {}

local cmd_history = {}

-- Prefix-matching command-line history search
-- direction: -1 for older entries (Up), 1 for newer entries (Down)
M.history_search = function(direction)
    local kind = vim.fn.getcmdtype()
    local line = vim.fn.getcmdline()
    local state = cmd_history[kind]

    if not state or line ~= state.value then
        state = {
            prefix = line,
            index = direction < 0 and vim.fn.histnr(kind) + 1 or 0,
        }
    end

    local start = state.index + direction
    local stop = direction < 0 and 1 or vim.fn.histnr(kind)

    for i = start, stop, direction do
        local entry = vim.fn.histget(kind, i)

        if entry:sub(1, #state.prefix) == state.prefix then
            state.index = i
            state.value = entry
            cmd_history[kind] = state
            vim.fn.setcmdline(entry)
            vim.fn.setcmdpos(#entry + 1)
            return ""
        end
    end

    -- Going down past the newest match: remove the completion and
    -- return to the original text from before the first <Up>
    if direction > 0 then
        state.index = vim.fn.histnr(kind) + 1
        state.value = state.prefix
        cmd_history[kind] = state
        vim.fn.setcmdline(state.prefix)
        vim.fn.setcmdpos(#state.prefix + 1)
    end

    return ""
end

return M
