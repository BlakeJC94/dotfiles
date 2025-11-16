local M = {}

M.plugins = require("BlakeJC94.plugins")
M.functions = require("BlakeJC94.functions")

M.set_options = function(options)
    for k, v in pairs(options) do
        vim.opt[k] = v
    end
end

local bootstrap_package_manager = function()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable",
            lazypath,
        })
    end
    vim.opt.rtp:prepend(lazypath)
end

M.set_plugins = function(plugins)
    bootstrap_package_manager()
    pack = require("lazy")
    pack.setup(plugins)
end

M.set_mappings = function(maps)
    for _, map in pairs(maps) do
        local key, value = unpack(map)
        local opts = {}

        local mode = map.mode or "n"

        if map.silent == nil then
            opts.silent = true
        else
            opts.silent = map.silent
        end

        if map.noremap == nil then
            opts.noremap = true
        else
            opts.noremap = map.noremap
        end

        if map.nowait ~= nil then
            opts.nowait = map.nowait
        end
        if map.script ~= nil then
            opts.script = map.script
        end
        if map.expr ~= nil then
            opts.expr = map.expr
        end
        if map.unique ~= nil then
            opts.unique = map.unique
        end
        if map.desc ~= nil then
            opts.desc = map.desc
        end
        if map.buffer ~= nil then
            opts.buffer = map.buffer
        end

        vim.keymap.set(mode, key, value, opts)
    end
end

return M
