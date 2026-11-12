-- Frontend development for Vue, Next.js, React, TypeScript

return {
  -- TypeScript support (tsserver, eslint, prettier)
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- Vue.js support
  { import = "lazyvim.plugins.extras.lang.vue" },

  -- Tailwind CSS support
  { import = "lazyvim.plugins.extras.lang.tailwind" },

  -- Language server configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript (vtsls is faster than tsserver)
        vtsls = {
          settings = {
            typescript = {
              -- Inlay hints: show types inline
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
              -- Relative imports (not @/...)
              preferences = {
                importModuleSpecifier = "relative",
              },
            },
          },
        },
        -- ESLint for error checking
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
          },
        },
        -- Vue Language Server
        volar = {
          init_options = {
            vue = {
              hybridMode = true, -- Better performance
            },
          },
        },
      },
    },
  },

  -- Install frontend tools
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vtsls", -- TypeScript language server
        "eslint-lsp", -- ESLint
        "prettier", -- Formatting
        "vue-language-server", -- Vue
        "css-lsp", -- CSS
        "cssmodules-language-server", -- CSS Modules
        "html-lsp", -- HTML
        "json-lsp", -- JSON
        "tailwindcss-language-server", -- Tailwind
        "graphql-language-service-cli", -- GraphQL
      })
    end,
  },

  -- Frontend files in treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vue",
        "svelte",
        "css",
        "scss",
        "html",
        "json",
        "jsonc",
        "graphql",
      })
    end,
  },

  -- Prettier for formatting frontend files
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
      },
    },
  },

  -- Show npm package versions in package.json
  -- Useful to see whether packages are outdated
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
    ft = "json",
    keys = {
      { "<leader>ns", "<cmd>lua require('package-info').show()<cr>", desc = "Show package version" },
      { "<leader>nc", "<cmd>lua require('package-info').hide()<cr>", desc = "Hide package version" },
      { "<leader>nt", "<cmd>lua require('package-info').toggle()<cr>", desc = "Toggle package info" },
      { "<leader>nu", "<cmd>lua require('package-info').update()<cr>", desc = "Update package" },
      { "<leader>nd", "<cmd>lua require('package-info').delete()<cr>", desc = "Delete package" },
      { "<leader>ni", "<cmd>lua require('package-info').install()<cr>", desc = "Install package" },
      { "<leader>np", "<cmd>lua require('package-info').change_version()<cr>", desc = "Change package version" },
    },
  },
}
