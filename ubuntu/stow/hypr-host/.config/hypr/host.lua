-- Host-specific Hyprland overlay, Ubuntu T14s Gen 2i (Intel Iris Xe)
-- Required from hyprland.lua when this package is stowed.

-- Internal panel (FHD 1920x1080)
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

-- GPU env (Intel)
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("VDPAU_DRIVER", "va_gl")
-- wlroots-era leftover, no effect on aquamarine. Kept so behaviour matches the old config.
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- Synaptics precision touchpad (T14s)
hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
            scroll_factor = 0.6,
        },
    },
})

-- Brightness keys, bind both XF86 keycodes and F5/F6 to cover Fn-lock states
local scripts = "~/.config/hypr/scripts"
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/brightness_wob.sh down"), { repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scripts .. "/brightness_wob.sh up"),   { repeating = true })
hl.bind("F5", hl.dsp.exec_cmd(scripts .. "/brightness_wob.sh down"), { repeating = true })
hl.bind("F6", hl.dsp.exec_cmd(scripts .. "/brightness_wob.sh up"),   { repeating = true })
