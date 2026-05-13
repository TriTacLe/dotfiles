-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Theme toggle: switch between light and dark
vim.keymap.set("n", "<leader>uN", function()
  local current = vim.g.colors_name
  if current == "tokyonight-day" or current == "catppuccin-latte" then
    vim.cmd("colorscheme tokyonight")
  else
    vim.cmd("colorscheme tokyonight-day")
  end
end, { desc = "Theme: Toggle Light/Dark" })

-- Theme picker (fixed - ensure telescope is loaded)
vim.keymap.set("n", "<leader>uT", function()
  require("telescope.builtin").colorscheme({ enable_preview = true })
end, { desc = "Theme: Picker" })
