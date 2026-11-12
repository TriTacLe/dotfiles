-- Helpers used by several plugins
-- Put things here that more than one plugin needs

local M = {}

-- Check whether a plugin is installed
-- Usage: if utils.has("neo-tree.nvim") then ... end
function M.has(plugin)
  return require("lazy.core.config").plugins[plugin] ~= nil
end

-- Get the options of a plugin
function M.opts(plugin)
  return require("lazy.core.config").plugins[plugin] or {}
end

-- Safe require that returns nil when the module is missing
-- Avoids a crash when a plugin is absent
function M.safe_require(module)
  local ok, result = pcall(require, module)
  if ok then
    return result
  end
  return nil
end

-- Check whether we are inside a git repository
function M.is_git_repo()
  local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("true") ~= nil
  end
  return false
end

-- Get the git root directory
-- Returns nil outside a git repo
function M.git_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    return result ~= "" and result or nil
  end
  return nil
end

return M
