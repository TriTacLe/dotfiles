# Keybindings

Generated from `shared/stow/hypr/.config/hypr/keybindings.lua` by
`shared/scripts/keybindings-md.sh`. SUPER is the main modifier, MOD5 the right Alt.
Machine keys such as brightness live in each host overlay; personal binds in the
profile's `hypr.lua`.

| Key | Action |
| --- | --- |
| SUPER + Q | Open terminal |
| SUPER + X | Close window with confirmation |
| SUPER + V | Toggle floating |
| SUPER + F | Toggle fullscreen |
| SUPER + SPACE | App launcher |
| SUPER + E | File manager (Thunar) |
| SUPER + W | Browser (Firefox) |
| SUPER + SHIFT + W | Browser (Brave) |
| SUPER + R | Obsidian |
| SUPER + O | Lock screen |
| SUPER + U | Logout menu |
| SUPER + SHIFT + M | Exit Hyprland |
| SUPER + H | `focus({ direction = "left" })` |
| SUPER + L | `focus({ direction = "right" })` |
| SUPER + K | `focus({ direction = "up" })` |
| SUPER + J | `focus({ direction = "down" })` |
| SUPER + SHIFT + H | `window.move({ direction = "left" })` |
| SUPER + SHIFT + L | `window.move({ direction = "right" })` |
| SUPER + SHIFT + K | `window.move({ direction = "up" })` |
| SUPER + SHIFT + J | `window.move({ direction = "down" })` |
| SUPER + 1..9, 0 | `focus({ workspace = i })` |
| SUPER + SHIFT + 1..9, 0 | `window.move({ workspace = i })` |
| SUPER + D | `focus({ workspace = "r+1" })` |
| SUPER + A | `focus({ workspace = "r-1" })` |
| SUPER + SHIFT + D | `window.move({ workspace = "r+1" })` |
| SUPER + SHIFT + A | `window.move({ workspace = "r-1" })` |
| SUPER + S | `workspace.toggle_special()` |
| ALT + Tab | `focus({ workspace = "r+1" })` |
| ALT + SHIFT + Tab | `focus({ workspace = "r-1" })` |
| SUPER + SHIFT + B | Restart waybar |
| SUPER + SHIFT + N | Toggle notifications |
| SUPER + SHIFT + C | Color picker |
| SUPER + period | Emoji picker alternative |
| SUPER + Y | `run ("wl-kbptr -o modes=floating,bisect -o mode_floating.source=detect")` |
| SUPER + T | `run ("wl-kbptr")` |
| SUPER + SHIFT + S | `run ("scripts/screenshot_macos_style.sh")` |
| SUPER + CTRL + SHIFT + SPACE | `run ("scripts/switch_layout.sh")` |
| SUPER + CTRL + SHIFT + 7 | `run ("scripts/speaker_toggle.sh")` |
| SUPER + SHIFT + R | Rename workspace |
| Menu | `run ('wtype "~"')` |
| Print | `run ('wtype "~"')` |
| CTRL + ALT + 2 | `run ("wtype @")` |
| CTRL + ALT + 3 | `run ("wtype £")` |
| CTRL + ALT + 4 | `run ("wtype $")` |
| CTRL + ALT + 7 | `run ("wtype {")` |
| CTRL + ALT + 8 | `run ("wtype [")` |
| CTRL + ALT + 9 | `run ("wtype ]")` |
| CTRL + ALT + 0 | `run ("wtype }")` |
| MOD5 + Q | `run ("ghostty"))` |
| MOD5 + O | `run ("hyprlock"))` |
| MOD5 + E | `run ("thunar"))` |
| MOD5 + V | `window.float({ action = "toggle" })` |
| MOD5 + F | `window.fullscreen()` |
| MOD5 + SPACE | `run ("wofi"))` |
| MOD5 + D | `focus({ workspace = "r+1" })` |
| MOD5 + A | `focus({ workspace = "r-1" })` |
| XF86AudioMute | Mute |
| XF86AudioLowerVolume | Volume down (hold) |
| XF86AudioRaiseVolume | Volume up (hold) |
| XF86MonBrightnessDown | Brightness down (hold) |
| XF86MonBrightnessUp | Brightness up (hold) |
| XF86Send | `run ("scripts/screenshot_keycode.sh 2>/dev/null \|\| true")` |
| SUPER + mouse:272 | `window.drag(), { mouse = true }` |
| SUPER + mouse:273 | `window.resize(), { mouse = true }` |
| SUPER + SHIFT + mouse:272 | `window.resize(), { mouse = true }` |
