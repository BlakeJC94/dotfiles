local M = {}

-- AIDEV-NOTE: resolves maven jar paths from Bazel's external cache for jdtls classpath
local function bazel_maven_jar_glob(root_dir)
    if not vim.uv.fs_stat(root_dir .. "/MODULE.bazel") then
        return nil
    end

    if vim.fn.executable("bazel") ~= 1 then
        return nil
    end

    local handle = io.popen("bazel info output_base 2>/dev/null", "r")
    if not handle then
        return nil
    end
    local output_base = handle:read("*l")
    handle:close()

    if not output_base or output_base == "" then
        return nil
    end

    return output_base .. "/external/rules_jvm_external*/v1/**/*.jar"
end

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
            "air", -- Air is an R formatter and language server, written in Rust.
            opts = {
                cmd = { "air", "language-server" },
                filetypes = { "r" },
                root_markers = { "air.toml", ".air.toml", ".git" },
            },
        },
        {
            "jdtls",
            opts = { -- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jdtls.lua#L74
                cmd = function(dispatchers, config)
                    local data_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace"

                    if config.root_dir then
                        data_dir = data_dir .. "/" .. vim.fn.fnamemodify(config.root_dir, ":p:h:t")
                    end

                    local get_jdtls_jvm_args = function()
                        local env = os.getenv("JDTLS_JVM_ARGS")
                        local args = {}
                        for a in string.gmatch((env or ""), "%S+") do
                            local arg = string.format("--jvm-arg=%s", a)
                            table.insert(args, arg)
                        end
                        return unpack(args)
                    end

                    local config_cmd = {
                        "jdtls",
                        "-data",
                        data_dir,
                        get_jdtls_jvm_args(),
                    }

                    return vim.lsp.rpc.start(config_cmd, dispatchers, {
                        cwd = config.cmd_cwd,
                        env = config.cmd_env,
                        detached = config.detached,
                    })
                end,
                filetypes = { "java" },
                root_markers = {
                    {
                        -- Multi-module projects
                        "mvnw", -- Maven
                        "gradlew", -- Gradle
                        "settings.gradle", -- Gradle
                        "settings.gradle.kts", -- Gradle
                        -- Use git directory as last resort for multi-module maven projects
                        -- In multi-module maven projects it is not really possible to determine what is the parent directory
                        -- and what is submodule directory. And jdtls does not break if the parent directory is at higher level than
                        -- actual parent pom.xml so propagating all the way to root git directory is fine
                        ".git",
                    },
                    {
                        -- Single-module projects
                        "build.xml", -- Ant
                        "pom.xml", -- Maven
                        "build.gradle", -- Gradle
                        "build.gradle.kts", -- Gradle
                    },
                },
                init_options = {},
                on_init = function(client)
                    local root_dir = client.config.root_dir
                    if not root_dir then
                        return
                    end

                    local jar_glob = bazel_maven_jar_glob(root_dir)
                    if not jar_glob then
                        return
                    end

                    client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
                        java = {
                            project = {
                                referencedLibraries = { include = { jar_glob } },
                            },
                        },
                    })
                    client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                end,
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
        local lsp_name = unpack(config)

        if config.opts then
            vim.lsp.config(lsp_name, config.opts)
        end

        vim.lsp.enable(lsp_name)
    end
end

return M
