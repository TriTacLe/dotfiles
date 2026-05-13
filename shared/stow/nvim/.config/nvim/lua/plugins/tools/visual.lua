-- Cross-language visual feedback

return {
  -- Sticky scope header showing enclosing def/class at top of buffer
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      max_lines = 3,
      multiline_threshold = 5,
      mode = "cursor",
    },
    keys = {
      { "<leader>uC", "<cmd>TSContextToggle<cr>", desc = "Toggle treesitter context" },
    },
  },

  -- Treesitter-based folds with peek popup
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    opts = {
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
    },
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zp", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
    },
  },

  -- Status column with fold marks (pairs with ufo)
  {
    "luukvbaal/statuscol.nvim",
    event = "BufReadPost",
    opts = function()
      local builtin = require("statuscol.builtin")
      return {
        relculright = true,
        segments = {
          { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
          { text = { "%s" }, click = "v:lua.ScSa" },
          { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
        },
      }
    end,
  },

  -- Rainbow brackets via treesitter
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "BufReadPost",
  },

  -- Inline variable values during debug sessions
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = { commented = true },
  },

  -- Symbol outline tree (Class/Function/Method)
  {
    "stevearc/aerial.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      backends = { "treesitter", "lsp" },
      filter_kind = { "Class", "Function", "Method", "Constructor", "Interface", "Module", "Struct", "Type" },
      layout = { min_width = 28 },
      show_guides = true,
    },
    keys = {
      { "<leader>cs", "<cmd>AerialToggle<cr>", desc = "Symbol outline" },
    },
  },
}
