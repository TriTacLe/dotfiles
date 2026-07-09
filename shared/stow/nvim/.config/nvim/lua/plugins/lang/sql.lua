-- SQL utviklingsoppsett (sqls LSP + dadbod via LazyVim extra)

return {
  -- sql-formatter via Mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "sql-formatter",
      })
    end,
  },

  -- Formatter
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sql = { "sql_formatter" },
        mysql = { "sql_formatter" },
        plsql = { "sql_formatter" },
      },
    },
  },

  -- Dadbod UI keymaps
  {
    "kristijanhusak/vim-dadbod-ui",
    keys = {
      { "<leader>du", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
      { "<leader>df", "<cmd>DBUIFindBuffer<cr>", desc = "Find DB buffer" },
    },
  },

  -- SQL filetype options
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          vim.opt_local.expandtab = true
          vim.opt_local.shiftwidth = 2
          vim.opt_local.tabstop = 2
          vim.opt_local.softtabstop = 2
        end,
      })
    end,
  },
}
