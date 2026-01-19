-- TODO Add wezterm namespace to luals
return function()
    vim.diagnostic.config({
        virtual_text = false,
        signs = false,
        underline = true,
        update_in_insert = false,
        severity_sort = false,
    })
    local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
    for sign_type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. sign_type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    -- Configure LSPs
    vim.lsp.config("lua_ls", {
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
    })
    vim.lsp.enable("lua_ls")

    vim.lsp.enable("stylua")

    vim.lsp.config("pylsp", {
        settings = {
            pylsp = {
                plugins = {
                    pyflakes = { enabled = false }, -- often loud and redundant
                    pylint = { enabled = false }, -- extremely noisy; disable unless needed
                    pycodestyle = { enabled = false }, -- style noise
                    mccabe = { enabled = false }, -- complexity warnings
                    yapf = { enabled = false },
                    pylsp_mypy = { enabled = false },
                },
            },
        },
    })
    vim.lsp.enable("pylsp")

    vim.lsp.config("ruff", {
        init_options = {
            settings = {
                showSyntaxErrors = false,
                organizeImports = true,
                fixAll = true,
            },
        },
    })
    vim.lsp.enable("ruff")

    vim.lsp.enable("sqruff")

    vim.lsp.enable('rumdl')

    vim.lsp.enable('marksman')

    vim.lsp.enable('harper_ls')

    vim.lsp.enable('jqls')

    vim.lsp.enable('air')

    vim.lsp.enable('taplo')

    vim.lsp.enable('terraformls')

    vim.lsp.enable('yamlls')

    vim.lsp.enable('bashls')
end
