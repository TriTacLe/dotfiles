-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- Profile overrides, linked to lua/config/local.lua by `just profile`.
pcall(require, "config.local")
