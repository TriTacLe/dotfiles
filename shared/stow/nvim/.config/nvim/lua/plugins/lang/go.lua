-- Go development setup
-- Go configuration for Neovim

return {
  -- LazyVim's Go extra gives basic LSP
  { import = "lazyvim.plugins.extras.lang.go" },

  -- gopls with tuned settings
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              -- Use gofumpt, which is stricter than gofmt
              gofumpt = true,
              -- Code lenses (small actions in the code)
              codelenses = {
                gc_details = false,
                generate = true, -- For generate directives
                regenerate_cgo = true,
                run_govulncheck = true, -- Security check
                test = true, -- Run tests from the code
                tidy = true, -- go mod tidy
                upgrade_dependency = true, -- Upgrade packages
                vendor = true, -- go mod vendor
              },
              -- Inlay hints: show types inline
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              -- Static analysis
              analyses = {
                fieldalignment = true, -- Check struct size
                nilness = true, -- Check nil errors
                unusedparams = true, -- Unused parameters
                unusedwrite = true, -- Unused writes
                useany = true, -- Suggest any instead of interface{}
              },
              -- Insert placeholders for parameters
              usePlaceholders = true,
              -- Complete imports automatically
              completeUnimported = true,
              -- Run staticcheck for better analysis
              staticcheck = true,
              -- Ignore these directories
              directoryFilters = { "-node_modules", "-vendor", "-.git" },
              ui = {
                semanticTokens = true,
              },
            },
          },
        },
      },
    },
  },

  -- Install Go tools automatically
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "gopls", -- Go language server
        "delve", -- Debugger
        "gofumpt", -- Better formatting
        "goimports", -- Auto-import
        "gomodifytags", -- Edit struct tags
        "impl", -- Generate interface implementations
        "gotests", -- Generate tests
        "golangci-lint", -- Linting
        "buf", -- Protocol Buffers
        "protolint", -- Protobuf linting
      })
    end,
  },

  -- Go files in treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "go",
        "gomod",
        "gosum",
        "gowork",
        "templ", -- Templating for Go
      })
    end,
  },

  -- Auto-format with gofumpt and organise imports
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports" },
      },
    },
  },

  -- Debugging for Go
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    keys = {
      {
        "<leader>td",
        function()
          require("dap-go").debug_test()
        end,
        desc = "Debug Go test",
        ft = "go",
      },
      {
        "<leader>tD",
        function()
          require("dap-go").debug_last_test()
        end,
        desc = "Debug previous test",
        ft = "go",
      },
    },
  },

  -- Tools for struct tags (json, db, etc)
  {
    "crispgm/nvim-go",
    ft = "go",
    config = function()
      require("go").setup({
        notify = false,
        auto_format = false, -- We use conform instead
        auto_lint = false,
      })
    end,
    keys = {
      { "<leader>ctg", "<cmd>GoAddTags<cr>", desc = "Add struct tags" },
      { "<leader>ctG", "<cmd>GoRemoveTags<cr>", desc = "Remove struct tags" },
      { "<leader>ctf", "<cmd>GoFillStruct<cr>", desc = "Fill struct" },
      { "<leader>cti", "<cmd>GoImpl<cr>", desc = "Generate interface" },
    },
  },

  -- Test runner with UI
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-go",
    },
    opts = {
      adapters = {
        ["neotest-go"] = {
          experimental = {
            test_table = true, -- Support for table-driven tests
          },
          args = { "-count=1", "-timeout=60s" },
        },
      },
    },
  },

  -- Run Go code snippets
  {
    "michaelb/sniprun",
    build = "bash ./install.sh",
    keys = {
      { "<leader>rg", "<cmd>SnipRun<cr>", desc = "Run Go snippet" },
    },
    opts = {
      selected_interpreters = { "Go_original" },
    },
  },
}
