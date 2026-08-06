-- EDID-based monitor rules, survive dock changes and connector renames.
-- Run `hyprctl monitors | grep description` on each machine to get strings.
-- Non-matching desc: rules are silently ignored by Hyprland.

-- Internal panels: add desc: rules in your host-* package's host.lua, not here.

-- External monitors, add desc: strings for any external display used
-- hl.monitor({ output = "desc:Dell Inc. DELL U2720Q XXXXX", mode = "3840x2160@60", position = "auto-right", scale = 2 })

-- Fallback, any monitor not matched above gets sane defaults
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
