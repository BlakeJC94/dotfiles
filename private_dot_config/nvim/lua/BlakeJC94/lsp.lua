local M = {}

local function get_lspconfigs()
    return {
        {
            "luals",
            opts = {
                cmd = { "lua-language-server" },
                filetypes = { "lua" },
                root_markers = {
                    ".emmyrc.json",
                    ".luarc.json",
                    ".luarc.jsonc",
                    ".luacheckrc",
                    ".stylua.toml",
                    "stylua.toml",
                    "selene.toml",
                    "selene.yml",
                },
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
                settings = {
                    Lua = {
                        codeLens = { enable = true },
                        hint = { enable = true, semicolon = "Disable" },
                    },
                },
            },
        },
        {
            "stylua",
            opts = {
                cmd = { "stylua", "--lsp" },
                filetypes = { "lua" },
                root_markers = { ".stylua.toml", "stylua.toml", ".editorconfig" },
            },
        },
        {
            "pylsp",
            opts = {
                cmd = { "pylsp" },
                filetypes = { "python" },
                root_markers = {
                    "pyproject.toml",
                    "setup.py",
                    "setup.cfg",
                    "requirements.txt",
                    "Pipfile",
                    ".git",
                },
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
            "ruff", -- A Language Server Protocol implementation for Ruff, an extremely fast Python linter and code formatter, written in Rust.
            opts = {
                cmd = { "ruff", "server" },
                filetypes = { "python" },
                root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
                -- init_options = {
                settings = {
                    showSyntaxErrors = false,
                    organizeImports = true,
                    fixAll = true,
                },
                -- },
            },
        },
        {
            "rumdl",
            opts = {
                cmd = { "rumdl", "server" },
                filetypes = { "markdown" },
                root_markers = { ".git" },
            },
        },
        {
            "air", -- Air is an R formatter and language server, written in Rust.
            opts = {
                cmd = { "air", "language-server" },
                filetypes = { "r" },
                root_markers = { "air.toml", ".air.toml", ".git" },
            },
        },
        {
            "taplo", -- Language server for Taplo, a TOML toolkit.
            opts = {
                cmd = { "taplo", "lsp", "stdio" },
                filetypes = { "toml" },
                root_markers = { ".taplo.toml", "taplo.toml", ".git" },
            },
        },
        {
            "terraformls",
            opts = {
                cmd = { "terraform-ls", "serve" },
                filetypes = { "terraform", "terraform-vars" },
                root_markers = { ".terraform", ".git" },
            },
        },
        {
            "sqruff",
            opts = {
                cmd = { "sqruff", "lsp" },
                filetypes = { "sql" },
                root_markers = { ".sqruff", ".git" },
            },
        },
        {
            "marksman", -- Marksman is a Markdown LSP server providing completion, cross-references, diagnostics, and more.
            opts = {
                cmd = { "marksman", "server" },
                filetypes = { "markdown", "markdown.mdx" },
                root_markers = { ".marksman.toml", ".git" },
            },
        },
    }
end

M.set_lspconfigs = function()
    local lspconfigs = get_lspconfigs()
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

return M
