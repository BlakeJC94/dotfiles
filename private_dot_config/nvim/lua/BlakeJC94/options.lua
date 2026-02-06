M = {}

local get_options = function()
    local options = {
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
        inccommand = 'split',  -- Open temp split to preview replace output
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
        background = "dark", -- Background mode
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
        -- TOP MARGIN
        showtabline = 1, -- Display tab line (0, never, 1 auto, 2 always)
    }

    if vim.fn.executable('rg') == 1 then
      options.grepprg = 'rg --vimgrep --smart-case'
      options.grepformat = '%f:%l:%c:%m'
    end

    return options
end

local disable_netrw = function()
    vim.g.loaded_netrwPlugin = 1
    vim.g.loaded_netrw = 1
end

local set_options = function(options)
    for k, v in pairs(options) do
        vim.opt[k] = v
    end
end

M.set = function()
    vim.g.mapleader = " "

    disable_netrw()

    local options = get_options()
    set_options(options)
end

return M
