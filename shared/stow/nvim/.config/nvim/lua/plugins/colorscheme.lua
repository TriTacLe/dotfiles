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
    opts = {
      flavour = "mocha",
      -- Upstream Latte fails WCAG AA on a white background: blue 4.34, green 2.96,
      -- yellow 2.31. These are the same values theme_apply.sh writes for the terminal,
      -- darkened to 4.5 while keeping hue. Regenerate from themes/catppuccin-latte.json.
      color_overrides = {
        latte = {
          base = "#eff1f5",
          mantle = "#e6e9ef",
          crust = "#dce0e8",
          text = "#4c4f69",
          subtext0 = "#5c5f77",
          subtext1 = "#676a7f",
          surface0 = "#ccd0da",
          surface1 = "#bcc0cc",
          surface2 = "#acb0be",
          overlay0 = "#82889c",
          overlay1 = "#84879a",
          overlay2 = "#7c7f93",
          blue = "#145ff5",
          sapphire = "#187585",
          peach = "#bc4501",
          green = "#307820",
          red = "#d20f39",
          mauve = "#8839ef",
          pink = "#c31e97",
          yellow = "#976014",
          maroon = "#d21c2c",
          teal = "#12747a",
        },
      },
    },
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
