# Neovim plugins

Plugin configuration on top of LazyVim.

## Layout

- `lang/`: one file per language. `java.lua` (Java and Spring Boot), `go.lua`, `rust.lua`,
  `cpp.lua`, `frontend.lua` (Vue, Next.js, React, TypeScript).
- `tools/`: `dap.lua` (debugging), `hidden-files.lua` (show dotfiles such as `.env`),
  `markdown-preview.lua`, `peek.lua`, `glow.lua`, `wakatime.lua`.
- `../utils.lua`: helpers. It lives in `lua/`, not `lua/plugins/`, because LazyVim loads
  everything under `plugins/` as a plugin spec.
- `../config/local.lua`: profile overrides, linked by `just profile`, loaded last.

## Languages

### Java (`java.lua`)

Spring Boot projects: LSP with completion, debugging, JPA snippets (`findBy` + Tab expands
to repository method templates), test running and an HTTP client for trying endpoints.

- `<leader>th` runs the HTTP request under the cursor.
- `<leader>tt` runs tests.

### Go (`go.lua`)

gopls, Delve, format on save with gofumpt, a test runner and struct tag tools.

- `<leader>td` debugs the test under the cursor.
- `<leader>ctg` adds struct tags.

### Frontend (`frontend.lua`)

TypeScript and Vue language servers, ESLint, Prettier, Tailwind CSS, and npm package
versions shown inline in `package.json`.

- `<leader>ns` shows package versions.

## Tools

- `dap.lua`: debugging for Java and Go.
- `hidden-files.lua`: shows dotfiles such as `.env` in the file explorer. `H` toggles.
- `markdown-*.lua`: three ways to preview Markdown: browser, floating window, terminal.
- `wakatime.lua`: time tracking.

## Adding a plugin

1. Create a `.lua` file in the right directory.
2. Return a table with the plugin spec.
3. Restart Neovim; lazy.nvim handles the rest.

```lua
-- lua/plugins/tools/my-plugin.lua
return {
  {
    "author/name",
    config = function()
      require("name").setup()
    end,
  },
}
```

## Utils

`lua/utils.lua` provides `has(plugin)`, `git_root()` and `safe_require()`.

```lua
local utils = require("utils")  -- not "plugins.utils"
if utils.has("neo-tree.nvim") then
  -- ...
end
```

## Language extras

`lua/config/lazy.lua` imports the LazyVim extras for Java, TypeScript, Vue, Tailwind, Go,
Rust, clangd, CMake, Python and SQL. They give the base LSP setup; the files in `lang/`
extend them.
