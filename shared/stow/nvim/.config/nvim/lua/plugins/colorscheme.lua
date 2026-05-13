-- Theme configuration
-- Change the colorscheme below to switch themes

return {
  -- Theme: Catppuccin (popular, many variants)
  -- https://github.com/catppuccin/nvim
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      -- flavour options: "latte" (light), "frappe", "macchiato", "mocha" (dark)
      flavour = "latte",
    },
  },

  -- Theme: Gruvbox (retro, easy on eyes)
  -- https://github.com/ellisonleao/gruvbox.nvim
  -- {
  --   "ellisonleao/gruvbox.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("gruvbox").setup({
  --       -- Set background before loading
  --       -- vim.o.background = "light" -- or "dark"
  --     })
  --   end,
  -- },

  -- Theme: Rose Pine (soft, elegant)
  -- https://github.com/rose-pine/neovim
  -- {
  --   "rose-pine/neovim",
  --   name = "rose-pine",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     -- variant options: "main" (dark), "moon", "dawn" (light)
  --     variant = "dawn",
  --   },
  -- },

  -- Theme: Solarized (classic, scientific)
  -- https://github.com/maxmx03/solarized.nvim
  -- {
  --   "maxmx03/solarized.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     -- style options: "dark" or "light"
  --     style = "light",
  --   },
  -- },

  -- ============================================
  -- ACTIVE THEME - Change this to switch themes
  -- ============================================
  {
    "LazyVim/LazyVim",
    opts = {
      -- Available themes (install above first if needed):
      -- Built-in: "tokyonight", "tokyonight-day", "tokyonight-moon", "tokyonight-night", "tokyonight-storm", "habamax"
      -- Catppuccin: "catppuccin", "catppuccin-latte", "catppuccin-frappe", "catppuccin-macchiato", "catppuccin-mocha"
      -- Gruvbox: "gruvbox" (set vim.o.background = "light"/"dark")
      -- Rose Pine: "rose-pine", "rose-pine-main", "rose-pine-moon", "rose-pine-dawn"
      -- Solarized: "solarized" (set style in opts above)
      colorscheme = "desert",
    },
  },
}
