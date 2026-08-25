-- Host-specific Hyprland overlay, Arch desktop
-- Required from hyprland.lua when this package is stowed.

-- Internal display (run `hyprctl monitors | grep description` to verify)
hl.monitor({
    output   = "desc:AU Optronics 0x1092",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

-- GPU env (Intel iGPU, CometLake UHD)
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("VDPAU_DRIVER", "va_gl")

-- Touchpad device (laptop)
hl.device({
    name = "elan1201:00-04f3:3098-touchpad",
    sensitivity = 0.1,
})

-- Dock (nwg-dock works correctly on Arch, use wlr/taskbar in waybar on Ubuntu instead)
hl.on("hyprland.start", function()
    -- Top edge, since waybar owns the bottom and the dock widens as windows open.
    hl.exec_cmd("nwg-dock-hyprland -i 32 -nolauncher -l top -p top -o eDP-1")
end)

