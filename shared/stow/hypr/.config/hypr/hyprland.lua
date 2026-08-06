--       ░▒▒▒▒▒▒▒░░░
--     ░░▒▒▒▒▒▒░░░░▓▓
--    ░░▒▒▒▒▒░░░░░▓▓
--   ░░░▒▒▒░░░░░░▓▓
--   ░░░▒▒▒░░░░░▓▓▓▓▓▓
--    ░░░▒▒░░░░▓▓   ▓▓
--     ░░▒▒▓▓   ▓▓ YPRLAND config


-- Monitor setup, see https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Generic fallback + EDID-based rules in monitors.lua, host-specific override in host.lua
require("monitors")

-- host.lua ships in the per-machine hypr-host package. pcall keeps the rest of
-- this file alive on machines where that package is not stowed.
pcall(require, "host")


-- Autostart applications
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("blueman-applet")                    -- Bluetooth tray icon
    hl.exec_cmd("nm-applet --no-agent --indicator")  -- Network tray icon
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-slideshow.sh")
    hl.exec_cmd("waybar")
    hl.dispatch(hl.dsp.focus({ workspace = 3 }))     -- Land on workspace 3 at login
    hl.exec_cmd("hypridle")
    hl.exec_cmd("avizo-daemon")                      -- Volume/brightness overlay
    hl.exec_cmd("~/.config/hypr/scripts/assign_workspaces.sh")
    hl.exec_cmd("~/.config/hypr/scripts/monitor_watch.sh")
    -- hl.exec_cmd("hyprswitch init --daemon")       -- Mac-like Alt+Tab
end)


-- Environment variables (GPU-specific env goes in per-host host.lua)

-- GTK Theme
hl.env("GTK_THEME", "catppuccin-mocha-flamingo-standard+default")

-- Scaling
hl.env("GDK_SCALE", "1")
hl.env("XCURSOR_SIZE", "21")
hl.env("GDK_DPI_SCALE", "1")
hl.env("GNOME_KEYRING_CONTROL", "/run/user/1000/keyring")
hl.env("ELECTRON_PASSWORD_STORE", "gnome-libsecret")


hl.config({
    -- XWayland scaling
    xwayland = {
        force_zero_scaling = true,
    },

    -- Input/keyboard/mouse
    input = {
        kb_layout = "no", -- Norwegian keyboard layout
        kb_model = "",
        kb_options = "",
        kb_variant = "",
        kb_rules = "",

        follow_mouse = 1,
        force_no_accel = true,
        sensitivity = -0.35,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = false,
            scroll_factor = 0.8,
        },

        -- Alternative keyboard options (disabled)
        -- kb_options = "caps:escape",
        -- kb_options = "grp:lctrl_lalt_toggle",
    },

    -- Host-specific input device blocks go in per-host host.lua

    general = {
        gaps_in = 4,
        gaps_out = { top = 7, right = 7, bottom = 0, left = 7 },
        border_size = 3,

        col = {
            active_border = "rgba(65b2ffff)",
            inactive_border = "rgba(011423aa)",
        },

        layout = "dwindle",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        animate_manual_resizes = true,
        vrr = 0,
    },

    ecosystem = {
        no_update_news = true,
    },

    -- Layout settings
    dwindle = {
        preserve_split = true,
    },

    -- Decoration, blur, shadows
    decoration = {
        rounding = 14,

        blur = {
            enabled = true,
            size = 3,
            passes = 4,
            new_optimizations = true,
        },

        -- Shadows (disabled)
        -- shadow = { enabled = true, range = 14 },
    },

    gestures = {
        workspace_swipe_forever = true,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


-- Import additional config files
require("animations")
require("keybindings")
require("windowrules")
-- require("hyprgrass")  -- re-enable after hyprpm builds on 0.56
-- require("hyprexpo")   -- re-enable after hyprpm builds on 0.56
