-- keymaps attached with autocmd
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function()
    -- these will be buffer-local keybindings
    -- because they only work if you have an active language server
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})

    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, {})

    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, {})

    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})

    vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, {})

    vim.keymap.set('n', 'gr', vim.lsp.buf.references, {})

    vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, {})

    vim.keymap.set('n', '<F3>', function() vim.lsp.buf.format({ async = true }) end, {})
  end
})

-- general diagnostic config, e.g. syntax error highlighting etc...
vim.diagnostic.config({
  virtual_text = false,      -- Disable inline diagnostics if using virtual_lines
  virtual_lines = false,     -- Enable virtual lines for diagnostics
  signs = true,              -- Show signs in the gutter
  underline = true,          -- Underline problematic text
  update_in_insert = true,   -- Update diagnostics in insert mode
  severity_sort = false,     -- Do not sort by severity (show all diagnostics)
})
