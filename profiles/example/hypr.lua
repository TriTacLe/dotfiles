-- Profile-specific Hyprland config, linked to ~/.config/hypr/host_local.lua by
-- `just profile`. Loads after every tracked file, so anything set here wins.
-- Hyprland scopes each file, so helpers from keybindings.lua are not in scope.

-- Keyboard layout, when it differs from the machine's host.lua
-- hl.config({ input = { kb_layout = "us" } })

-- Monitor rules, see `hyprctl monitors all`
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Personal binds
-- hl.bind("CTRL + SHIFT + ALT + A", hl.dsp.exec_cmd("brave --new-window https://claude.ai/"))
-- hl.bind("SUPER + bracketleft", hl.dsp.exec_cmd('wtype "å"'))
