-- Environment variables and XWayland scaling.
-- GPU-specific env belongs in the per-host host.lua, not here.

-- GTK Theme
hl.env("GTK_THEME", "catppuccin-mocha-flamingo-standard+default")

-- Scaling
hl.env("GDK_SCALE", "1")
hl.env("XCURSOR_SIZE", "21")
hl.env("GDK_DPI_SCALE", "1")
local runtime = os.getenv("XDG_RUNTIME_DIR")
if runtime then hl.env("GNOME_KEYRING_CONTROL", runtime .. "/keyring") end
hl.env("ELECTRON_PASSWORD_STORE", "gnome-libsecret")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
