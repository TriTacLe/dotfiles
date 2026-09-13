-- Autostart, plus the workspaces that must always exist.

-- Under uwsm, launch as a background scope so oomd sees each daemon on its
-- own. A plain session falls through to the bare command.
local function bg(cmd)
    return "if systemctl --user -q is-active wayland-wm@*.service; then uwsm app -s b -- "
        .. cmd .. "; else " .. cmd .. "; fi"
end

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd(bg("blueman-applet"))                    -- Bluetooth tray icon
    hl.exec_cmd(bg("nm-applet --no-agent --indicator"))  -- Network tray icon
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd(bg("swaync"))
    hl.exec_cmd(bg("hyprpaper"))
    hl.exec_cmd(bg("~/.config/hypr/scripts/wallpaper-slideshow.sh"))
    hl.exec_cmd(bg("waybar"))
    hl.dispatch(hl.dsp.focus({ workspace = 3 }))     -- Land on workspace 3 at login
    hl.exec_cmd(bg("hypridle"))
    hl.exec_cmd(bg("avizo-daemon"))                      -- Volume/brightness overlay
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
