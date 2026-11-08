return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>f", desc = "Find files" },
    { "<leader>b", desc = "Buffers" },
    { "<leader>/", desc = "Live grep" },
  },
  config = function()
    -- calling `setup` is optional for customization
    require("fzf-lua").setup({
      winopts = {
        split = "botright new", -- open in a full-width split on the bottom
      },
      grep = {
        rg_opts = "--hidden --column --line-number -g '!{.git,node_modules}/*'",
      },
    })
    vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').files()<CR>", { silent = true, noremap = true })
    vim.keymap.set("n", "<leader>b", "<cmd>lua require('fzf-lua').buffers()<CR>", { silent = true, noremap = true })
    vim.keymap.set("n", "<leader>/", "<cmd>lua require('fzf-lua').live_grep()<CR>", { silent = true, noremap = true })
    -- TAB / S-TAB -- select / unselect one file
    -- Alt-a -- select / unselect all matches
    -- Alt-q -- send selection to quickfix list and open it
  end
  -- NAVIGATION
  -- ctrl-n / ctrl-p -- next / previous
}
