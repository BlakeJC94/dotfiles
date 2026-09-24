local set_options = function()
    for k, v in pairs({
        -- MAIN INPUT/OUTPUT
        clipboard = "unnamedplus", -- Allows vim to use "+ for yanks, puts, and deletes
        timeout = false, -- Allow timing out halfway into a mapping
        timeoutlen = 1000, -- Time (ms) between key sequences
        ttimeoutlen = 10, -- Time (ms) between key sequences in terminal
        hidden = true, -- Allow buffers to be hidden without saving
        confirm = true,
        autoread = true,
        mouse = "",
        updatetime = 100,
        path = vim.opt.path - { "/usr/include" },
        shellcmdflag = "-ic",  -- Source aliases in :! shell
        -- TABS AND INDENTS
        smartindent = true, -- Enable better indenting
        tabstop = 4, -- Number of space chars for each tab char
        softtabstop = 4, -- Number of space chars to insert on pressing tab
        shiftwidth = 4, -- Number of space chars used when auto-indenting
        expandtab = true, -- Replace tabs with spaces when indenting with </>
        -- SEARCHING
        ignorecase = true, -- Ignore cases in search patterns
        smartcase = true, -- Use case-sensitive search when an uppercase letter is used
        hlsearch = true, -- Highlight matches
        incsearch = true, -- Highlight matches while typing
        inccommand = "split", -- Open temp split to preview replace output
        -- BACKUPS AND SPELLING
        swapfile = false, -- Allow swap files
        backup = false, -- Allow creation of backup files
        spell = true, -- Built-in spell-checker
        undofile = true, -- Create global undofile
        undodir = vim.fn.expand("~/.nvim/undodir"),
        -- WINDOW DISPLAY
        splitbelow = true, -- Open splits below
        splitright = true, -- Open vsplits on right
        shortmess = vim.o.shm .. "I", -- Disable into message
        termguicolors = true, -- Wider colorscheme support
        guicursor = "", -- Cursor
        errorformat = vim.o.errorformat .. "%f", -- append %f
        -- LINE DISPLAY
        scrolloff = 8, -- N lines to keep visible above/below cursor
        sidescrolloff = 8, -- N columns to keep visible left/right of cursor
        textwidth = 80, -- Margin for text input
        showmatch = true, -- Highlight matching brackets
        wrap = false, -- Soft-wrap long lines and use breakindent opts
        linebreak = true, -- Only split/wrap long lines after words
        breakindent = true, -- Indent soft-wrapped lines
        breakindentopt = { list = -1 }, -- Options for breakindent
        showbreak = nil, -- Text to print at breakindent
        -- FOLDS
        foldmethod = "indent", -- Auto-create folds by indent levels
        foldlevel = 0, -- Close all folds when opening file
        fillchars = { fold = " ", eob = " " }, -- Replace dots with spaces in fold head
        -- LEFT MARGIN
        number = true, -- Show line numbers
        relativenumber = false, -- Show rel/abs line numbers
        signcolumn = "number", -- Set sign column
        -- BOTTOM MARGIN
        laststatus = 2, -- Show status line mode
        showcmd = true, -- Show command in bottom right
        cmdheight = 1, -- Set height of command window
        wildignore = { "*.pyc", "**/.git/*", "**/data/*" },
        wildmode = { "longest:full", "full" },
        -- TOP MARGIN
        showtabline = 1, -- Display tab line (0, never, 1 auto, 2 always)
    }) do
        vim.opt[k] = v
    end
end

local bootstrap_package_manager = function()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        print("Cloning lazy.nvim..")
        vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable",
            lazypath,
        })
    end
    vim.opt.rtp:prepend(lazypath)
end

local main = function()
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "
    set_options()

    bootstrap_package_manager()
    vim.cmd.colorscheme("retrobox")
    require("lazy").setup({
        spec = { { import = "plugins" } },
        change_detection = { enabled = false },
        colorscheme = { "retrobox" },
        dev = { path = "~/Workspace/repos" },
    })
end

main()



-- -- vim.api.nvim_create_autocmd('TermRequest', {
-- --  callback = function(ev)
-- --    local seq = vim.v.termrequest
-- --    -- Kitty graphics protocol: APC sequence starting with 'G'
-- --    if seq and seq:sub(1, 1) == 'G' then
-- --      -- Reconstruct the full APC sequence and send to host terminal vim.api.nvim_ui_send('\027_G' .. seq .. '\027\\') NOTE: Return true to mark as handled (prevents any other processing)
-- --      return true
-- --    end
-- --  end,
-- -- })
-- --
-- --
-- vim.api.nvim_create_autocmd('TermRequest', {
--  callback = function(ev)
--    local seq = vim.v.termrequest
--    vim.notify('TermRequest: ' .. (seq and seq:sub(1, 50) or 'nil'))
--    if seq and seq:sub(1, 1) == 'G' then
--      -- The kitty protocol is APC (ESC _) + data + ST (ESC \)
--      -- v:termrequest contains just the data (starts with 'G')
--      -- Reconstruct: ESC _ + data + ESC \
--      vim.api.nvim_ui_send('\027_' .. seq .. '\027\\')
--      return true
--    end
--  end,
-- })

-- vim.api.nvim_create_autocmd('TermRequest', {
--  callback = function(ev)
--    local seq = vim.v.termrequest
--    -- v:termrequest contains the full sequence including \033_
--    -- Just need to append the ST terminator (\033\)
--    if seq and seq:find('\027_G') then
--      vim.api.nvim_ui_send(seq .. '\027\\')
--      return true
--    end
--  end,
-- })

-- Why did I enable/disable this?
-- vim.api.nvim_create_autocmd('TermRequest', {
--  callback = function(ev)
--    local seq = vim.v.termrequest
--    if seq and seq:find('\027_G') then
--      local tty = io.open('/dev/tty', 'w')
--      if tty then
--        tty:write(seq)
--        tty:write('\027\\')
--        tty:close()
--      end
--      return true
--    end
--  end,
-- })
