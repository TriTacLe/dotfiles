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
--
-- It rests on waybar at the bottom, so any window on the workspace sits under
-- it. Run it only while the workspace is empty: start it when the last window
-- goes, kill it when the first one arrives.
local dock = "nwg-dock-hyprland -i 32 -nolauncher -l top -p bottom -o eDP-1"
local sync_dock = 'if [ "$(hyprctl activeworkspace -j | jq .windows)" -eq 0 ]; then '
    .. "pgrep -x nwg-dock-hyprla >/dev/null || setsid "
    .. dock
    .. " >/dev/null 2>&1 & else pkill -x nwg-dock-hyprla; fi"

for _, event in ipairs({ "hyprland.start", "window.open", "window.close", "workspace.active" }) do
    hl.on(event, function()
        hl.exec_cmd(sync_dock)
    end)
end

