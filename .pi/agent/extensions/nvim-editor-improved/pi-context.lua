-- pi-context.lua
--
-- Injected by the nvim-editor-improved Pi extension via
-- `nvim -c "lua dofile(vim.env.PI_NVIM_LUA)" <prompt>`. It runs after the
-- user's init.lua, so their plugins, keymaps, and options still apply.
--
-- Environment provided by the extension:
--   PI_NVIM_CONTEXT : read-only conversation snapshot (markdown)
--   PI_NVIM_PROMPT  : the editable prompt file (also the launched buffer)
--   PI_NVIM_OUTCOME : file where the chosen outcome is recorded
--
-- Outcomes:
--   :wqa / ZZ        -> exit 0, no outcome file -> extension submits
--   :PiSubmit        -> outcome "submit"
--   :PiEdit          -> outcome "edit"    (return to Pi's editor)
--   :PiCancel / :cq  -> outcome "cancel" / non-zero exit
--
-- The prompt buffer is persisted on exit unless an outcome was already
-- recorded, so the plain `:wqa` path works without a mapping.

local prompt_win = vim.api.nvim_get_current_win()
local prompt_buf = vim.api.nvim_get_current_buf()
local context_path = vim.env.PI_NVIM_CONTEXT
local outcome_path = vim.env.PI_NVIM_OUTCOME

local function record(kind)
  if outcome_path and outcome_path ~= "" then
    vim.fn.writefile({ kind }, outcome_path)
  end
end

local function decided()
  return outcome_path and outcome_path ~= "" and vim.fn.filereadable(outcome_path) == 1
end

local function write_prompt()
  pcall(function()
    vim.api.nvim_buf_call(prompt_buf, function()
      vim.cmd("silent! write")
    end)
  end)
end

-- Read-only context snapshot in a window above the prompt, scrolled to the
-- newest content so the most recent turns are visible next to the cursor.
if context_path and context_path ~= "" and vim.fn.filereadable(context_path) == 1 then
  vim.cmd("silent aboveleft split " .. vim.fn.fnameescape(context_path))
  local ctx_buf = vim.api.nvim_get_current_buf()
  vim.bo[ctx_buf].buftype = "nofile"
  vim.bo[ctx_buf].bufhidden = "wipe"
  vim.bo[ctx_buf].swapfile = false
  vim.bo[ctx_buf].modifiable = false
  vim.bo[ctx_buf].readonly = true
  vim.bo[ctx_buf].filetype = "markdown"

  local ctx_win = vim.api.nvim_get_current_win()
  vim.wo[ctx_win].wrap = true
  vim.wo[ctx_win].linebreak = true
  vim.wo[ctx_win].number = false
  vim.wo[ctx_win].relativenumber = false
  vim.wo[ctx_win].signcolumn = "no"
  vim.cmd("normal! G")
  vim.cmd("resize " .. math.max(5, math.floor(vim.o.lines * 0.55)))

  vim.api.nvim_set_current_win(prompt_win)
end

-- Start at the end of the prompt, ready to type.
vim.cmd("normal! G$")

vim.api.nvim_create_user_command("PiSubmit", function()
  record("submit")
  write_prompt()
  vim.cmd("qa!")
end, { desc = "Submit this prompt to Pi" })

vim.api.nvim_create_user_command("PiEdit", function()
  record("edit")
  write_prompt()
  vim.cmd("qa!")
end, { desc = "Return this prompt to Pi's editor without submitting" })

vim.api.nvim_create_user_command("PiCancel", function()
  record("cancel")
  vim.cmd("cq")
end, { desc = "Cancel and keep the previous Pi prompt" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if decided() then return end
    write_prompt()
  end,
})
