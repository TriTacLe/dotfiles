-- Rust development setup

return {
  -- rust-analyzer with tuned settings
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              -- Inlay hints
              inlayHints = {
                bindingModeHints = { enable = true },
                chainingHints = { enable = true },
                closingBraceHints = { enable = true, minLines = 10 },
                closureReturnTypeHints = { enable = "with_block" },
                lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
                maxLength = { enable = true, value = 25 },
                parameterHints = { enable = true },
                reborrowHints = { enable = "skip_trivial" },
                renderColons = { enable = true },
                typeHints = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
              },
              -- Code lenses
              lens = {
                enable = true,
                run = { enable = true },
                debug = { enable = true },
                implementations = { enable = true },
                references = {
                  adt = { enable = true },
                  enumVariant = { enable = true },
                  method = { enable = true },
                  trait = { enable = true },
                },
              },
              -- Check with clippy on save
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              -- Procedural macros
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
            },
          },
        },
      },
    },
  },

  -- Install Rust tools (rust-analyzer is handled by the LazyVim rust extra)
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "taplo", -- TOML LSP (Cargo.toml)
      })
    end,
  },

  -- Rust files in treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "rust",
        "toml",
        "ron",
      })
    end,
  },

  -- Test runner with neotest-rust
  {
    "nvim-neotest/neotest",
    dependencies = {
      "rouge8/neotest-rust",
    },
    opts = {
      adapters = {
        ["neotest-rust"] = {
          args = { "--no-capture" },
        },
      },
    },
  },
}
