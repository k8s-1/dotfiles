local scopes_sidebar
local frames_sidebar

return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>",       function() require("dap").continue() end,          desc = "DAP continue / start" },
      { "<leader>dc", function() require("dap").continue() end,          desc = "DAP continue / start" },
      { "<leader>dn", function() require("dap").step_over() end,         desc = "DAP next (step over)" },
      { "<leader>di", function() require("dap").step_into() end,         desc = "DAP step in" },
      { "<leader>do", function() require("dap").step_out() end,          desc = "DAP step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP breakpoint" },
      { "<leader>dh", function() require("dap.ui.widgets").hover() end,  desc = "DAP hover",           mode = { "n", "v" } },
      { "<leader>dx", function() require("dap").terminate() end,         desc = "DAP terminate" },
      {
        "<leader>ds",
        function()
          local w = require("dap.ui.widgets")
          scopes_sidebar = scopes_sidebar or w.sidebar(w.scopes, { width = 50 }, "vsplit")
          scopes_sidebar.toggle()
        end,
        desc = "DAP scopes sidebar"
      },
      { "<leader>dr", function() require("dap").repl.toggle() end,                               desc = "DAP REPL" },
      { "<leader>dC", function() require("dap").clear_breakpoints() end,                         desc = "DAP clear breakpoints" },
      { "<leader>dl", function() require("dap").run_last() end,                                  desc = "DAP run last" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "DAP conditional breakpoint" },
      {
        "<leader>df",
        function()
          local w = require("dap.ui.widgets")
          frames_sidebar = frames_sidebar or w.sidebar(w.frames, { height = 10 }, "belowright split")
          frames_sidebar.toggle()
        end,
        desc = "DAP frames sidebar"
      },
    },
    config = function()
      local dap = require("dap")

      dap.adapters.delve = {
        type = "server",
        port = "${port}",
        executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
      }

      dap.configurations.go = {
        {
          type = "delve",
          name = "Debug package",
          request = "launch",
          program = "${fileDirname}",
        },
        {
          type = "delve",
          name = "Debug package (args)",
          request = "launch",
          program = "${fileDirname}",
          args = function()
            return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
          end,
        },
        {
          type = "delve",
          name = "Debug test (function under cursor)",
          request = "launch",
          mode = "test",
          program = "${fileDirname}",
          args = function()
            local line = vim.fn.search([[^func \(Test\|Benchmark\)]], "bcnW")
            local name = line > 0 and vim.fn.getline(line):match("^func%s+([%w_]+)") or ""
            return { "-test.run", "^" .. name .. "$" }
          end,
        },
        {
          type = "delve",
          name = "Attach to process",
          request = "attach",
          mode = "local",
          processId = require("dap.utils").pick_process,
        },
      }

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk" })
    end,
  },
}
