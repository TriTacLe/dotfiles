--       ░▒▒▒▒▒▒▒░░░
--     ░░▒▒▒▒▒▒░░░░▓▓
--    ░░▒▒▒▒▒░░░░░▓▓
--   ░░░▒▒▒░░░░░░▓▓
--   ░░░▒▒▒░░░░░▓▓▓▓▓▓
--    ░░░▒▒░░░░▓▓   ▓▓
--     ░░▒▒▓▓   ▓▓ YPRLAND config
--
-- Split across one file per concern. Hyprland scopes require() per file, so an
-- error in one of them does not take the rest of the config down.
--
-- Order matters: theme defines the palette looknfeel reads, and monitors runs
-- before anything that depends on an output existing.

require("theme")

-- Monitor setup, see https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Generic fallback + EDID-based rules in monitors.lua, host-specific override in host.lua
require("monitors")

require("env")
require("looknfeel")
require("input")
require("animations")
require("keybindings")
require("windowrules")

-- host.lua ships in the per-machine hypr-host package. pcall keeps the rest of
-- this file alive on machines where that package is not stowed. It loads last
-- so a host override actually overrides: when it ran before input.lua, anything
-- input.lua also set was silently written back over the top of it.
pcall(require, "host")

require("autostart")

