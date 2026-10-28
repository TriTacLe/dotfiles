-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Session only. Startup reads theme_current.lua, which theme_apply.sh writes.
vim.keymap.set("n", "<leader>uN", function()
  local light = vim.g.colors_name == "catppuccin-latte"
  vim.cmd("colorscheme " .. (light and "catppuccin-mocha" or "catppuccin-latte"))
end, { desc = "Theme: Toggle Light/Dark" })

vim.keymap.set("n", "<leader>uT", function()
  Snacks.picker.colorschemes()
end, { desc = "Theme: Picker" })
