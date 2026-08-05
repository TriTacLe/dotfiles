-- LaTeX development setup

return {
  -- compile, view PDF (zathura), synctex, motions
  {
    "lervag/vimtex",
    lazy = false, -- lazy-loading breaks inverse search from the viewer
    keys = {
      { "<localLeader>l", "", desc = "+vimtex", ft = "tex" },
    },
    init = function()
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_compiler_method = "tectonic"
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
  },

  -- texlab: completion, hover docs, diagnostics
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {},
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "texlab",
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bibtex",
      })
      -- vimtex's own syntax beats the latex treesitter parser
      opts.highlight = opts.highlight or {}
      opts.highlight.disable = opts.highlight.disable or {}
      vim.list_extend(opts.highlight.disable, { "latex" })
    end,
  },
}
