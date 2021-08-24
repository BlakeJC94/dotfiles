local lspconfig = require 'lspconfig'
local lspsaga = require 'lspsaga'
-- local lsp_status = require 'lsp-status'
local lspkind = require 'lspkind'
local lsp = vim.lsp
local buf_keymap = vim.api.nvim_buf_set_keymap
local cmd = vim.cmd

local util = require('lspconfig/util')
local path = util.path

-- use project .venv if available
local function get_python_path(workspace)
  -- Find and use virtualenv via poetry in workspace directory.
  local match = vim.fn.glob(path.join(workspace, 'poetry.lock'))
  if match ~= '' then
    local venv = vim.fn.trim(vim.fn.system('poetry env info -p'))
    return path.join(venv, 'bin', 'python')
  end

  -- Fallback to system Python.
  return vim.fn.exepath('python3') or vim.fn.exepath('python') or 'python'
end

-- LSP Kind (symbols)
lspkind.init {}

-- LSP Signature config
require('lsp_signature').setup{
  bind = false,
  use_lspsaga = true,
}

-- LSP Saga
lspsaga.init_lsp_saga {
  error_sign = "",
  warn_sign = "",
  hint_sign = "",
  infor_sign = "",
  max_preview_lines = 30,
  finder_action_keys = {
  open = 'o', vsplit = 's',split = 'i',quit = {'q', "<esc>"},scroll_down = '<C-f>', scroll_up = '<C-b>' -- quit can be a table
  },
  code_action_keys = {
    quit = {'q', "<esc>"},exec = '<CR>'
  },
  rename_action_keys = {
    quit = {'<C-c>', "<esc>"},exec = '<CR>'  -- quit can be a table
  },
}

