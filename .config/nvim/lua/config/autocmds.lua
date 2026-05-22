-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})


local function is_wsl()
  local f = io.open('/proc/version', 'r')
  if not f then return false end
  local s = f:read('*a')
  f:close()
  return s:lower():find('microsoft') ~= nil
end

if is_wsl() then
  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    pattern = "*",
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
      for _, line in ipairs(lines) do
        if line:find('\r') then
          vim.opt_local.fileformat = "dos"
          return
        end
      end
    end,
  })
end

-- " Use tabs for Go files (4 spaces wide)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false -- Use actual tab characters
    vim.opt_local.tabstop = 4       -- Width of a tab character (4 spaces wide)
    vim.opt_local.shiftwidth = 4    -- Indent width for auto-indent (4 spaces)
  end,
})
