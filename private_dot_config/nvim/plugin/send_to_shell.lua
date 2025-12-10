-- Plugin to manage a marked terminal and send text to it
local M = {}

-- Store the terminal buffer and job ID
local terminal_buf = nil
local terminal_job_id = nil

-- Function to check if the terminal is running IPython
local function is_ipython()
  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
    return false
  end

  -- Get the terminal buffer content to check for IPython prompt
  local lines = vim.api.nvim_buf_get_lines(terminal_buf, -10, -1, false)
  for _, line in ipairs(lines) do
    if string.match(line, "In %[%d+%]:") or string.match(line, "IPython") then
      return true
    end
  end
  return false
end

-- Function to open a new terminal in a split
local function open_terminal(cmd)
  -- Check if we already have a valid terminal
  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
    -- Check if the terminal job is still running
    local job_info = vim.fn.jobwait({ terminal_job_id }, 0)
    if job_info[1] == -1 then -- Job is still running
      print("Terminal already exists and is active")
      return
    end
  end

  -- Create a horizontal split
  vim.cmd("split")

  -- Open terminal in the new split with optional command
  if cmd and cmd ~= "" then
    vim.cmd("terminal " .. cmd)
  else
    vim.cmd("terminal")
  end

  -- Store the buffer number and job ID
  terminal_buf = vim.api.nvim_get_current_buf()
  terminal_job_id = vim.b.terminal_job_id

  -- Set some buffer options for better UX
  vim.api.nvim_buf_set_option(terminal_buf, "buflisted", false)
  vim.api.nvim_buf_set_name(terminal_buf, "SendToShell Terminal")

  -- Set up auto-close when terminal exits
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = terminal_buf,
    callback = function()
      -- Close the terminal buffer when the process exits
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(terminal_buf) then
          vim.api.nvim_buf_delete(terminal_buf, { force = true })
        end
        -- Reset the terminal variables
        terminal_buf = nil
        terminal_job_id = nil
      end)
    end,
    once = true,
  })

  -- Return to the previous window
  vim.cmd("wincmd p")

  if cmd and cmd ~= "" then
    print("Terminal opened with command: " .. cmd)
  else
    print("Terminal opened and marked")
  end
end

-- Function to close the marked terminal
local function close_terminal()
  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
    print("No valid terminal found to close.")
    return
  end

  -- Find the window containing the terminal buffer
  local terminal_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == terminal_buf then
      terminal_win = win
      break
    end
  end

  -- Close the terminal window if found
  if terminal_win then
    vim.api.nvim_win_close(terminal_win, false)
  end

  -- Delete the terminal buffer
  vim.api.nvim_buf_delete(terminal_buf, { force = true })

  -- Reset the terminal variables
  terminal_buf = nil
  terminal_job_id = nil

  print("Terminal closed")
end

-- Function to scroll terminal to bottom
local function scroll_terminal_to_bottom()
  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
    return
  end

  -- Find the window containing the terminal buffer
  local terminal_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == terminal_buf then
      terminal_win = win
      break
    end
  end

  if terminal_win then
    -- Get the total number of lines in the buffer
    local line_count = vim.api.nvim_buf_line_count(terminal_buf)
    -- Set cursor to the last line
    vim.api.nvim_win_set_cursor(terminal_win, { line_count, 0 })
  end
end

-- Function to send text to the marked terminal
local function send_to_terminal(text, force_ipython_mode)
  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
    print("No valid terminal found. Use :OpenTerminal first.")
    return
  end

  if not terminal_job_id then
    print("Terminal job ID not found.")
    return
  end

  -- Expand % symbols to current file path
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file and current_file ~= "" then
    text = string.gsub(text, "%%", vim.fn.shellescape(current_file))
  end

  -- Auto-detect IPython mode or use forced mode
  local use_ipython_mode = force_ipython_mode or is_ipython()

  if use_ipython_mode then
    -- Use IPython's %cpaste mode for multi-line code
    vim.api.nvim_chan_send(terminal_job_id, "%cpaste -q\n")
    -- Wait a moment for cpaste to be ready
    vim.defer_fn(function()
      vim.api.nvim_chan_send(terminal_job_id, text .. "\n")
      vim.api.nvim_chan_send(terminal_job_id, "\x04") -- Ctrl-D to end paste mode
    end, 50)
  else
    -- Send the text to the terminal normally
    vim.api.nvim_chan_send(terminal_job_id, text .. "\n")
  end

  -- Scroll terminal to bottom after a short delay to allow text to appear
  vim.defer_fn(scroll_terminal_to_bottom, 100)
end

-- Function to send current line to terminal
local function send_current_line()
  local line = vim.api.nvim_get_current_line()
  send_to_terminal(line)
