return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = {
    -- MAIN KEYMAP TO OPEN OIL
    { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
  },
  config = function()
    require("oil").setup({
      columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
      },
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
      },
      keymaps = {
        ["g?"] = "actions.show_help",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["g."] = "actions.toggle_hidden",
      },
      skip_confirm_for_simple_edits = true,
    })
  end,
}
