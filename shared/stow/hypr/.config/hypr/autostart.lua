-- Autostart, plus the workspaces that must always exist.

-- Under uwsm, launch as a scope in background-graphical.slice so each daemon is
-- its own unit and stops with the session. A plain session falls through to the
-- bare command. exec in both branches so the wrapper shell does not stay parked
-- around every daemon for the life of the session.
local function bg(cmd)
    return "if systemctl --user -q is-active wayland-wm@*.service; then exec uwsm app -s b -- "
        .. cmd .. "; else exec " .. cmd .. "; fi"
end

-- uwsm's session target also pulls in /etc/xdg/autostart, so anything with a
-- desktop entry there is already started for us and starting it again gives two
-- tray icons. Launch these only in a plain session.
local function unless_uwsm(cmd)
    return "if systemctl --user -q is-active wayland-wm@*.service; then :; else exec " .. cmd .. "; fi"
end

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd(unless_uwsm("blueman-applet"))           -- Bluetooth tray icon, also in /etc/xdg/autostart
    hl.exec_cmd(unless_uwsm("nm-applet --no-agent --indicator")) -- Network tray icon, also in /etc/xdg/autostart
    hl.exec_cmd(bg("swaync"))
    hl.exec_cmd(bg("hyprpaper"))
    hl.exec_cmd(bg("~/.config/hypr/scripts/wallpaper-slideshow.sh"))
    hl.exec_cmd(bg("waybar"))
    hl.dispatch(hl.dsp.focus({ workspace = 3 }))     -- Land on workspace 3 at login
    hl.exec_cmd(bg("hypridle"))
    hl.exec_cmd(bg("swayosd-server"))                    -- Volume/brightness overlay
    hl.exec_cmd(bg("~/.config/hypr/scripts/assign_workspaces.sh"))
    hl.exec_cmd(bg("~/.config/hypr/scripts/monitor_watch.sh"))
    hl.exec_cmd(bg("~/.config/hypr/scripts/workspace_names.sh"))  -- Restore workspace labels
    -- hl.exec_cmd("hyprswitch init --daemon")       -- Mac-like Alt+Tab
end)

-- Workspaces 1 to 6 always exist. An emptied workspace would otherwise be
-- destroyed and take its label with it.
for i = 1, 6 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end