local keymap_opts = { noremap = true, silent = true }
local function on_attach(client)

  -- Attach LSP Signature
  require('lsp_signature').on_attach({
    bind = false,
    use_lspsaga = true,
  })

  -- buf_keymap(0, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', keymap_opts)
  -- buf_keymap(0, "n", "gf", ":Lspsaga lsp_finder<CR>", keymap_opts)  -- LSP Finder
  buf_keymap(0, 'n', 'gd', '<cmd>lua require"telescope.builtin".lsp_definitions()<CR>', keymap_opts)
  -- code actions
  buf_keymap(0, "n", "<leader>ca", ":Lspsaga code_action<CR>", keymap_opts)
  buf_keymap(0, "v", "<leader>ca", ":Lspsaga range_code_action<CR>", keymap_opts)

  buf_keymap(0, "n", "K", ":Lspsaga hover_doc<CR>", keymap_opts)  -- hover
  -- buf_keymap(0, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)  -- hover

  -- scroll down hover doc or scroll in definition preview
  buf_keymap(0, "n", "<C-f>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", keymap_opts)
  buf_keymap(0, "n", "<C-b>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", keymap_opts)

  -- buf_keymap(0, "n", "gs", ":Lspsaga signature_help<CR>", keymap_opts)  -- signature help
  buf_keymap(0, "n", "<leader>rf", ":Lspsaga rename<CR>", keymap_opts)  -- LSP rename (refactor)
  buf_keymap(0, "n", "gp", ":Lspsaga preview_definition<CR>", keymap_opts)  -- Preview Definition
  buf_keymap(0, "n", "<leader>sd", ":Lspsaga show_line_diagnostics<CR>", keymap_opts)  -- Show Line Diagnostics
  buf_keymap(0, 'n', 'gTD', '<cmd>lua vim.lsp.buf.type_definition()<CR>', keymap_opts)
  buf_keymap(0, 'n', 'gf', '<cmd>lua require"telescope.builtin".lsp_references()<CR>', keymap_opts)
  -- Diagnostic Navigation
  buf_keymap(0, "n", "]e", ":Lspsaga diagnostic_jump_next<CR>", keymap_opts)
  buf_keymap(0, "n", "[e", ":Lspsaga diagnostic_jump_prev<CR>", keymap_opts)

  -- format, if LSP supports it
  if client.resolved_capabilities.document_formatting then
        vim.cmd [[augroup Format]]
        vim.cmd [[autocmd! * <buffer>]]
        vim.cmd [[autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting()]]
        vim.cmd [[augroup END]]
    end

  cmd 'augroup lsp_aucmds'
  if client.resolved_capabilities.document_highlight == true then
    cmd 'au CursorHold <buffer> lua vim.lsp.buf.document_highlight()'
    cmd 'au CursorMoved <buffer> lua vim.lsp.buf.clear_references()'
  end

  -- cmd 'au CursorHold,CursorHoldI <buffer> lua require"nvim-lightbulb".update_lightbulb {sign = {enabled = false}, virtual_text = {enabled = true, text = ""}, float = {enabled = false, text = "", win_opts = {winblend = 100, anchor = "NE"}}}'
  cmd 'augroup END'
end

-- local settings for Lua LSP
local sumneko_root_path = vim.fn.stdpath('cache')..'/lua-language-server'
local sumneko_binary = sumneko_root_path.."/bin/Linux/lua-language-server"

-- linter/formatter configs
local black = require "config/efm/black"
local flake8 = require "config/efm/flake8"
local isort = require "config/efm/isort"
local prettier = require "config/efm/prettier"

-- TODO: fix html, css, json servers
-- TODO: setup dockerls and ansiblels

local servers = {
  -- bashls = {},
  yamlls = {
    cmd = { "yaml-language-server", "--stdio" },
  },
  cssls = { },
  html = { filetypes = { "html", "htmldjango" } },
  jsonls = { cmd = { 'vscode-json-languageserver', '--stdio' } },
  -- jedi_language_server = {
  --   root_dir = function(fname)
  --       local root_files = {
  --       'pyproject.toml',
  --       'setup.py',
  --       'setup.cfg',
  --       'requirements.txt',
  --       'Pipfile',
  --     }
  --     return util.root_pattern(unpack(root_files))(fname) or util.find_git_ancestor(fname) or util.path.dirname(fname)
  --   end
  -- },
  pyright = {
    disableOrganizeImports = true,
    settings = {
        python = {
          analysis = {
            typeCheckingMode = "off",
            autoImportCompletions = true,
          },
      },
    },
    on_init = function(client)
      client.config.settings.python.pythonPath = get_python_path(client.config.root_dir)
    end
  },
  efm = {
    init_options = {documentFormatting = true},
    root_dir = vim.loop.cwd,
    settings = {
      rootMarkers = {".git/", "pyproject.toml", "poetry.lock"},
      languages = {
        python = {black, flake8, isort},
        html = {prettier},
        json = {prettier},
        css = {prettier},
        javascript = {prettier},
        yaml = {prettier},
        markdown = {prettier},
      }
    }
  },
  sumneko_lua = {
    cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
    settings = {
      Lua = {
        diagnostics = { globals = { 'vim' } },
        runtime = { version = 'LuaJIT', path = vim.split(package.path, ';') },
        workspace = {
          library = {
            [vim.fn.expand '$VIMRUNTIME/lua'] = true,
            [vim.fn.expand '$VIMRUNTIME/lua/vim/lsp'] = true,
          },
        },
      },
    },
  },
}

-- local snippet_capabilities = vim.lsp.protocol.make_client_capabilities()
-- snippet_capabilities.textDocument.completion.completionItem.snippetSupport = true
-- snippet_capabilities.textDocument.completion.completionItem.resolveSupport = {
--   properties = { 'documentation', 'detail', 'additionalTextEdits' },
-- }

for server, config in pairs(servers) do
  if type(config) == 'function' then
    config = config()
  end
  config.on_attach = on_attach
  -- config.capabilities = vim.tbl_deep_extend(
  --   'keep',
  --   config.capabilities or {},
  --   -- snippet_capabilities,
  --   -- lsp_status.capabilities
  -- )
  lspconfig[server].setup(config)
end
