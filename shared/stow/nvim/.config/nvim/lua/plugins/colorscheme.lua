-- The active colorscheme follows the desktop theme: theme_apply.sh writes
-- lua/theme_current.lua with the name from the theme JSON. <leader>uN and
-- <leader>uT still switch within a session.

local ok, current = pcall(require, "theme_current")
local colorscheme = ok and current.colorscheme or "desert"

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = { flavour = "mocha" },
  },
  -- lazy.nvim loads these on demand when their colorscheme name is requested.
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "shaunsingh/nord.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = colorscheme },
  },
}
