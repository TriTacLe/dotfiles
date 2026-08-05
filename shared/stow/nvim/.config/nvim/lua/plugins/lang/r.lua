-- R development setup

return {
  -- REPL, object browser, Rmd/Quarto knit (successor to Nvim-R)
  {
    "R-nvim/R.nvim",
    ft = { "r", "rmd", "quarto" },
    opts = {
      R_args = { "--quiet", "--no-save" },
    },
  },

  -- languageserver: completion, hover docs, lintr diagnostics
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        r_language_server = {},
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "r-languageserver",
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "r",
        "rnoweb",
      })
    end,
  },
}
