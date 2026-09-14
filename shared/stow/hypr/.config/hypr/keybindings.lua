-- Keybindings, see https://wiki.hypr.land/Configuring/Basics/Binds/

local mod = "SUPER"
local alt = "MOD5" -- alternate modifier, right Alt on some layouts
local scripts = "~/.config/hypr/scripts"

-- Under uwsm, launch into app.slice as its own scope so the oomd drop-in
-- there applies. A plain session falls through to the bare command.
local function app(cmd)
    return "if systemctl --user -q is-active wayland-wm@*.service; then exec uwsm app -- "
        .. cmd .. "; else exec " .. cmd .. "; fi"
end


-- Window controls

hl.bind(mod .. " + Q", hl.dsp.exec_cmd(app("ghostty")))                          -- Open terminal
hl.bind(mod .. " + X", hl.dsp.exec_cmd(scripts .. "/kill_confirm.sh"))      -- Close window with confirmation
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))          -- Toggle floating
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())                          -- Toggle fullscreen

-- Alternative terminal (disabled)
-- hl.bind(mod .. " + Q", hl.dsp.exec_cmd("alacritty"))


-- Application launchers

hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(app("wofi")))                         -- App launcher
hl.bind(mod .. " + E", hl.dsp.exec_cmd(app("thunar")))                           -- File manager (Thunar)
hl.bind(mod .. " + W", hl.dsp.exec_cmd(app("firefox")))                          -- Browser (Firefox)
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(app("brave")))                    -- Browser (Brave)
hl.bind(mod .. " + R", hl.dsp.exec_cmd(app("obsidian --ozone-platform-hint=auto"))) -- Obsidian


-- System controls

hl.bind(mod .. " + O", hl.dsp.exec_cmd(app("hyprlock")))                         -- Lock screen
hl.bind(mod .. " + U", hl.dsp.exec_cmd(app("wlogout --protocol layer-shell")))   -- Logout menu
hl.bind(mod .. " + SHIFT + M", hl.dsp.exit())                               -- Exit Hyprland


-- Window navigation (VIM style)

hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))


-- Workspace navigation

-- Direct workspace access, and move window to workspace with SHIFT
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Relative workspace navigation
hl.bind(mod .. " + D", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + A", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + D", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "r-1" }))

-- Special workspace (scratchpad)
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special())

-- Hyprswitch, requires 'hyprswitch init --daemon' in autostart
-- hl.bind("ALT + Tab", hl.dsp.exec_cmd("hyprswitch simple --next"))
-- hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("hyprswitch simple --prev"))

-- Alt+Tab for workspace switching (Mac Mission Control style)
hl.bind("ALT + Tab", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("ALT + SHIFT + Tab", hl.dsp.focus({ workspace = "r-1" }))


-- Quick launch shortcuts

hl.bind("CTRL + SHIFT + B", hl.dsp.exec_cmd(app("brave --new-window https://www.bible.com/bible/111/MAT.1.NIV")))
hl.bind("CTRL + SHIFT + ALT + E", hl.dsp.exec_cmd(app("brave --new-window https://chat.openai.com/")))
hl.bind("CTRL + SHIFT + ALT + A", hl.dsp.exec_cmd(app("brave --new-window https://claude.ai/")))
hl.bind("CTRL + SHIFT + ALT + L", hl.dsp.exec_cmd(app("brave --new-window https://linkedin.com/")))


-- Utility bindings

hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("killall waybar; " .. app("waybar")))         -- Restart waybar
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd(app("swaync-client -t -sw")))             -- Toggle notifications
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("wl-color-picker clipboard --no-notify")) -- Color picker
hl.bind(mod .. " + period", hl.dsp.exec_cmd(app("wofi-emoji")))                          -- Emoji picker alternative

-- Mouse pointer utilities
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("wl-kbptr -o modes=floating,bisect -o mode_floating.source=detect"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("wl-kbptr"))

