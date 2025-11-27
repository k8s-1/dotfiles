-- [[ Setting options ]]
-- See `:help vim.opt`
-- For more options, you can see `:help option-list`

-- Tab handling
-- expand tab input with spaces characters
vim.opt.expandtab = true
-- syntax aware indentations for newline inserts
vim.opt.smartindent = true
-- num of space characters per tab
vim.opt.tabstop = 2
-- spaces per indentation level
vim.opt.shiftwidth = 2

-- Make line numbers default
vim.opt.number = true

-- Add relative line numbers, to help with jumping.
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits.
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
-- See `:help 'clipboard'`
-- vim.opt.clipboard = "unnamedplus"

-- Enable break indent, wrap lines that are too long with the original indentation of the screen
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease plugin update time, default 4000
vim.opt.updatetime = 300

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Make neovim work with tmux
vim.opt.termguicolors = true

-- Disable netrw at the very start of your init.lua
-- according to nvim.tree README
-- only needed for nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1


-- Enable folding
-- use za to toggle folds
vim.opt.foldmethod = "manual"
vim.opt.foldenable = true
