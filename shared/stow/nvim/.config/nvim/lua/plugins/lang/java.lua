-- Java and Spring Boot setup on top of LazyVim's java extra (imported in
-- config/lazy.lua). Diagnostics, LSP keys and mason entries the extra
-- already provides are not repeated here.

return {
  -- Rounded diagnostic float; everything else follows LazyVim defaults.
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        float = { border = "rounded", source = true },
      },
    },
  },
  -- JDTLS (Java språkserver) med Spring Boot tilpasninger
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- Utvid LazyVims standard JDTLS instillinger
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          -- Automatisk oppdatering når pom.xml/build.gradle endres
          configuration = {
            updateBuildConfiguration = "automatic",
          },
          -- Last ned kildekode for biblioteker (bra for debugging)
          maven = {
            downloadSources = true,
          },
          -- Vis hvor en metode er implementert
          implementationsCodeLens = {
            enabled = true,
          },
          -- Vis hvor en metode blir brukt
          referencesCodeLens = {
            enabled = true,
          },
          -- Inkluder dekompilerte kilder i søk
          references = {
            includeDecompiledSources = true,
          },
          -- Bruk Google Java Format
          format = {
            enabled = true,
          },
          -- Favoritt-metoder som dukker opp først i completion
          completion = {
            favoriteStaticMembers = {
              "org.assertj.core.api.Assertions.assertThat",
              "org.junit.jupiter.api.Assertions.*",
              "org.mockito.Mockito.*",
              "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
              "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
            },
            -- Ikke foreslå disse pakkene
            filteredTypes = {
              "com.sun.*",
              "io.micrometer.shaded.*",
              "java.awt.*",
              "jdk.*",
              "sun.*",
            },
          },
          -- Organiser imports - aldri bruk wildcard imports
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          -- Hvordan generere toString, equals, hashCode
          codeGeneration = {
            toString = {
              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
            },
            hashCodeEquals = {
              useJava7Objects = true,
            },
            useBlocks = true,
          },
        },
      })

      return opts
    end,
  },

  -- checkstyle is the one tool the java extra does not install.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "checkstyle" })
    end,
  },

  -- Checkstyle linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        java = { "checkstyle" },
      },
      linters = {
        checkstyle = {
          -- Bruk checkstyle.xml fra prosjektet hvis det finnes
          -- Ellers bruk standard Google Checkstyle
          args = {
            "-c",
            "/google_checks.xml", -- Standard Google checks
            "-f",
            "xml", -- XML format for parsing
            "--",
          },
          parser = function(output, bufnr)
            local diagnostics = {}
            if output == "" then
              return diagnostics
            end
            -- Parse XML output from checkstyle
            for line in output:gmatch("[^\r\n]+") do
              local file, line_nr, col, severity, msg =
                line:match('<error line="(%d+)" column="(%d+)" severity="(%w+)" message="([^"]+)"')
              if line_nr then
                table.insert(diagnostics, {
                  lnum = tonumber(line_nr) - 1,
                  col = tonumber(col) or 0,
                  message = msg or "Checkstyle error",
                  severity = severity == "error" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
                  source = "checkstyle",
                })
              end
            end
            return diagnostics
          end,
        },
      },
    },
  },

  -- Signature help while typing; the blink extra leaves it off.
  {
    "saghen/blink.cmp",
    opts = { signature = { enabled = true } },
  },

  -- JPA Repository snippets - dette er gullverdt!
  -- Skriv f.eks. "findBy" + Tab så får du mal for metoden
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = {
      history = true,
      deleteCheckEvents = "TextChanged",
    },
    config = function(_, opts)
      require("luasnip").setup(opts)

      -- Last inn standard snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Mine egne JPA snippets for Spring Boot
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      ls.add_snippets("java", {
        -- Basis CRUD
        s("findById", {
          t("Optional<"),
          i(1, "Entity"),
          t("> findById(Long id);"),
        }),
        s("findAll", {
          t("List<"),
          i(1, "Entity"),
          t("> findAll();"),
        }),
        s("save", {
          i(1, "Entity"),
          t(" save("),
          i(1),
          t(" entity);"),
        }),
        s("deleteById", {
          t("void deleteById(Long id);"),
        }),

        -- Spørringer med findBy
        s("findBy", {
          t("Optional<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("("),
          i(3, "Type"),
          t(" "),
          i(4, "field"),
          t(");"),
        }),
        s("findAllBy", {
          t("List<"),
          i(1, "Entity"),
          t("> findAllBy"),
          i(2, "Field"),
          t("("),
          i(3, "Type"),
          t(" "),
          i(4, "field"),
          t(");"),
        }),
        s("findByAnd", {
          t("Optional<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field1"),
          t("And"),
          i(3, "Field2"),
          t("("),
          i(4, "Type1"),
          t(" "),
          i(5, "field1"),
          t(", "),
          i(6, "Type2"),
          t(" "),
          i(7, "field2"),
          t(");"),
        }),
        s("findByOr", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field1"),
          t("Or"),
          i(3, "Field2"),
          t("("),
          i(4, "Type1"),
          t(" "),
          i(5, "field1"),
          t(", "),
          i(6, "Type2"),
          t(" "),
          i(7, "field2"),
          t(");"),
        }),
        s("findByLike", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("Containing(String "),
          i(3, "search"),
          t(");"),
        }),
        s("findByStartingWith", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("StartingWith(String "),
          i(3, "prefix"),
          t(");"),
        }),
        s("findByEndingWith", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("EndingWith(String "),
          i(3, "suffix"),
          t(");"),
        }),
        s("findByGreaterThan", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("GreaterThan("),
          i(3, "Type"),
          t(" "),
          i(4, "value"),
          t(");"),
        }),
        s("findByLessThan", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("LessThan("),
          i(3, "Type"),
          t(" "),
          i(4, "value"),
          t(");"),
        }),
        s("findByBetween", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("Between("),
          i(3, "Type"),
          t(" start, "),
          i(3),
          t(" end);"),
        }),
        s("findByIsNull", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("IsNull();"),
        }),
        s("findByIsNotNull", {
          t("List<"),
          i(1, "Entity"),
          t("> findBy"),
          i(2, "Field"),
          t("IsNotNull();"),
        }),
        s("findByOrderBy", {
          t("List<"),
          i(1, "Entity"),
          t("> findAllByOrderBy"),
          i(2, "Field"),
          t("Asc();"),
        }),
        s("findTopBy", {
          t("Optional<"),
          i(1, "Entity"),
          t("> findTopByOrderBy"),
          i(2, "Field"),
          t("Desc();"),
        }),
        s("findFirstBy", {
          t("Optional<"),
          i(1, "Entity"),
          t("> findFirstBy"),
          i(2, "Field"),
          t("("),
          i(3, "Type"),
          t(" "),
          i(4, "value"),
          t(");"),
        }),

        -- Count og exists
        s("countBy", {
          t("long countBy"),
          i(1, "Field"),
          t("("),
          i(2, "Type"),
          t(" "),
          i(3, "value"),
          t(");"),
        }),
        s("existsBy", {
          t("boolean existsBy"),
          i(1, "Field"),
          t("("),
          i(2, "Type"),
          t(" "),
          i(3, "value"),
          t(");"),
        }),

        -- Egne SQL spørringer med @Query
        s("query", {
          t('@Query("'),
          i(1, "SELECT e FROM Entity e WHERE e.field = ?1"),
          t('")'),
          t({ "", "" }),
          i(2, "ReturnType"),
          t(" "),
          i(3, "methodName"),
          t("("),
          i(4, "Params"),
          t(");"),
        }),

        -- Mal for hele repository interfacet
        s("repo", {
          t("public interface "),
          i(1, "Entity"),
          t("Repository extends JpaRepository<"),
          i(1),
          t(", Long> {"),
          t({ "", "}" }),
        }),
      })
    end,
  },

  -- HTTP client for å teste REST API-er
  -- Bra for Spring Boot Controllers
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>th", "<cmd>lua require('kulala').run()<cr>", desc = "Kjør HTTP request" },
      { "<leader>tj", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Neste HTTP request" },
      { "<leader>tk", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Forrige HTTP request" },
    },
    opts = {},
  },

  -- Java adapter for neotest. Keys come from LazyVim's test extra.
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-plenary", "rcasia/neotest-java" },
    opts = {
      adapters = {
        ["neotest-java"] = {},
        ["neotest-plenary"] = {},
      },
    },
  },

  -- Bokmerker for hurtignavigasjon
  -- F.eks. Controller -> Service -> Repository
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    opts = {
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
      settings = {
        save_on_toggle = true,
      },
    },
    keys = {
      {
        "<leader>ha",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Legg til bokmerke",
      },
      {
        "<leader>hh",
        function()
          require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
        end,
        desc = "Åpne bokmerker",
      },
      {
        "<leader>h1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Bokmerke 1",
      },
      {
        "<leader>h2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Bokmerke 2",
      },
      {
        "<leader>h3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Bokmerke 3",
      },
      {
        "<leader>h4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Bokmerke 4",
      },
    },
  },
}
