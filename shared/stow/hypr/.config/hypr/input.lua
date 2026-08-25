-- Keyboard, mouse, touchpad, gestures.
-- Host-specific device blocks go in the per-host host.lua.

hl.config({
    input = {
        kb_layout = "no", -- Norwegian keyboard layout
        kb_model = "",
        kb_options = "",
        kb_variant = "",
        kb_rules = "",

        follow_mouse = 1,
        force_no_accel = true,
        sensitivity = -0.35,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = false,
            scroll_factor = 0.8,
        },

        -- Alternative keyboard options (disabled)
        -- kb_options = "caps:escape",
        -- kb_options = "grp:lctrl_lalt_toggle",
    },

    gestures = {
        workspace_swipe_forever = true,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
