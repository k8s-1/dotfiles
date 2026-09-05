-- pick one scheme as the default, loaded by vim.cmd.colorscheme at start with
-- high priority, the rest can be lazyloaded
-- :colorscheme <name>
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    -- priority = 1000,
    config = function()
      require("catppuccin").setup({})
      vim.cmd.colorscheme "catppuccin-mocha"
      -- vim.cmd.colorscheme "catppuccin-macchiato"
    end,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = false,
    priority = 1000,

    name = "oxocarbon",
    config = function()
      vim.opt.background = "dark"
      vim.cmd.colorscheme "oxocarbon"
    end,
  },
  {
    'rebelot/kanagawa.nvim',
    lazy = true,
    -- priority = 1000,
    config = function()
      require('kanagawa').setup({
        background = {     -- map the value of 'background' option to a theme
          dark = "dragon", -- try "dragon" !
          light = "lotus"
        },
      })
      -- vim.cmd.colorscheme('kanagawa')
    end
  }
}
