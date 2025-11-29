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
      },
      files = {
        -- save entire matched file list to quick fix list, required fzf >= 0.53
        actions = { ["ctrl-q"] = { fn = require "fzf-lua".actions.file_sel_to_qf, prefix = "select-all" } }
        -- alternatively, press TAB / S-TAB to select / unselect specific files
        -- when done, press alt-q
      }
    })
    vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').files()<CR>", { silent = true, noremap = true })
    vim.keymap.set("n", "<leader>b", "<cmd>lua require('fzf-lua').buffers()<CR>", { silent = true, noremap = true })
    vim.keymap.set("n", "<leader>/", "<cmd>lua require('fzf-lua').live_grep()<CR>", { silent = true, noremap = true })
    -- TAB -- select
    -- Alt-q -- add selection to quick fix list
  end
  -- NAVIGATION
  -- you can use UP/DOWN arrow key and PG_UP PG_DOWN
}
