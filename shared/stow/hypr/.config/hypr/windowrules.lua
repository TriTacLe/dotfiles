-- Window rules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Examples (disabled)
-- hl.window_rule({ name = "float-kitty", match = { class = "^(kitty)$" }, float = true })
-- hl.window_rule({ name = "dim-kitty", match = { class = "^(kitty)$" }, opacity = 0.8 })

-- Mullvad VPN, always floating
hl.window_rule({
    name  = "float-mullvad",
    match = { class = "mullvad-vpn" },

    float = true,
    move  = "69.5% 55%",
    size  = "30% 40%",
})

-- Brave Browser
hl.window_rule({
    name  = "tile-brave",
    match = { class = "Brave-browser" },

    tile = true,
})

-- Thunar file manager
hl.window_rule({
    name  = "float-thunar",
    match = { class = "thunar" },

    float  = true,
    center = true,
    size   = "50% 50%",
})

-- Badlion Client
hl.window_rule({
    name  = "float-badlion",
    match = { class = "BadlionClient" },

    float  = true,
    center = true,
    size   = "50% 50%",
})

-- Discord
hl.window_rule({
    name  = "float-discord",
    match = { initial_title = "discord" },

    float  = true,
    center = true,
    size   = "50% 50%",
    -- monitor = "DP-2",
})

-- Brave Google login popup
hl.window_rule({
    name  = "float-brave-popup",
    match = { initial_title = "Untitled - Brave" },

    float  = true,
    center = true,
    size   = "50% 50%",
})

-- Pavucontrol (audio control)
hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "pavucontrol" },

    float = true,
    move  = "69.5% 55%",
    size  = "30% 40%",
})


-- Layer rules

hl.layer_rule({
    name  = "blur-logout",
    match = { namespace = "logout_dialog" },

    blur = true,
})

-- Other layer rules (disabled)
-- hl.layer_rule({ name = "blur-waybar", match = { namespace = "waybar" }, blur = true })
-- hl.layer_rule({ name = "blur-wofi", match = { namespace = "wofi" }, blur = true })


-- Smart gaps (disabled)
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0 })

-- Workspace assignments (disabled)
-- hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
-- hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
