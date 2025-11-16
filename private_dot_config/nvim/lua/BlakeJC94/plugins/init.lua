local M = {}

-- Get the path to your plugins directory
local plugin_dir = vim.fn.stdpath("config") .. "/lua/BlakeJC94/plugins/"

-- Iterate over all .lua files in that directory
for _, file in ipairs(vim.fn.glob(plugin_dir .. "*.lua", true, true)) do
    -- Extract the filename without extension
    local name = file:match("([^/]+)%.lua$")
    if name ~= "init" then  -- skip init.lua
        -- Build the module path
        local module = "BlakeJC94.plugins." .. name
        M[name] = require(module)
    end
end

return M
