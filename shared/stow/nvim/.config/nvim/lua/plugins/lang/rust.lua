-- Rust utviklingsoppsett

return {
  -- rust-analyzer med gode instillinger
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
              -- Kodelinser
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
              -- Sjekk med clippy ved lagring
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              -- Prosedyre-makroer
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

  -- Installer Rust-verktøy (rust-analyzer handtert av LazyVim rust extra)
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "taplo", -- TOML LSP (Cargo.toml)
      })
    end,
  },

  -- Rust-filer i treesitter
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

  -- Test runner med neotest-rust
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