-- Screenshot tools
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(scripts .. "/screenshot_macos_style.sh"))
-- hl.bind(mod .. " + SHIFT + CTRL + S", hl.dsp.exec_cmd(scripts .. "/screenshot_save.sh"))

-- Scripts
hl.bind(mod .. " + CTRL + SHIFT + SPACE", hl.dsp.exec_cmd(scripts .. "/switch_layout.sh"))
hl.bind(mod .. " + CTRL + SHIFT + 7", hl.dsp.exec_cmd(scripts .. "/speaker_toggle.sh"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd(scripts .. "/rename_workspace.sh"))      -- Rename workspace


-- Special character input

-- æøå for US keyboard layout
hl.bind(mod .. " + bracketleft", hl.dsp.exec_cmd('wtype "å"'))
hl.bind(mod .. " + semicolon",   hl.dsp.exec_cmd('wtype "ø"'))
hl.bind(mod .. " + apostrophe",  hl.dsp.exec_cmd('wtype "æ"'))

-- Menu/Application key writes tilde
hl.bind("Menu", hl.dsp.exec_cmd('wtype "~"'))
hl.bind("Print", hl.dsp.exec_cmd('wtype "~"'))

-- Special characters with Ctrl+Alt
hl.bind("CTRL + ALT + 2", hl.dsp.exec_cmd("wtype @"))
hl.bind("CTRL + ALT + 3", hl.dsp.exec_cmd("wtype £"))
hl.bind("CTRL + ALT + 4", hl.dsp.exec_cmd("wtype $"))
hl.bind("CTRL + ALT + 7", hl.dsp.exec_cmd("wtype {"))
hl.bind("CTRL + ALT + 8", hl.dsp.exec_cmd("wtype ["))
hl.bind("CTRL + ALT + 9", hl.dsp.exec_cmd("wtype ]"))
hl.bind("CTRL + ALT + 0", hl.dsp.exec_cmd("wtype }"))


-- Alternate modifier (MOD5) bindings

hl.bind(alt .. " + Q", hl.dsp.exec_cmd(app("ghostty")))
hl.bind(alt .. " + O", hl.dsp.exec_cmd(app("hyprlock")))
hl.bind(alt .. " + E", hl.dsp.exec_cmd(app("thunar")))
hl.bind(alt .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(alt .. " + F", hl.dsp.window.fullscreen())
hl.bind(alt .. " + SPACE", hl.dsp.exec_cmd(app("wofi")))
hl.bind(alt .. " + D", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(alt .. " + A", hl.dsp.focus({ workspace = "r-1" }))


-- Media and brightness controls (work on any machine with standard keys)

-- Audio controls (macOS-style center overlay)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "/volume.sh mute"))                            -- Mute
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "/volume.sh down"), { repeating = true })      -- Volume down (hold)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "/volume.sh up"), { repeating = true })        -- Volume up (hold)

-- Brightness controls (macOS-style center overlay)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/brightness.sh down"), { repeating = true })  -- Brightness down (hold)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "/brightness.sh up"), { repeating = true })    -- Brightness up (hold)

-- Screenshot
hl.bind("XF86Send", hl.dsp.exec_cmd(scripts .. "/screenshot_keycode.sh 2>/dev/null || true"))

-- Machine-specific bindings (uncomment if you have ASUS laptop)
-- hl.bind("code:156", hl.dsp.exec_cmd("rog-control-center"))
-- hl.bind("code:211", hl.dsp.exec_cmd("asusctl profile -n; pkill -SIGRTMIN+8 waybar"))
-- hl.bind("code:237", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight set 33%-"))
-- hl.bind("code:238", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight set 33%+"))
-- hl.bind("code:210", hl.dsp.exec_cmd("asusctl led-mode -n"))


-- Mouse bindings

-- Move/resize windows with mod + mouse buttons
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })


-- Plugins (disabled)

-- hl.bind(mod .. " + G", hl.plugin.hyprexpo.expo({ action = "toggle" }))
