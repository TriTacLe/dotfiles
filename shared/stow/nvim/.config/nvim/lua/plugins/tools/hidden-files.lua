-- Show dotfiles and gitignored files in snacks explorer and file picker
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = { hidden = true, ignored = true },
          files = { hidden = true, ignored = true },
        },
      },
    },
  },
}
