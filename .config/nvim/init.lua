require("config.keymaps")
require("config.options")
require("config.autocmds")

-- package manager: https://github.com/folke/lazy.nvim
-- :checkhealth lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lazy load ./lua/plugins/*.lua
require("lazy").setup("plugins")


-- LSP
-- load basic config for built-in lsp commands
require("config.lsp")

-- 1. language server is installed with mason plugin instead of e.g. npm -i <name>, pip install etc...,
-- put new servers into mason.lua before adding them here
-- 2. defaults are loaded via nvim-lspconfig plugin,
-- vim.lsp.config automatically finds nvim-lspconfig configs and merges with any local lsp/*.lua configs
-- 3. override defaults with vim.lsp.config or configuring /after directory

-- calls ./lsp/<language-server>.lua
local language_servers = {
  "lua_ls",
  "rust_analyzer",
  "bashls",
  "yamlls",
  "gopls",
  "eslint",
}

for _, l in ipairs(language_servers) do
    vim.lsp.enable(l)
end

-- to override defaults, use vim.lsp.config, e.g.
-- vim.lsp.config('clangd', {
--   filetypes = { 'c' },
-- })
