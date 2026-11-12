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
-- goes, kill it when the first one arrives. Focus changes re-run the check so a
-- missed open or move cannot leave it sitting over a window.
--
-- Only act on a state change: a second launch while one is starting makes
-- nwg-dock toggle the first instance instead of exiting.
local dock = "nwg-dock-hyprland -i 32 -nolauncher -l top -p bottom -o eDP-1"
local dock_up = nil
local function sync_dock()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local want = ws.windows == 0
    if want == dock_up then return end
    dock_up = want
    if want then
        hl.exec_cmd("pgrep -x nwg-dock-hyprla >/dev/null || setsid " .. dock .. " >/dev/null 2>&1 &")
    else
        hl.exec_cmd("pkill -x nwg-dock-hyprla")
    end
end

for _, event in ipairs({ "hyprland.start", "window.open", "window.close", "window.active", "workspace.active" }) do
    hl.on(event, sync_dock)
end

