-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.g.lazyvim_python_lsp = "basedpyright"

-- Builtin sql ftplugin hijacks <Right>/<Left>/<C-C> in insert mode (sqlcomplete drill maps)
vim.g.omni_sql_no_default_maps = 1

-- STM32 prac task files (main.c1..main.c6) are plain C
vim.filetype.add({ pattern = { [".*%.c[1-6]"] = "c" } })