end

-- Function to send visual selection to terminal
local function send_visual_selection(force_ipython_mode)
  -- Get the visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

  if #lines == 0 then
    return
  end

  -- If single line, handle column selection
  if #lines == 1 then
    local line = lines[1]
    local start_col = start_pos[3] - 1
    local end_col = end_pos[3]
    lines[1] = string.sub(line, start_col + 1, end_col)
  else
    -- Multi-line selection: trim first and last lines
    local first_line = lines[1]
    local last_line = lines[#lines]
    lines[1] = string.sub(first_line, start_pos[3])
    lines[#lines] = string.sub(last_line, 1, end_pos[3])
  end

  local text = table.concat(lines, "\n")
  send_to_terminal(text, force_ipython_mode)
end

-- Function to check if a line is a cell delimiter
local function is_cell_delimiter(line)
  -- Cell delimiter pattern: # %%, -- %%, In[n], or ```
  return string.match(line, "^%s*[#%-%-]%s+%%%%") or string.match(line, "^%s*In%[%d+%]") or string.match(line, "^```")
end

-- Function to send current cell to terminal
local function send_current_cell(force_ipython_mode)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(0)
  local all_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Find the start of the current cell
  local cell_start = 1
  for i = current_line, 1, -1 do
    if is_cell_delimiter(all_lines[i]) then
      cell_start = i + 1
      break
    end
  end

  -- Find the end of the current cell
  local cell_end = total_lines
  local next_cell_start = nil
  for i = current_line + 1, total_lines do
    if is_cell_delimiter(all_lines[i]) then
      cell_end = i - 1
      next_cell_start = i
      break
    end
  end

  -- Get the cell content
  local cell_lines = vim.api.nvim_buf_get_lines(0, cell_start - 1, cell_end, false)

  -- Remove empty lines at the beginning and end
  while #cell_lines > 0 and string.match(cell_lines[1], "^%s*$") do
    table.remove(cell_lines, 1)
  end
  while #cell_lines > 0 and string.match(cell_lines[#cell_lines], "^%s*$") do
    table.remove(cell_lines, #cell_lines)
  end

  if #cell_lines == 0 then
    print("No cell content found")
    return
  end

  local text = table.concat(cell_lines, "\n")
  send_to_terminal(text, force_ipython_mode)

  -- Jump to the next cell if it exists
  if next_cell_start then
    vim.api.nvim_win_set_cursor(0, { next_cell_start, 0 })
  end
end

-- Create user commands
vim.api.nvim_create_user_command("OpenTerminal", function(opts)
  open_terminal(opts.args)
end, {
  nargs = "*",
  desc = "Open a new terminal in a split and mark it for sending text (optional: specify command to run)",
})

vim.api.nvim_create_user_command("SendToTerminal", function(opts)
  local force_ipython = opts.bang
  send_to_terminal(opts.args, force_ipython)
end, {
  nargs = "+",
  bang = true,
  desc = "Send arbitrary text to the marked terminal (auto-detects IPython, use ! to force IPython mode)",
})

vim.api.nvim_create_user_command("SendLine", function(opts)
  local force_ipython = opts.bang
  local line = vim.api.nvim_get_current_line()
  send_to_terminal(line, force_ipython)
end, {
  bang = true,
  desc = "Send current line to the marked terminal (auto-detects IPython, use ! to force IPython mode)",
})

vim.api.nvim_create_user_command("SendSelection", function(opts)
  local force_ipython = opts.bang
  send_visual_selection(force_ipython)
end, {
  range = true,
  bang = true,
  desc = "Send visual selection to the marked terminal (auto-detects IPython, use ! to force IPython mode)",
})

vim.api.nvim_create_user_command("SendCell", function(opts)
  local force_ipython = opts.bang
  send_current_cell(force_ipython)
end, {
  bang = true,
  desc = "Send current cell (between # %%, -- %%, In[n], or ``` markers) to the marked terminal",
})

vim.api.nvim_create_user_command("CloseTerminal", function()
  close_terminal()
end, {
  desc = "Close the marked terminal",
})

-- Set up key mappings
vim.keymap.set('v', '<C-c>', function()
  send_visual_selection()
end, { desc = 'Send selection to terminal', silent = true })

vim.keymap.set('n', '<C-c><C-c>', function()
  send_current_cell()
end, { desc = 'Send current cell to terminal', silent = true })

-- Optional: Set up some additional convenient key mappings
-- Uncomment these if you want more default keybindings
-- vim.keymap.set('n', '<leader>to', open_terminal, { desc = 'Open terminal' })
-- vim.keymap.set('n', '<leader>tl', send_current_line, { desc = 'Send line to terminal' })

return M
