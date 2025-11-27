-- mason installs language servers and linter programs
-- instead of e.g. `npm i -g bash-language-server`
-- install language servers either with:
-- A. Mason UI
-- B. Automatically through this config

-- Language servers are needed by LSP (language server protocol), configured in ../lsp)
-- :LspInfo
-- LSP does linting, formatting, and more

return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "lua_ls",
        "rust_analyzer",
        "bashls",
        "yamlls",
        "gopls",
        "eslint",
      },
    },
      dependencies = {
        { "mason-org/mason.nvim", opts = {} },
    },
}
