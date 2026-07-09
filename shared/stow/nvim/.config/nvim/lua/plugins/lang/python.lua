-- Python utviklingsoppsett

return {
  -- Bytt til basedpyright (strengere type-inferens enn pyright)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = { enabled = false },
        basedpyright = {
          enabled = true,
          settings = {
            basedpyright = {
              typeCheckingMode = "standard",
              analysis = {
                autoImportCompletions = true,
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
      },
    },
  },

  -- Installer Python-verktøy
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "debugpy", -- Debugger
        "mypy",    -- Statisk type-sjekker
      })
    end,
  },

  -- Python-filer i treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "python",
        "toml",
        "requirements", -- requirements.txt
      })
    end,
  },

  -- Formatter: ruff for Python
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
      },
    },
  },

  -- Debugging med debugpy
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local venv = vim.fn.getcwd() .. "/.venv/bin/python"
      local fallback = vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
      require("dap-python").setup(vim.fn.filereadable(venv) == 1 and venv or fallback)
    end,
    keys = {
      { "<leader>td", function() require("dap-python").debug_selection() end, desc = "Debug Python utvalg", ft = "python" },
      { "<leader>tm", function() require("dap-python").test_method() end, desc = "Debug pytest metode", ft = "python" },
      { "<leader>tc", function() require("dap-python").test_class() end, desc = "Debug pytest klasse", ft = "python" },
    },
  },

  -- Test runner med neotest-python (pytest)
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
          python = function()
            local venv = vim.fn.getcwd() .. "/.venv/bin/python"
            return vim.fn.filereadable(venv) == 1 and venv or "python3"
          end,
          args = { "--tb=short", "-v" },
        },
      },
    },
  },

  -- Automatisk aktiver venv i prosjektet
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    ft = "python",
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = false,
        },
      },
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Velg Python venv", ft = "python" },
    },
  },

  -- Docstring generator (Google style)
  {
    "danymat/neogen",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      snippet_engine = "luasnip",
      languages = {
        python = { template = { annotation_convention = "google" } },
      },
    },
    keys = {
      { "<leader>cn", function() require("neogen").generate() end, desc = "Generate docstring", ft = "python" },
      { "<leader>cN", function() require("neogen").generate({ type = "class" }) end, desc = "Generate class docstring", ft = "python" },
    },
  },

  -- IPython REPL
  {
    "Vigemus/iron.nvim",
    ft = "python",
    config = function()
      require("iron.core").setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            python = require("iron.fts.python").ipython,
          },
          repl_open_cmd = "horizontal bot 15 split",
        },
        keymaps = {
          send_motion = "<leader>rc",
          visual_send = "<leader>rv",
          send_file = "<leader>rf",
          send_line = "<leader>rr",
          send_paragraph = "<leader>rp",
          cr = "<leader>r<cr>",
          interrupt = "<leader>ri",
          exit = "<leader>rq",
          clear = "<leader>rl",
        },
        highlight = { italic = true },
        ignore_blank_lines = true,
      })
    end,
    keys = {
      { "<leader>rs", "<cmd>IronRepl<cr>", desc = "Start IPython REPL", ft = "python" },
      { "<leader>rr", desc = "Send line to REPL", ft = "python" },
      { "<leader>rv", desc = "Send visual to REPL", mode = "v", ft = "python" },
      { "<leader>rf", desc = "Send file to REPL", ft = "python" },
      { "<leader>rq", desc = "Exit REPL", ft = "python" },
      { "<leader>rl", desc = "Clear REPL", ft = "python" },
    },
  },

  -- pytest coverage gutters
  {
    "andythigpen/nvim-coverage",
    ft = "python",
    opts = {
      auto_reload = true,
      lang = {
        python = {
          coverage_command = "pytest --cov --cov-report json",
          coverage_file = "coverage.json",
        },
      },
    },
    keys = {
      { "<leader>tcl", "<cmd>CoverageLoad<cr>", desc = "Load coverage", ft = "python" },
      { "<leader>tcs", "<cmd>CoverageSummary<cr>", desc = "Coverage summary", ft = "python" },
      { "<leader>tct", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage signs", ft = "python" },
    },
  },

  -- Refactoring: extract function/variable, inline
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    ft = "python",
    opts = {},
    keys = {
      { "<leader>re", function() require("refactoring").refactor("Extract Function") end, desc = "Extract function", mode = "v", ft = "python" },
      { "<leader>rv", function() require("refactoring").refactor("Extract Variable") end, desc = "Extract variable", mode = "v", ft = "python" },
      { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, desc = "Inline variable", mode = { "n", "v" }, ft = "python" },
    },
  },

  -- Lualine: show active venv name in statusline
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        function()
          local ok, vs = pcall(require, "venv-selector")
          if not ok then return "" end
          local v = vs.venv()
          return v and ("venv:" .. vim.fn.fnamemodify(v, ":t")) or ""
        end,
        cond = function() return vim.bo.filetype == "python" end,
      })
    end,
  },

  -- Python filetype options (ruff line length = 88)
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          vim.opt_local.colorcolumn = "88"
          vim.opt_local.textwidth = 88
          vim.opt_local.expandtab = true
          vim.opt_local.shiftwidth = 4
          vim.opt_local.tabstop = 4
          vim.opt_local.softtabstop = 4
        end,
      })
    end,
  },

  -- F-string toggle: "..." <-> f"..." on string under cursor
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, _)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function(ev)
          vim.keymap.set("n", "<leader>cf", function()
            local node = vim.treesitter.get_node()
            while node and node:type() ~= "string" do
              node = node:parent()
            end
            if not node then return end
            local sr, sc = node:start()
            local line = vim.api.nvim_buf_get_lines(ev.buf, sr, sr + 1, false)[1]
            local col = sc + 1
            local ch = line:sub(col, col)
            if ch == "f" or ch == "F" then
              -- strip f-prefix
              vim.api.nvim_buf_set_text(ev.buf, sr, sc, sr, sc + 1, {})
            else
              -- add f-prefix
              vim.api.nvim_buf_set_text(ev.buf, sr, sc, sr, sc, { "f" })
            end
          end, { buffer = ev.buf, desc = "Toggle f-string" })
        end,
      })
    end,
  },
}
