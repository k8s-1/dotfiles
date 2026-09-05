return {
  {
    "tpope/vim-fugitive",
    name = "vim-fugitive",
    cmd = "Git",
    keys = {
      { "<leader>gl", desc = "Git log" },
      { "<leader>gd", desc = "Git diff" },
      { "<leader>gb", desc = "Git blame" },
      { "<leader>gs", desc = "Git status" },
    },
    config = function()
      vim.keymap.set("n", "<leader>gl", ":Git log -p<CR>")
      vim.keymap.set("n", "<leader>gd", ":Git diff<CR>")
      vim.keymap.set("n", "<leader>gb", ":Git blame<CR>")
      vim.keymap.set("n", "<leader>gs", ":Git status<CR>")
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    name = "gitsigns",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({})
      local gitsigns = require('gitsigns')
      vim.keymap.set('n', '<leader>gt', gitsigns.toggle_current_line_blame, { noremap = true })
      vim.keymap.set('n', '<leader>gh', gitsigns.preview_hunk, { noremap = true })
    end,
  }
}
