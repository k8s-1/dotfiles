return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- calling `setup` is optional for customization
    require("fzf-lua").setup({
      winopts = {
        split = "botright new", -- open in a full-width split on the bottom
      },
      grep = {
        rg_opts = "--hidden --column --line-number -g '!{.git,node_modules}/*'",
      }
    })
    vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').files()<CR>", { silent = true, noremap = true })
    vim.keymap.set("n", "<leader>b", "<cmd>lua require('fzf-lua').buffers()<CR>", { silent = true, noremap = true })
    vim.keymap.set("n", "<leader>/", "<cmd>lua require('fzf-lua').live_grep()<CR>",
      { silent = true, noremap = true })
  end
  -- NAVIGATION
  -- you can use UP/DOWN arrow key and PG_UP PG_DOWN
}
