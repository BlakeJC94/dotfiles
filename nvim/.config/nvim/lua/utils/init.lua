local utils = {}
local lsp_util = require('lspconfig/util')

function utils.add_keymap(mode, opts, keymaps)
  for _, keymap in ipairs(keymaps) do
    vim.api.nvim_set_keymap(mode, keymap[1], keymap[2], opts)
  end
end

function utils.add_keymap_normal_mode(opts, keymaps)
  utils.add_keymap("n", opts, keymaps)
end

function utils.add_keymap_visual_mode(opts, keymaps)
  utils.add_keymap("v", opts, keymaps)
end

function utils.add_keymap_visual_block_mode(opts, keymaps)
  utils.add_keymap("x", opts, keymaps)
end

function utils.add_keymap_insert_mode(opts, keymaps)
  utils.add_keymap("i", opts, keymaps)
end

function utils.add_keymap_term_mode(opts, keymaps)
  utils.add_keymap("t", opts, keymaps)
end

-- Find either venv or global python
function utils.get_python_path(workspace)
  local path = lsp_util.path
  -- Find and use virtualenv via poetry in workspace directory.
  local match = vim.fn.glob(path.join(workspace, '.venv'))
  if match ~= '' then
    if vim.g.windows then
      return path.join(workspace, '.venv', 'Scripts', 'python')
    else
      return path.join(workspace, '.venv', 'bin', 'python')
    end
  end

  -- Fallback to system Python.
  return vim.fn.exepath('python') or 'python'
end

-- Use current working directory as 'workspace' to find python and run current buffer
function utils.run_python()
  local root = vim.loop.cwd()
  local file_path = vim.fn.expand("%:p")
  local python_bin = require('utils').get_python_path(root)
  if vim.g.windows then
    return vim.api.nvim_command(string.format(':split term://%s %s', python_bin, file_path))
  else
    return require('toggleterm').exec(("%s %s"):format(python_bin, file_path))
  end
end

function utils.loaded_plugins()
  local count = 0

  for _, v in pairs(packer_plugins) do
    if (v.loaded == true) then
      count = count + 1
    end
  end

  return count
end

return utils
