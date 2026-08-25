-- Jupyter stack: molten (inline cell output), jupytext (.ipynb as .py), quarto (.qmd), image.nvim
--
-- One-time pip deps (in your project venv or --user):
--   pip install pynvim jupyter_client cairosvg nbformat pillow pyperclip
-- After :Lazy sync, run :UpdateRemotePlugins for molten.

return {
  -- Run notebook cells inline, show output in buffer
  {
    "benlubas/molten-nvim",
    build = ":UpdateRemotePlugins",
    dependencies = { "3rd/image.nvim" },
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_show_more = true
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
    end,
    keys = {
      {
        "<leader>mi",
        "<cmd>MoltenInit<cr>",
        desc = "Molten: init kernel",
        ft = { "python", "quarto" },
      },
      {
        "<leader>me",
        "<cmd>MoltenEvaluateOperator<cr>",
        desc = "Molten: evaluate operator",
        ft = { "python", "quarto" },
      },
      {
        "<leader>ml",
        "<cmd>MoltenEvaluateLine<cr>",
        desc = "Molten: evaluate line",
        ft = { "python", "quarto" },
      },
      {
        "<leader>mv",
        "<cmd>MoltenEvaluateVisual<cr>",
        desc = "Molten: evaluate visual",
        mode = "v",
        ft = { "python", "quarto" },
      },
      {
        "<leader>mr",
        "<cmd>MoltenReevaluateCell<cr>",
        desc = "Molten: re-evaluate cell",
        ft = { "python", "quarto" },
      },
      {
        "<leader>md",
        "<cmd>MoltenDelete<cr>",
        desc = "Molten: delete cell",
        ft = { "python", "quarto" },
      },
      {
        "<leader>mo",
        "<cmd>MoltenShowOutput<cr>",
        desc = "Molten: show output",
        ft = { "python", "quarto" },
      },
      {
        "<leader>mh",
        "<cmd>MoltenHideOutput<cr>",
        desc = "Molten: hide output",
        ft = { "python", "quarto" },
      },
    },
  },

  -- Open .ipynb as .py with # %% cell separators
  {
    "GCBallesteros/jupytext.nvim",
    opts = {
      style = "markdown",
      output_extension = "auto",
      force_ft = nil,
    },
  },

  -- .qmd polyglot support (quarto documents)
  {
    "quarto-dev/quarto-nvim",
    dependencies = { "jmbuhr/otter.nvim" },
    ft = { "quarto" },
    opts = {
      codeRunner = {
        enabled = true,
        default_method = "molten",
      },
    },
  },

  -- LSP + completions inside code blocks in qmd/ipynb-as-py
  {
    "jmbuhr/otter.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = true,
    opts = {},
  },

  -- Inline images via kitty graphics protocol
  {
    "3rd/image.nvim",
    ft = { "markdown", "quarto" },
    opts = {
      backend = "kitty",
      integrations = {
        markdown = { enabled = true, clear_in_insert_mode = false, download_remote_images = false },
        neorg = { enabled = false },
        typst = { enabled = false },
      },
      max_width = 80,
      max_height = 20,
      max_height_window_percentage = 0.4,
      max_width_window_percentage = 0.6,
      window_overlap_clear_enabled = true,
    },
  },
}
