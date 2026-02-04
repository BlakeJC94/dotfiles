local function get_lspconfigs()
    return {
        {
            "luals",
            opts = {
                on_init = function(client)
                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name
                        if
                            path ~= vim.fn.stdpath("config")
                            and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
                        then
                            return
                        end
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                        runtime = {
                            version = "LuaJIT",
                            path = { "lua/?.lua", "lua/?/init.lua" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            library = { vim.env.VIMRUNTIME },
                        },
                    })
                end,
                settings = { Lua = {} },
            },
        },
        { "stylua" },
        {
            "pylsp",
            opts = {
                settings = {
                    pylsp = {
                        plugins = {
                            jedi = { environment = vim.fn.getcwd() .. "/.venv" },
                            pyflakes = { enabled = false }, -- often loud and redundant
                            pylint = { enabled = false }, -- extremely noisy; disable unless needed
                            pycodestyle = { enabled = false }, -- style noise
                            mccabe = { enabled = false }, -- complexity warnings
                            yapf = { enabled = false },
                            pylsp_mypy = { enabled = false },
                        },
                    },
                },
            },
        },
        {
            "ruff",
            opts = {
                init_options = {
                    settings = {
                        showSyntaxErrors = false,
                        organizeImports = true,
                        fixAll = true,
                    },
                },
            },
        },
        { "sqruff" },
        { "rumdl" },
        { "marksman" },
        { "jqls" },
        { "air" },
        { "taplo" },
        { "terraformls" },
        { "yamlls" },
        { "bashls" },
    }
end

local function set_lspconfigs(lspconfigs)
    for _, config in pairs(lspconfigs) do
        lsp_name = unpack(config)

        -- if vim.fn.executable(lsp_name) == 0 then
        --     vim.notify(lsp_name .. " not found", vim.log.levels.WARN)
        -- end

        if config.opts then
            vim.lsp.config(lsp_name, config.opts)
        end

        vim.lsp.enable(lsp_name)
    end
end

return function()
    vim.diagnostic.config({
        virtual_text = false,
        signs = false,
        underline = true,
        update_in_insert = false,
        severity_sort = false,
    })

    local lspconfigs = get_lspconfigs()
    set_lspconfigs(lspconfigs)
end
