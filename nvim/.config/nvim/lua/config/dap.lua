local M = {}

local dap = require('dap')

M.stop_debugger = function()
  dap.terminate()
  require'dapui'.close()
  vim.api.nvim_command('DapVirtualTextForceRefresh')
end

M.setup = function()

  local options = { noremap = true, silent = true }
  vim.api.nvim_set_keymap("n", "<leader>b", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", options)
  vim.api.nvim_set_keymap("n", "<leader>rc", "<cmd>lua require'dap'.run_to_cursor()<cr>", options)
  vim.api.nvim_set_keymap("n", "<F5>", "<cmd>lua require'dap'.continue()<cr>", options)
  vim.api.nvim_set_keymap("n", "<F9>", "<cmd>lua require'config.dap'.stop_debugger()<cr>", options)
  vim.api.nvim_set_keymap("n", "<F11>", "<cmd>lua require'dap'.repl.open()<cr>", options)
  vim.api.nvim_set_keymap("n", "<F6>", "<cmd>lua require'dap'.step_over()<cr>", options)
  vim.api.nvim_set_keymap("n", "<F7>", "<cmd>lua require'dap'.step_into()<cr>", options)

  local breakpoint = {
      text = "",
      texthl = "DiagnosticSignError",
      linehl = "",
      numhl = "",
    }

  vim.fn.sign_define("DapBreakpoint", breakpoint)
  dap.defaults.fallback.terminal_win_cmd = "50vsplit new"

  dap.adapters.python = {
    type = 'executable';
    command = vim.loop.os_homedir() .. '/.local/debugpy/bin/python';
    args = { '-m', 'debugpy.adapter' };
  }

  dap.configurations.python = {
    {
    type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = 'launch';
    name = "Launch file";

    -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

    -- program = "${workspaceFolder}/${file}"; -- This configuration will launch the current file if used.
    program = "${file}"; -- This configuration will launch the current file if used.
    pythonPath = function()
      -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
      -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
      -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
      local cwd = vim.fn.getcwd()
      if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
        return cwd .. '/venv/bin/python'
      elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
        return cwd .. '/.venv/bin/python'
      else
        return vim.fn.exepath('python')
      end
    end;
    },
  }

end

return M
