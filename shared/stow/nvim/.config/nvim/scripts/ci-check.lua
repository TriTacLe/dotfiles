-- Headless smoke test for the Neovim config.
-- Run with:  nvim --headless -c "luafile scripts/ci-check.lua"
--
-- Catches config breakage: Lua errors in plugin setup, and treesitter parser or
-- query mismatches. It does not start language servers. Whether rust-analyzer
-- or jdtls is installed is an environment question, not a config bug, and real
-- servers make headless runs slow and prone to hanging on exit.
--
-- Plugins that need an external runtime (molten needs a Python host, vimtex
-- needs a TeX install) are deliberately not force-loaded, since failing on a
-- missing system package would keep CI red for no useful reason.

local errors = {}

-- Keep headless runs from blocking on a "press ENTER" prompt.
vim.o.more = false
vim.opt.shortmess:append("aF")

local NOISE = {
  "language server", "not installed", "executable", "mason",
  "no project root", "python3 provider", "treesitter cli",
}
local ERROR_SIGNATURES = {
  "attempt to call", "attempt to index", "attempt to perform", "nil value",
  "stack traceback", "query error", "error executing", "e5108", "e5113",
}

local function is_noise(line)
  local l = line:lower()
  for _, p in ipairs(NOISE) do
    if l:find(p) then
      return true
    end
  end
  return false
end

local function is_error(line)
  if is_noise(line) then
    return false
  end
  local l = line:lower()
  for _, sig in ipairs(ERROR_SIGNATURES) do
    if l:find(sig, 1, true) then
      return true
    end
  end
  return line:find("E%d%d%d") ~= nil
end

-- Capture real ERROR notifications, ignoring environment noise.
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if level == vim.log.levels.ERROR and not is_noise(tostring(msg)) then
    table.insert(errors, "notify: " .. tostring(msg):gsub("%s+", " "))
  end
  return orig_notify(msg, level, opts)
end

-- 1) Force-load the plugins whose config should run everywhere. A Lua error in
--    any of their setup functions surfaces here.
local core = {
  "LazyVim",
  "snacks.nvim",
  "nvim-lspconfig",
  "mason.nvim",
  "nvim-treesitter",
  "conform.nvim",
  "nvim-lint",
  "lualine.nvim",
  "LuaSnip",
  "nvim-dap",
  "which-key.nvim",
  "gitsigns.nvim",
}
for _, p in ipairs(core) do
  local ok, err = pcall(function()
    require("lazy").load({ plugins = { p } })
  end)
  if not ok then
    table.insert(errors, "load " .. p .. ": " .. tostring(err))
  end
end

-- 2) Treesitter: parse a sample per language on a scratch buffer. Passing the
--    language explicitly means no FileType event fires, so no LSP attaches.
--
--    Parsers have to be installed synchronously first. Left to itself
--    vim.treesitter.start kicks off a background download and fails on the spot,
--    so whichever language happens to be slowest that run goes red.
local samples = {
  lua = "local a = 1",
  python = "def f():\n    return 1",
  rust = "fn main() {}",
  go = "package main",
  java = "class A {}",
  cpp = "int main() { return 0; }",
  typescript = "const a: number = 1",
  tsx = "const C = () => null",
  html = "<div></div>",
  css = ".a { color: red }",
  bash = "echo hi",
  json = '{"a": 1}',
  yaml = "a: 1",
  toml = "a = 1",
  markdown = "# hi",
  sql = "select 1;",
}
local langs = vim.tbl_keys(samples)
table.sort(langs)

local ok_ts, ts = pcall(require, "nvim-treesitter")
if ok_ts and type(ts.install) == "function" then
  local ok_install, err = pcall(function()
    ts.install(langs):wait(600000)
  end)
  if not ok_install then
    table.insert(errors, "treesitter install: " .. tostring(err))
  end
end

for _, lang in ipairs(langs) do
  local code = samples[lang]
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(code, "\n"))
  local ok, err = pcall(vim.treesitter.start, buf, lang)
  if not ok then
    table.insert(errors, "treesitter " .. lang .. ": " .. tostring(err))
  end
  pcall(vim.api.nvim_buf_delete, buf, { force = true })
end

-- Let scheduled callbacks run, then scan the message log.
vim.wait(500)
local msgs = vim.api.nvim_exec2("messages", { output = true }).output or ""
for line in msgs:gmatch("[^\n]+") do
  if is_error(line) then
    table.insert(errors, "message: " .. line)
  end
end

if #errors > 0 then
  io.stderr:write("\nFAILED: Neovim config check found " .. #errors .. " issue(s):\n")
  for _, e in ipairs(errors) do
    io.stderr:write("  - " .. e .. "\n")
  end
  vim.cmd("cquit 1")
else
  io.stderr:write("\nOK: config loaded cleanly (core plugins + treesitter)\n")
  vim.cmd("qa!")
end
