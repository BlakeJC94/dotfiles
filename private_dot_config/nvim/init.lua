-- Bootstrap package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

vim.g.mapleader = " "

-- Install plugins
require("lazy").setup({
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		branch = "main",
		build = ":TSUpdate",
		config = function()
			local treesitter = require("nvim-treesitter")
			treesitter.setup({
				install_dir = vim.fn.stdpath("data") .. "/treesitter",
			})
			treesitter.install({ "python", "lua", "markdown", "markdown_inline", "sql" })
			vim.api.nvim_create_autocmd("FileType", {
			   pattern = { "python,lua,markdown,sql" },
			   callback = function()
				vim.treesitter.start()
			   end,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- Configure LSPs
			vim.lsp.config("lua_ls", {
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
				settings = { Lua = {} },
			})

			vim.lsp.enable("pylsp")
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("sqruff")
			vim.lsp.enable("stylua")
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"kdheepak/cmp-latex-symbols",
			"lukas-reineke/cmp-under-comparator",
		},
		config = function()
			local function has_words_before()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local function cmp_tab(fallback)
				local cmp = require("cmp")
				if cmp.visible() then
					cmp.select_next_item()
				elseif has_words_before() then
					cmp.complete()
				else
					fallback()
				end
			end

			local function cmp_s_tab(fallback)
				local cmp = require("cmp")
				if cmp.visible() then
					cmp.select_prev_item()
				else
					fallback()
				end
			end

			local cmp = require("cmp")

			local map = cmp.mapping
			vim.opt.completeopt = "menu,menuone,preview,noselect,noinsert"
			cmp.setup({
				-- formatting = { format = lspkind.cmp_format({ with_text = true, maxwidth = 50 }) },
				mapping = {
					["<Up>"] = map(map.select_prev_item(), { "i", "c" }),
					["<Down>"] = map(map.select_next_item(), { "i", "c" }),
					["<S-Up>"] = map.scroll_docs(-4),
					["<S-Down>"] = map.scroll_docs(4),
					["<Tab>"] = map(cmp_tab, { "i", "s", "c" }),
					["<S-Tab>"] = map(cmp_s_tab, { "i", "s", "c" }),
					["<C-c>"] = map(map.abort(), { "i", "c" }),
					["<CR>"] = map.confirm({
						behavior = cmp.ConfirmBehavior.Select,
						select = true,
					}),
				},
				preselect = cmp.PreselectMode.None,
				sources = {
					{ name = "nvim_lsp" },
					{ name = "path" },
					{
						name = "buffer",
						option = {
							get_bufnrs = function()
								local bufs = {}
								for _, win in ipairs(vim.api.nvim_list_wins()) do
									local buf = vim.api.nvim_win_get_buf(win)
									local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
									if byte_size < 1024 * 1024 then
										bufs[vim.api.nvim_win_get_buf(win)] = true
									end
								end
								return vim.tbl_keys(bufs)
							end,
						},
					},
					{ name = "latex_symbols" },
				},
				sorting = {
					comparators = {
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						require("cmp-under-comparator").under,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
			})
			cmp.setup.cmdline(":", {
				sources = {
					{ name = "cmdline" },
				},
			})
			cmp.setup.cmdline("/", {
				sources = {
					{ name = "buffer" },
				},
			})
		end,
	},
	{
		"ibhagwan/fzf-lua",
		opts = {
			winopts = {
				border = "none",
			},
			previewers = {
				man = { cmd = "man %s | col -bx" },
			},
			grep = {
				rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --hidden",
			},
			highlights = {
				actions = {
					["default"] = function(selected) -- TODO open PR for this action
						local bufnr = vim.api.nvim_get_current_buf()
						if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_option(bufnr, "readonly") then
							return
						end
						local cursor = vim.api.nvim_win_get_cursor(0)
						local row, col = cursor[1] - 1, cursor[2]
						local results = {}
						for i = 1, #selected do
							results[i] = string.gsub(selected[i], "^@", "")
						end
						vim.api.nvim_buf_set_text(bufnr, row, col, row, col, results)
					end,
				},
				fzf_opts = {
					["--no-multi"] = nil,
				},
			},
		},
		keys = {
			{ "z=", [[v:count ? v:count . 'z=' : ':FzfLua spell_suggest<CR>']], expr = true },
			{ "<C-r><C-r>", "<cmd>FzfLua registers<CR>", mode = "i" },
			{ "<Leader><BS>", "<cmd>FzfLua files<CR>", mode = "n" },
			{ "<Leader><CR>", "<cmd>FzfLua buffers<CR>", mode = "n" },
			{ "<Leader>ff", "<cmd>FzfLua resume<CR>", mode = "n" },
			{ "<Leader>fF", "<cmd>FzfLua<CR>", mode = "n" },
			{ "<Leader>fb", ":FzfLua buffers<CR>" },
			{ "<Leader>fo", ":FzfLua oldfiles cwd_only=true<CR>" }, -- Recently changed files
			{ "<Leader>fO", ":FzfLua oldfiles<CR>" }, -- Recently changed files
			{ "<Leader>f/", ":FzfLua lgrep_curbuf<CR>" },
			{ "<Leader>fg", ":FzfLua live_grep_native<CR>" }, -- Jumping with livegrep
			{ "<Leader>fh", ":FzfLua help_tags<CR>" },
			{ "<Leader>fH", ":FzfLua man_pages<CR>" },
			{ "<Leader>fq", ":FzfLua quickfix<CR>" },
			{ "<Leader>fl", ":FzfLua loclist<CR>" },
			{ "<Leader>fv", ":FzfLua lsp_document_symbols<CR>" },
		},
	},
	{
		"ellisonleao/gruvbox.nvim",
		config = function()
			local gruvbox = require("gruvbox")
			local palette = gruvbox.palette

			local color_midpoint = function(color1, color2, n_midpoints, point_idx)
				n_midpoints = n_midpoints or 1
				point_idx = point_idx or 1

				if n_midpoints < 1 then
					error("Invalid n_midpoints, expected >= 1")
				end
				if point_idx < 1 or point_idx > n_midpoints then
					error("Invalid point_idx")
				end

				local color_coords = {}
				for _, color in ipairs({ color1, color2 }) do
					if type(color) ~= "string" or #color ~= 7 or color:sub(1, 1) ~= "#" then
						error("Invalid color given, expected format '#xxxxxx'")
					end
					color_coords[color] = {
						tonumber("0x" .. color:sub(2):sub(1, 2)),
						tonumber("0x" .. color:sub(2):sub(3, 4)),
						tonumber("0x" .. color:sub(2):sub(5, 6)),
					}
				end

				local delta_x = 1 / (n_midpoints + 1)
				local result = "#"

				for i = 1, 3 do
					local m = color_coords[color2][i] - color_coords[color1][i]
					local c = color_coords[color1][i]
					local step = point_idx * delta_x

					local val = step * m + c
					result = result .. string.format("%02x", math.floor(val + 0.5))
				end

				return result
			end

			local bg_diff_delete = color_midpoint(palette.dark0_hard, palette.neutral_red, 10, 1)
			local bg_diff_add = color_midpoint(palette.dark0_hard, palette.neutral_green, 10, 1)
			local bg_diff_change = color_midpoint(palette.dark0_hard, palette.neutral_blue, 10, 1)
			local bg_diff_text = color_midpoint(palette.dark0_hard, palette.neutral_yellow, 10, 3)

			gruvbox.setup({
				undercurl = true,
				underline = true,
				bold = true,
				italic = {
					strings = false,
					comments = false,
					operators = false,
					folds = false,
				},
				invert_selection = false,
				invert_signs = false,
				invert_tabline = false,
				invert_intend_guides = false,
				contrast = "hard", -- can be "hard" or "soft"
				overrides = {
					NormalFloat = { bg = palette.dark0 },
					SignColumn = { bg = palette.dark0_hard },
					Folded = { bg = palette.dark0 },
					ColorColumn = { bg = palette.dark0 },
					CursorLine = { bg = palette.dark0 },
					CursorLineNr = { bg = palette.dark0 },
					Search = { fg = palette.bright_yellow, bg = palette.dark0 },
					CurSearch = { bg = palette.bright_yellow, fg = palette.dark0 },
					IncSearch = { fg = palette.bright_yellow, bg = palette.dark0 },
					DiffChange = { bg = bg_diff_change, fg = "", reverse = false },
					DiffAdd = { bg = bg_diff_add, fg = "", reverse = false },
					DiffDelete = { bg = bg_diff_delete, fg = "", reverse = false },
					DiffText = { bg = bg_diff_text, fg = "", reverse = false },
					MatchWord = { bg = palette.dark0 },
					MatchParenCur = { bg = palette.dark0 },
					MatchWordCur = { bg = palette.dark0 },
					LocalHighlight = { bg = nil, fg = nil, underline = true },
					SymbolsOutline = { bg = nil, fg = palette.neutral_blue },
					SymbolsOutlineConnector = { bg = nil, fg = palette.neutral_blue },
					healthSuccess = { bg = palette.bright_green, fg = palette.dark0_hard },
					healthError = { bg = palette.bright_red, fg = palette.dark0_hard },
				},
			})

			vim.opt.background = "dark"
			vim.cmd("colorscheme gruvbox")
		end,
	},
	{
		"chrisgrieser/nvim-various-textobjs",
		opts = { keymaps = { useDefaults = false } },
		keys = {
			{ "av", '<cmd>lua require("various-textobjs").subword("outer")<CR>', mode = { "o", "x" } },
			{ "iv", '<cmd>lua require("various-textobjs").subword("inner")<CR>', mode = { "o", "x" } },
		},
	},
	{ "tpope/vim-rsi" },
	{ "tpope/vim-eunuch" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-surround" },
	{ "tpope/vim-commentary" },
	{ "tpope/vim-unimpaired" },
	{ "tpope/vim-dispatch" },
	{ "tpope/vim-sleuth" },
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-rhubarb" },
	{ "tpope/vim-vinegar" },
	{ "BlakeJC94/vim-convict" },
	{ "rhysd/conflict-marker.vim" }, -- Get the mappings from this and rm
	{ "brenoprata10/nvim-highlight-colors" },
})

-- functions
local custom_fold_text = function()
	local line = vim.fn.getline(vim.v.foldstart)

	local indent_str = string.rep(" ", vim.fn.indent(vim.v.foldstart - 1))
	local fold_str = indent_str .. line .. string.rep(" ", vim.bo.textwidth)

	local fold_size = vim.v.foldend - vim.v.foldstart + 1
	local fold_size_str = " (" .. fold_size .. ") "

	return string.sub(fold_str, 0, vim.bo.textwidth - #fold_size_str) .. fold_size_str
end
_G.custom_fold_text = custom_fold_text

local toggle_quickfix_list = function()
	local has_qf = #vim.fn.filter(vim.fn.getwininfo(), "v:val.quickfix") > 0

	if has_qf then
		pcall(vim.cmd.cclose)
	else
		local ok = pcall(vim.cmd.copen)
		if not ok then
			vim.notify("No quickfix list available", vim.log.levels.WARN)
		end
	end
end

local toggle_local_list = function()
	local has_loc = #vim.fn.filter(vim.fn.getwininfo(), "v:val.loclist") > 0

	if has_loc then
		pcall(vim.cmd.lclose)
	else
		local ok = pcall(vim.cmd.lopen)
		if not ok then
			vim.notify("No location list available", vim.log.levels.WARN)
		end
	end
end

-- Options
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
	path = vim.opt.path - { "/usr/include" },
	-- TABS AND INDENTS
	smartindent = true, -- Enable better indenting
	tabstop = 4, -- Number of space chars for each tab char
	softtabstop = 4, -- Number of space chars to insert on pressing tab
	shiftwidth = 4, -- Number of space chars used when auto-indenting
	expandtab = true, -- Replace tabs with spaces when indenting with </>
	-- SEARCHING
	ignorecase = true, -- Ignore cases in search patterns
	smartcase = true, -- Use case-sensitve search when an uppercase letter is used
	hlsearch = true, -- Highlight matches
	incsearch = true, -- Highlight matches while typing
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
	scrolloff = 999, -- N lines to keep visible above/below cursor
	sidescrolloff = 8, -- N columns to keep visible left/right of cursor
	textwidth = 100, -- Margin for text input
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
	foldtext = "v:lua.custom_fold_text()",
	-- LEFT MARGIN
	number = true, -- Show line numbers
	relativenumber = true, -- Show rel/abs line numbers
	signcolumn = "number", -- Set sign column
	-- BOTTOM MARGIN
	statusline = "%<%f %h%m%r%{FugitiveStatusline()}%=%{get(b:,'gitsigns_status','')} %-14.(%l,%c%V%) %P",
	laststatus = 2, -- Show status line mode
	showcmd = true, -- Show command in bottom right
	cmdheight = 1, -- Set height of command window
	wildignore = { "*.pyc", "**/.git/*", "**/data/*" },
	-- TOP MARGIN
	showtabline = 1, -- Display tab line (0, never, 1 auto, 2 always)
}
for k, v in pairs(options) do
	vim.opt[k] = v
end

-- mappings
local mappings = {
	-- Make Y behave like D and C
	{ "Y", "y$" },
	-- Better jumplist for large line steps (and step through visual lines with j/k)
	{ "j", [[(v:count > 5 ? 'm`' . v:count : 'g') . 'j']], expr = true },
	{ "k", [[(v:count > 5 ? 'm`' . v:count : 'g') . 'k']], expr = true },
	-- gV: Visually select last pasted block (like gv)
	{ "gV", "`[v`]" },
	-- gF: create new file at filename over cursor
	{ "gF", "<cmd>e <c-r><c-f><CR>" },
	-- Make {/} don't change the jumplist
	{ "{", ":<C-u>keepjumps norm! {<CR>" },
	{ "}", ":<C-u>keepjumps norm! }<CR>" },
	-- Prevent x and s from overriding what's in the clipboard
	{ "x", '"_x' },
	{ "X", '"_X' },
	{ "s", '"_s' },
	-- Open folds when flicking through search matches
	{ "n", "nzv" },
	{ "N", "Nzv" },
	-- Remap q and Q to stop polluting registers accidentally!
	{ "q", "gw" },
	{ "Q", "q" },
	-- Maintain Visual Mode after >/</= actions
	{ "<", "<gv", mode = "v" },
	{ ">", ">gv", mode = "v" },
	{ "=", "=gv", mode = "v" },
	-- Swap p and P to stop losing register contents by pasting over
	{ "p", "P", mode = "v" },
	{ "P", "p", mode = "v" },
	-- C-s : Quickly guess correct spelling errors (undoable)
	{ "<C-s>", "<C-g>u<Esc>[s1z=`]a<C-g>u", mode = "i", remap = false },
	{ "<C-s>", "i<C-g>u<Esc>[s1z=`]", remap = false },
	-- Stop accidentally opening help in insert mode
	{ "<F1>", "", mode = "i" },
	-- Use unused arrow keys
	{ "<Left>", "[" },
	{ "<Right>", "]" },
	{ "<Up>", "[" },
	{ "<Down>", "]" },
	-- Fkey maps
	{ "<F1>", ":setl relativenumber!<CR>:setl relativenumber?<CR>", silent = false },
	{ "<F2>", ":setl number!<CR>:setl number?<CR>", silent = false },
	{ "<F3>", ":setl wrap!<CR>:setl wrap?<CR>", silent = false },
	{ "<F4>", ":setl spell!<CR>:setl spell?<CR>", silent = false },
	{ "<F5>", ":checktime<CR>", silent = false },
	{ "<F6>", ":wincmd =<CR>", silent = false },
	-- Resize split maps
	{ "<C-Left>", ":wincmd 8<<CR>" },
	{ "<C-Up>", ":wincmd 4+<CR>" },
	{ "<C-Down>", ":wincmd 4-<CR>" },
	{ "<C-Right>", ":wincmd 8><CR>" },
	-- Vim Tab controls
	{ "<Leader>t", ":tabedit %<CR>" },
	{ "<Leader>n", ":tabnext<CR>" },
	{ "<Leader>p", ":tabnext<CR>" },
	{ "<Leader>N", ":+tabmove<CR>" },
	{ "<Leader>P", ":-tabmove<CR>" },
	-- Leader maps
	{ "<Leader><Tab>", "<C-^>" }, -- Last file
	{ "<Leader>q", toggle_quickfix_list },
	{ "<Leader>l", toggle_local_list },
	{ "<Leader>;", "<cmd>edit $MYVIMRC | lcd %:p:h<CR>" }, -- Edit settings
}

local set_mappings = function(maps)
	for _, map in pairs(maps) do
		local key, value = unpack(map)
		local opts = {}

		local mode = map.mode or "n"

		if map.silent == nil then
			opts.silent = true
		else
			opts.silent = map.silent
		end

		if map.noremap == nil then
			opts.noremap = true
		else
			opts.noremap = map.noremap
		end

		if map.nowait ~= nil then
			opts.nowait = map.nowait
		end
		if map.script ~= nil then
			opts.script = map.script
		end
		if map.expr ~= nil then
			opts.expr = map.expr
		end
		if map.unique ~= nil then
			opts.unique = map.unique
		end
		if map.desc ~= nil then
			opts.desc = map.desc
		end
		if map.buffer ~= nil then
			opts.buffer = map.buffer
		end

		vim.keymap.set(mode, key, value, opts)
	end
end
set_mappings(mappings)

local add_undo_breakpoints_insert_mode_punctuation = function()
	local undo_mappings = {}
	for _, mark in pairs({ ".", ",", "!", "?", "(", ")", "[", "]", "{", "}", "<", ">", '"', "'" }) do
		undo_mappings[#undo_mappings + 1] = { mark, mark .. "<C-g>u", mode = "i" }
	end
	set_mappings(undo_mappings)
end
add_undo_breakpoints_insert_mode_punctuation()

local disable_shift_alt_arrow_keys = function()
	local arrow_mappings = {}
	for _, mod in pairs({ "S-", "A-" }) do
		for _, dir in pairs({ "Left", "Down", "Up", "Right" }) do
			arrow_mappings[#arrow_mappings + 1] = { "<" .. mod .. dir .. ">", "" }
		end
	end
	set_mappings(arrow_mappings)
end
disable_shift_alt_arrow_keys()

