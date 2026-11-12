-- C/C++ development setup

return {
  -- clangd with tuned settings
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          keys = {
            { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch between header and source" },
          },
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, {
              "Makefile",
              "configure.ac",
              "configure.in",
              "config.h.in",
              "meson.build",
              "meson_options.txt",
              "build.ninja",
            }) or vim.fs.root(bufnr, {
              "compile_commands.json",
              "compile_flags.txt",
            }) or vim.fs.root(bufnr, ".git")
            if root then
              on_dir(root)
            end
          end,
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          settings = {
            clangd = {
              InlayHints = {
                Designators = true,
                Enabled = true,
                ParameterNames = true,
                DeducedTypes = true,
              },
            },
          },
        },
      },
    },
  },

  -- Install C++ tools
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      -- clangd + cmake-language-server handled by LazyVim extras
      vim.list_extend(opts.ensure_installed, {
        "clang-format", -- Formatting
        "codelldb", -- Debugger
        "cmakelang", -- CMake formatting + lint
      })
    end,
  },

  -- C/C++ files in treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "c",
        "cpp",
        "cmake",
        "make",
      })
    end,
  },

  -- clang-format for formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
      },
    },
  },

  -- Debugging with codelldb
  {
    "mfussenegger/nvim-dap",
    config = function(_, opts)
      local dap = require("dap")
      if not dap.adapters.codelldb then
        dap.adapters.codelldb = {
          type = "server",
          port = "${port}",
          executable = {
            command = vim.fn.exepath("codelldb"),
            args = { "--port", "${port}" },
          },
        }
      end
      for _, lang in ipairs({ "c", "cpp" }) do
        dap.configurations[lang] = dap.configurations[lang] or {}
        table.insert(dap.configurations[lang], {
          type = "codelldb",
          request = "launch",
          name = "Launch (codelldb)",
          program = function()
            return vim.fn.input("Path to binary: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        })
      end
    end,
  },
}
