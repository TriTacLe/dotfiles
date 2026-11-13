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

-- Norwegian keyboard. nodeadkeys: ^ ~ ` and acute are dead keys on the stock
-- layout, so each needs a trailing space. Costs accents like é, which compose
-- off those keys. æ ø å have their own keys and are unaffected.
hl.config({
    input = {
        kb_layout = "no",
        kb_variant = "nodeadkeys",
    },
})

-- Dock (nwg-dock works correctly on Arch, use wlr/taskbar in waybar on Ubuntu instead)
--
-- It rests on waybar at the bottom, so any window on the workspace sits under
-- it. Run it only while the workspace is empty: start it when the last window
-- goes, kill it when the first one arrives. Focus and title changes re-run the
-- check: XWayland windows are counted late, so the open event alone can miss.
--
-- flock -n makes a second launch a no-op. Without it a second nwg-dock sends a
-- toggle to the first one instead of exiting. The kill is idempotent anyway.
local lock = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/nwg-dock.lock"
local dock = "flock -n " .. lock .. " nwg-dock-hyprland -i 32 -nolauncher -l top -p bottom -o eDP-1"
local function sync_dock()
    local ws = hl.get_active_workspace()
    if not ws or ws.id < 0 then return end
    if ws.windows == 0 then
        hl.exec_cmd("setsid " .. dock .. " >/dev/null 2>&1 &")
    else
        hl.exec_cmd("pkill -x nwg-dock-hyprla")
    end
end

for _, event in ipairs({ "hyprland.start", "window.open", "window.close", "window.active", "window.title", "workspace.active" }) do
    hl.on(event, sync_dock)
end

