-- Gaps, borders, decoration, layout.
-- Colours and rounding come from theme.lua so a theme switch reaches them.

local theme = require("theme")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = { top = 7, right = 7, bottom = 0, left = 7 },
        border_size = 3,

        col = {
            active_border = theme.border,
            inactive_border = theme.border_inactive,
        },

        layout = "dwindle",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        animate_manual_resizes = true,
        vrr = 0,
    },

    ecosystem = {
        no_update_news = true,
    },

    dwindle = {
        preserve_split = true,
    },

    decoration = {
        rounding = theme.rounding,

        blur = {
            enabled = true,
            size = 3,
            passes = 4,
            new_optimizations = true,
        },

        -- Shadows (disabled)
        -- shadow = { enabled = true, range = 14 },
    },
})
