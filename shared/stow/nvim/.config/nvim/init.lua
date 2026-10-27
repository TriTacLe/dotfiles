-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Personal overrides live outside the repo, linked from profiles/<user>/nvim.lua.
pcall(require, "config.local")
