return {
  {
    "tpope/vim-fugitive",
    name = "vim-fugitive",

    config = function()
      vim.keymap.set("n", "<leader>gl", ":Git log -p<CR>")
      vim.keymap.set("n", "<leader>gd", ":Git diff<CR>")
      vim.keymap.set("n", "<leader>gb", ":Git blame<CR>")
      vim.keymap.set("n", "<leader>gs", ":Git status<CR>")

      -- DOES NOT DEPEND ON VIM-FUGITIVE, LAZY ADD/COMMIT FUNCTION
      local function git_add_and_commit()
        local handle = io.popen('git diff --name-only && git add -A')
        if handle then
          local modified_files = handle:read("*a")
          handle:close()

          local commit_message = 'chore: update file(s):'

          for filename in modified_files:gmatch("[^\r\n]+") do
            commit_message = commit_message .. " " .. filename
          end

          print("Committing with message: " .. commit_message)

          local cmd = "git commit -m '" .. commit_message .. "'"

          local commit_handle = io.popen(cmd)
          if commit_handle then
            print("commit added!")
          end
        end
      end
      vim.keymap.set('n', '<leader>gg', git_add_and_commit, { noremap = true })
      -- DOES NOT DEPEND ON VIM-FUGITIVE, LAZY ADD/COMMIT FUNCTION
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    name = "gitsigns",
    lazy = false,
    config = function()
      require("gitsigns").setup({})
      local gitsigns = require('gitsigns')
      vim.keymap.set('n', '<leader>gt', gitsigns.toggle_current_line_blame, { noremap = true })
      vim.keymap.set('n', '<leader>gh', gitsigns.preview_hunk, { noremap = true })
    end,
  }
}
