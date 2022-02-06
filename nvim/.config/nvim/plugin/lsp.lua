local lspconfig = require('lspconfig')
-- local lspsaga = require('lspsaga')
-- local lspkind = require('lspkind')
-- local lsp = vim.lsp
local buf_keymap = vim.api.nvim_buf_set_keymap
local cmd = vim.cmd

local utils = require('utils')
local util = require('lspconfig.util')

-- LSP Signature config
-- require('lsp_signature').setup{
--   bind = false,
--   use_lspsaga = true,
--   hint_enable = false,
-- }

-- LSP Saga
-- lspsaga.init_lsp_saga {
--   use_saga_diagnostic_sign = true,
--   error_sign = " ",
--   warn_sign = " ",
--   hint_sign = " ",
--   infor_sign = " ",
--   max_preview_lines = 30,
--   finder_action_keys = {
--   open = 'o', vsplit = 's',split = 'i',quit = {'q', "<esc>"},scroll_down = '<C-f>', scroll_up = '<C-b>' -- quit can be a table
--   },
--   code_action_keys = {
--     quit = {'q', "<esc>"},exec = '<CR>'
--   },
--   rename_action_keys = {
--     quit = {'<C-c>', "<esc>"},exec = '<CR>'  -- quit can be a table
--   },
-- }


-- LSP Kind (symbols)
-- lspkind.init {}


local keymap_opts = { noremap = true, silent = true }
local function on_attach(client)

  -- Attach LSP Signature
  -- require('lsp_signature').on_attach({
  --   bind = false,
  --   use_lspsaga = true,
  --   hint_enable = false,
  -- })

  local signs = { Error = "", Warn = "", Hint = "", Info = "" }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl })
  end

  buf_keymap(0, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', keymap_opts)
  -- buf_keymap(0, "n", "gf", ":Lspsaga lsp_finder<CR>", keymap_opts)  -- LSP Finder
  buf_keymap(0, 'n', 'gd', '<cmd>lua require"telescope.builtin".lsp_definitions()<CR>', keymap_opts)
  -- code actions
  -- buf_keymap(0, "n", "<leader>ca", ":Lspsaga code_action<CR>", keymap_opts)
  -- buf_keymap(0, "v", "<leader>ca", ":Lspsaga range_code_action<CR>", keymap_opts)

  -- buf_keymap(0, "n", "K", ":Lspsaga hover_doc<CR>", keymap_opts)  -- hover
  buf_keymap(0, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)  -- hover

  -- scroll down hover doc or scroll in definition preview
  -- buf_keymap(0, "n", "<C-f>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", keymap_opts)
  -- buf_keymap(0, "n", "<C-b>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", keymap_opts)

  buf_keymap(0, "n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", keymap_opts)  -- signature help
  buf_keymap(0, "n", "<leader>rf", "<cmd>lua vim.lsp.buf.rename()<CR>", keymap_opts)  -- LSP rename (refactor)
  -- buf_keymap(0, "n", "gp", ":Lspsaga preview_definition<CR>", keymap_opts)  -- Preview Definition
  -- buf_keymap(0, "n", "<leader>sd", ":Lspsaga show_line_diagnostics<CR>", keymap_opts)  -- Show Line Diagnostics
  buf_keymap(0, 'n', 'gTD', '<cmd>lua vim.lsp.buf.type_definition()<CR>', keymap_opts)
  buf_keymap(0, 'n', 'gf', '<cmd>lua require"telescope.builtin".lsp_references()<CR>', keymap_opts)
  -- Diagnostic Navigation
  -- buf_keymap(0, "n", "]e", ":Lspsaga diagnostic_jump_next<CR>", keymap_opts)
  -- buf_keymap(0, "n", "[e", ":Lspsaga diagnostic_jump_prev<CR>", keymap_opts)

  -- format, if LSP supports it
  -- manual formatting on windows, format before write on linux
  if vim.g.windows then
    vim.cmd [[command! Format :lua vim.lsp.buf.formatting_sync({}, 2000)<CR>]]
  else
    if client.resolved_capabilities.document_formatting then
      vim.cmd [[augroup Format]]
      vim.cmd [[autocmd! * <buffer>]]

      -- https://github.com/mattn/efm-langserver/issues/88
      vim.cmd [[autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting_sync()]]

      vim.cmd [[augroup END]]
    end
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
if vim.g.windows then
  sumneko_root_path = vim.fn.expand("$HOME" .. "\\bin\\lua-language-server-2.6.3-win32-x64")
  sumneko_binary = sumneko_root_path.."\\bin\\lua-language-server.exe"
else
  sumneko_root_path = vim.fn.stdpath('cache')..'/lua-language-server'
  sumneko_binary = sumneko_root_path.."/bin/Linux/lua-language-server"
end

-- linter/formatter configs
local black = require "config/efm/black"
local flake8 = require "config/efm/flake8"
local isort = require "config/efm/isort"
local prettier = require "config/efm/prettier"
local shellcheck = require "config/efm/shellcheck"

-- TODO: fix html, css, json servers
-- TODO: setup dockerls and ansiblels

local border = {
  {"┌", "FloatBorder"},  --top-left
  {"─", "FloatBorder"},  --top
  {"┐", "FloatBorder"},  --top-right
  {"│", "FloatBorder"},  --right
  {"┘", "FloatBorder"},  --bottom-right
  {"─", "FloatBorder"},  --bottom
  {"└", "FloatBorder"},  --bottom-left
  {"│", "FloatBorder"},  --left
}

local handlers =  {
  ["textDocument/hover"] =  vim.lsp.with(vim.lsp.handlers.hover, {border = border}),
  ["textDocument/signatureHelp"] =  vim.lsp.with(vim.lsp.handlers.signature_help, {border = border }),
  ["textDocument/rename"] = vim.lsp.with(vim.lsp.handlers.re)
}

-- To instead override globally
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

local servers = {
  bashls = {},
  yamlls = {
    cmd = { "yaml-language-server", "--stdio" },
  },
  cssls = {},
  html = { filetypes = { "html", "htmldjango" } },
  jsonls = {},
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
    handlers=handlers,
    disableOrganizeImports = true,
    openFilesOnly = true,
    root_dir = function(fname)
        local root_files = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
      }
      return util.root_pattern(unpack(root_files))(fname) or util.find_git_ancestor(fname) or util.path.dirname(fname)
    end,
    settings = {
        python = {
          analysis = {
            typeCheckingMode = "off",
            autoImportCompletions = true,
          },
      },
    },
    on_init = function(client)
      client.config.settings.python.pythonPath = utils.get_python_path(client.config.root_dir)
    end
  },
  efm = {
    init_options = {
      documentFormatting = true,
    },
    root_dir = util.root_pattern {".git/", "."},
    settings = {
      rootMarkers = {".git/", "requirements.txt", ".venv/"},
      languages = {
        python = {black, flake8, isort},
        html = {prettier},
        json = {prettier},
        css = {prettier},
        javascript = {prettier},
        yaml = {prettier},
        markdown = {prettier},
        sh = {shellcheck},
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

local snippet_capabilities = vim.lsp.protocol.make_client_capabilities()
snippet_capabilities.textDocument.completion.completionItem.snippetSupport = true
snippet_capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = { 'documentation', 'detail', 'additionalTextEdits' },
}

for server, config in pairs(servers) do
  if type(config) == 'function' then
    config = config()
  end
  config.on_attach = on_attach
  config.capabilities = vim.tbl_deep_extend(
    'keep',
    config.capabilities or {},
    snippet_capabilities
  )
  lspconfig[server].setup(config)
end
