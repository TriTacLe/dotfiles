#!/usr/bin/env bash
# Apply a colour theme across every app that has a palette.
#
# Usage: theme_apply.sh <theme-name> [--no-reload]
#        theme_apply.sh --list
#
# Reads one JSON from ~/.config/hypr/themes/ and writes a small generated file
# per app. Every generated file is a sidecar the app already includes, so the
# hand-written config keeps its layout and only the colours move.
#
# Adding an app means adding one heredoc below. Adding a theme means dropping a
# JSON in themes/ with the same keys as the others.

set -euo pipefail

THEME_DIR="$HOME/.config/hypr/themes"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/current-theme"

list_themes() {
    for f in "$THEME_DIR"/*.json; do
        [ -e "$f" ] || continue
        printf '  %-18s %s\n' "$(basename "$f" .json)" "$(jq -r '._meta.name // ""' "$f")"
    done
}

mode="${1:-}"
skip_reload="${2:-}"

if [ -z "$mode" ] || [ "$mode" = "--list" ] || [ "$mode" = "-h" ]; then
    echo "Usage: theme_apply.sh <theme-name> [--no-reload]"
    echo "Available themes:"
    list_themes
    [ -f "$STATE_FILE" ] && echo "Current: $(cat "$STATE_FILE")"
    exit 0
fi

SRC="$THEME_DIR/${mode}.json"
if [ ! -f "$SRC" ]; then
    echo "Unknown theme '$mode'. Available:" >&2
    list_themes >&2
    exit 1
fi

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

g() { jq -r ".$1 // empty" "$SRC"; }

BASE=$(g base);         MANTLE=$(g mantle);     CRUST=$(g crust)
TEXT=$(g text);         SUBTEXT0=$(g subtext0); SUBTEXT1=$(g subtext1)
SURFACE0=$(g surface0); SURFACE1=$(g surface1); SURFACE2=$(g surface2)
OVERLAY0=$(g overlay0); OVERLAY1=$(g overlay1); OVERLAY2=$(g overlay2)

BLUE=$(g blue);   SAPPHIRE=$(g sapphire); PEACH=$(g peach); GREEN=$(g green)
RED=$(g red);     MAUVE=$(g mauve);       PINK=$(g pink);   YELLOW=$(g yellow)
MAROON=$(g maroon); TEAL=$(g teal)

ACCENT=$(g accent);               ACCENT=${ACCENT:-$BLUE}
ACCENT_DIM=$(g accent_dim);       ACCENT_DIM=${ACCENT_DIM:-$SAPPHIRE}
ACCENT_BRIGHT=$(g accent_bright); ACCENT_BRIGHT=${ACCENT_BRIGHT:-$TEAL}
SELECTION=$(g selection);         SELECTION=${SELECTION:-$SURFACE1}
BORDER=$(g border);               BORDER=${BORDER:-$SURFACE2}
OPACITY=$(g opacity);             OPACITY=${OPACITY:-0.75}
# A transparent bar shows the wallpaper, which only reads well on a dark theme.
VARIANT=$(jq -r '._meta.variant // "dark"' "$SRC")
if [ "$VARIANT" = "light" ]; then BAR_BG="$BASE"; else BAR_BG="rgba(0,0,0,0)"; fi
GTK_THEME=$(g gtk_theme)
ICON_THEME=$(g icon_theme)
# p10k paints segment backgrounds from the terminal palette, so the text on top has
# to come from the other end of the theme.
if [ "$VARIANT" = "light" ]; then ON_SEG="$BASE"; else ON_SEG="$CRUST"; fi

# Terminal 16, falling back to the main palette where a theme omits one.
TB=$(g term_black);   TB=${TB:-$SURFACE1}
TR=$(g term_red);     TR=${TR:-$RED}
TG=$(g term_green);   TG=${TG:-$GREEN}
TY=$(g term_yellow);  TY=${TY:-$YELLOW}
TBL=$(g term_blue);   TBL=${TBL:-$BLUE}
TMA=$(g term_magenta); TMA=${TMA:-$PINK}
TC=$(g term_cyan);    TC=${TC:-$TEAL}
TW=$(g term_white);   TW=${TW:-$SUBTEXT0}
TBB=$(g term_bright_black);   TBB=${TBB:-$SURFACE2}
TBR=$(g term_bright_red);     TBR=${TBR:-$RED}
TBG=$(g term_bright_green);   TBG=${TBG:-$GREEN}
TBY=$(g term_bright_yellow);  TBY=${TBY:-$YELLOW}
TBBL=$(g term_bright_blue);   TBBL=${TBBL:-$BLUE}
TBM=$(g term_bright_magenta); TBM=${TBM:-$PINK}
TBC=$(g term_bright_cyan);    TBC=${TBC:-$TEAL}
TBW=$(g term_bright_white);   TBW=${TBW:-$TEXT}

RAD_L=$(g radius_large); RAD_L=${RAD_L:-14}

# Strip the leading # for the formats that want bare hex.
s() { echo "${1#\#}"; }

# #rrggbb to "r, g, b" for CSS rgba().
hex2rgb() {
    local h="${1#\#}"
    printf "%d, %d, %d" "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

w() { mkdir -p "$(dirname "$1")"; cat > "$1"; }

# GTK apps: a colors.css sidecar next to style.css. These load their stylesheet
# from a path, so a relative @import resolves against the stylesheet directory.
GTK_COLORS="@define-color bg_base ${BASE};
@define-color bg_mantle ${MANTLE};
@define-color bg_crust ${CRUST};
@define-color bg_surface0 ${SURFACE0};
@define-color bg_surface1 ${SURFACE1};
@define-color bg_surface2 ${SURFACE2};
@define-color text_primary ${TEXT};
@define-color text_secondary ${SUBTEXT0};
@define-color text_muted ${SUBTEXT1};
@define-color overlay0 ${OVERLAY0};
@define-color overlay1 ${OVERLAY1};
@define-color overlay2 ${OVERLAY2};
@define-color accent ${ACCENT};
@define-color accent_dim ${ACCENT_DIM};
@define-color accent_bright ${ACCENT_BRIGHT};
@define-color blue ${BLUE};
@define-color sapphire ${SAPPHIRE};
@define-color green ${GREEN};
@define-color red ${RED};
@define-color yellow ${YELLOW};
@define-color peach ${PEACH};
@define-color mauve ${MAUVE};
@define-color pink ${PINK};
@define-color maroon ${MAROON};
@define-color teal ${TEAL};
@define-color selection ${SELECTION};
@define-color border_subtle rgba($(hex2rgb "$BORDER"), 0.6);
@define-color bar_bg ${BAR_BG};"

for app in waybar swaync wlogout nwg-dock-hyprland; do
    [ -d "$HOME/.config/$app" ] || continue
    printf '/* Generated by theme_apply.sh. Do not edit. */\n%s\n' "$GTK_COLORS" \
        > "$HOME/.config/$app/colors.css"
done

# GTK widget and icon themes. These live in settings.ini rather than in any CSS we
# generate, so a dark widget theme survives every colors.css.
if [ "$VARIANT" = "light" ]; then PREFER_DARK=0; SCHEME=prefer-light; else PREFER_DARK=1; SCHEME=prefer-dark; fi
for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [ -f "$ini" ] || continue
    if [ -n "$GTK_THEME" ]; then
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$ini"
    fi
    if [ -n "$ICON_THEME" ]; then
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$ini"
    fi
    sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$PREFER_DARK/" "$ini"
done
if [ -n "$GTK_THEME" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
fi
if [ -n "$ICON_THEME" ]; then
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
fi
gsettings set org.gnome.desktop.interface color-scheme "$SCHEME" 2>/dev/null || true

# wofi builds its stylesheet with load_from_data, which has no base path, so an
# @import cannot resolve. Its stylesheets are generated whole instead: the stowed
# templates/ hold the rules, and the colours get prepended on the way out.
WOFI_COLORS="@define-color bg_base ${BASE};
@define-color bg_mantle ${MANTLE};
@define-color bg_crust ${CRUST};
@define-color bg_surface0 ${SURFACE0};
@define-color bg_surface1 ${SURFACE1};
@define-color text_primary ${TEXT};
@define-color overlay2 ${OVERLAY2};
@define-color accent ${ACCENT};
@define-color red ${RED};
@define-color pink ${PINK};
@define-color selection ${SELECTION};"

for t in "$HOME"/.config/wofi/templates/*.css; do
    [ -e "$t" ] || continue
    {
        echo "/* Generated by theme_apply.sh from templates/. Do not edit. */"
        echo "$WOFI_COLORS"
        echo
        cat "$t"
    } > "$HOME/.config/wofi/$(basename "$t")"
done

# Hyprland, read by theme.lua.
w "$HOME/.config/hypr/colors.lua" <<EOF
-- Generated by theme_apply.sh. Do not edit.
return {
    bg              = "rgb($(s "$BASE"))",
    mantle          = "rgb($(s "$MANTLE"))",
    crust           = "rgb($(s "$CRUST"))",
    surface0        = "rgb($(s "$SURFACE0"))",
    surface1        = "rgb($(s "$SURFACE1"))",
    text            = "rgb($(s "$TEXT"))",
    accent          = "rgb($(s "$ACCENT"))",
    border          = "rgba($(s "$ACCENT")ff)",
    border_inactive = "rgba($(s "$CRUST")aa)",
    red             = "rgb($(s "$RED"))",
    green           = "rgb($(s "$GREEN"))",
    yellow          = "rgb($(s "$YELLOW"))",
    blue            = "rgb($(s "$BLUE"))",
    mauve           = "rgb($(s "$MAUVE"))",
    rounding        = ${RAD_L},
}
EOF

# hyprlock, sourced by hyprlock.conf.
w "$HOME/.config/hypr/hyprlock-colors.conf" <<EOF
# Generated by theme_apply.sh. Do not edit.
\$lock_text = rgba($(s "$TEXT")ee)
\$lock_text_dim = rgba($(s "$SUBTEXT0")cc)
\$lock_ring = rgb($(s "$OVERLAY2"))
\$lock_ring_check = rgb($(s "$GREEN"))
\$lock_ring_fail = rgb($(s "$RED"))
\$lock_bg = rgba($(s "$CRUST")ff)
EOF

# ghostty, pulled in by a config-file line.
w "$HOME/.config/ghostty/colors" <<EOF
# Generated by theme_apply.sh. Do not edit.
background = $(s "$BASE")
foreground = $(s "$TEXT")
background-opacity = $OPACITY
cursor-color = $(s "$ACCENT")
cursor-text = $(s "$BASE")
selection-background = $(s "$SELECTION")
selection-foreground = $(s "$TEXT")
palette = 0=$(s "$TB")
palette = 1=$(s "$TR")
palette = 2=$(s "$TG")
palette = 3=$(s "$TY")
palette = 4=$(s "$TBL")
palette = 5=$(s "$TMA")
palette = 6=$(s "$TC")
palette = 7=$(s "$TW")
palette = 8=$(s "$TBB")
palette = 9=$(s "$TBR")
palette = 10=$(s "$TBG")
palette = 11=$(s "$TBY")
palette = 12=$(s "$TBBL")
palette = 13=$(s "$TBM")
palette = 14=$(s "$TBC")
palette = 15=$(s "$TBW")
EOF

# kitty, included from kitty.conf line 1.
if [ -d "$HOME/.config/kitty" ]; then
    w "$HOME/.config/kitty/current-theme.conf" <<EOF
# Generated by theme_apply.sh. Do not edit.
background ${BASE}
foreground ${TEXT}
cursor ${ACCENT}
color0  ${TB}
color1  ${TR}
color2  ${TG}
color3  ${TY}
color4  ${TBL}
color5  ${TMA}
color6  ${TC}
color7  ${TW}
color8  ${TBB}
color9  ${TBR}
color10 ${TBG}
color11 ${TBY}
color12 ${TBBL}
color13 ${TBM}
color14 ${TBC}
color15 ${TBW}
EOF
fi

# alacritty, imported by alacritty.toml.
if [ -d "$HOME/.config/alacritty" ]; then
    w "$HOME/.config/alacritty/themes/current.toml" <<EOF
# Generated by theme_apply.sh. Do not edit.
[colors.primary]
background = '${BASE}'
foreground = '${TEXT}'

[colors.cursor]
text = '${BASE}'
cursor = '${ACCENT}'

[colors.normal]
black = '${TB}'
red = '${TR}'
green = '${TG}'
yellow = '${TY}'
blue = '${TBL}'
magenta = '${TMA}'
cyan = '${TC}'
white = '${TW}'

[colors.bright]
black = '${TBB}'
red = '${TBR}'
green = '${TBG}'
yellow = '${TBY}'
blue = '${TBBL}'
magenta = '${TBM}'
cyan = '${TBC}'
white = '${TBW}'
EOF
fi

# Neovim: LazyVim reads the colorscheme name from this file. Themes without
# an nvim name fall back to catppuccin-mocha.
NVIM_CS=$(jq -r '._meta.nvim // "catppuccin-mocha"' "$SRC")
w "$HOME/.config/nvim/lua/theme_current.lua" <<EOF
-- Generated by theme_apply.sh. Do not edit.
return { colorscheme = "$NVIM_CS" }
EOF

# That file is only read at startup, so tell the editors that are already open.
# --remote-expr instead of --remote-send: no keystrokes, so insert mode survives.
for sock in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*; do
    [ -S "$sock" ] || continue
    timeout 2 nvim --server "$sock" \
        --remote-expr "execute('colorscheme $NVIM_CS')" >/dev/null 2>&1 || true
done

# powerlevel10k. The rainbow preset paints segment backgrounds from terminal colours
# 0-7 and writes black on top, which assumes those colours are light. A light theme
# darkens them so they work as text, so the foregrounds have to be inverted here.
# Sourced after .p10k.zsh, which unsets every POWERLEVEL9K_* when it runs.
P10K_SEGMENTS="DIR DIR_SHORTENED DIR_ANCHOR
VCS_CLEAN VCS_MODIFIED VCS_UNTRACKED VCS_CONFLICTED VCS_LOADING
STATUS_OK STATUS_OK_PIPE STATUS_ERROR STATUS_ERROR_SIGNAL STATUS_ERROR_PIPE
COMMAND_EXECUTION_TIME BACKGROUND_JOBS DIRENV VIRTUALENV ANACONDA PYENV
NODENV NVM NODEENV CONTEXT TIME TODO TIMEWARRIOR TASKWARRIOR PER_DIRECTORY_HISTORY"

if [ -d "$HOME/.config/zsh" ]; then
    {
        echo "# Generated by theme_apply.sh. Do not edit."
        if [ "$VARIANT" = "light" ]; then
            for seg in $P10K_SEGMENTS; do
                echo "typeset -g POWERLEVEL9K_${seg}_FOREGROUND='${ON_SEG}'"
            done
            # my_git_formatter picks its own colours inside the function.
            echo "typeset -g MY_GIT_FG='%F{${ON_SEG}}'"
            echo "typeset -g MY_GIT_META_FG='%F{${ON_SEG}}'"
            echo "typeset -g MY_GIT_CONFLICT_FG='%F{${ON_SEG}}'"
            # The prompt character sits on the terminal background, not on a segment.
            echo "typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='${GREEN}'"
            echo "typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='${RED}'"
            echo "typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND='${OVERLAY0}'"
        else
            echo "# Dark variant: the preset's own colours already work."
        fi
    } > "$HOME/.config/zsh/p10k-colors.zsh"
fi

# GTK: libadwaita named colors for gtk4 and the legacy theme_* names for gtk3,
# written as colors.css next to each gtk.css. The gtk.css files import it.
GTK_THEME_NAME="${GTK_THEME:-catppuccin-mocha-flamingo-standard+default}"
w "$HOME/.config/gtk-4.0/colors.css" <<EOF
/* Generated by theme_apply.sh. Do not edit. */
@define-color window_bg_color ${BASE};
@define-color window_fg_color ${TEXT};
@define-color view_bg_color ${MANTLE};
@define-color view_fg_color ${TEXT};
@define-color headerbar_bg_color ${MANTLE};
@define-color headerbar_fg_color ${TEXT};
@define-color headerbar_backdrop_color ${BASE};
@define-color card_bg_color ${SURFACE0};
@define-color card_fg_color ${TEXT};
@define-color dialog_bg_color ${BASE};
@define-color dialog_fg_color ${TEXT};
@define-color popover_bg_color ${SURFACE0};
@define-color popover_fg_color ${TEXT};
@define-color accent_bg_color ${ACCENT};
@define-color accent_fg_color ${BASE};
@define-color accent_color ${ACCENT};
@define-color destructive_bg_color ${RED};
@define-color destructive_fg_color ${BASE};
@define-color destructive_color ${RED};
@define-color success_color ${GREEN};
@define-color warning_color ${YELLOW};
@define-color error_color ${RED};
@define-color borders ${BORDER};
EOF
w "$HOME/.config/gtk-3.0/colors.css" <<EOF
/* Generated by theme_apply.sh. Do not edit. */
@define-color theme_bg_color ${BASE};
@define-color theme_fg_color ${TEXT};
@define-color theme_base_color ${MANTLE};
@define-color theme_text_color ${TEXT};
@define-color theme_selected_bg_color ${ACCENT};
@define-color theme_selected_fg_color ${BASE};
@define-color borders ${BORDER};
@define-color success_color ${GREEN};
@define-color warning_color ${YELLOW};
@define-color error_color ${RED};
${GTK_COLORS}
EOF
# gtk-3.0/gtk.css is stowed and already imports colors.css, so nothing to patch here.
# It must stay a symlink: writing through it would replace it with a plain file.
# gtk4: a symlink to the system theme cannot import anything, so replace it with
# a file that imports the theme first and the palette on top. Rewrite it every
# run: the old version only wrote it once, so the theme path stayed baked in and
# changing GTK_THEME had no effect. Anything hand-written here is preserved.
GTK4="$HOME/.config/gtk-4.0/gtk.css"
GTK4_MARK="/* Generated by theme_apply.sh. Do not edit. */"
# Ours if it carries the marker, or if it opens with the theme import the older
# version of this script wrote before the marker existed.
if [ -L "$GTK4" ] || [ ! -e "$GTK4" ] \
    || head -n1 "$GTK4" 2>/dev/null | grep -qF "$GTK4_MARK" \
    || head -n1 "$GTK4" 2>/dev/null | grep -q '^@import url("file:///usr/share/themes/'; then
    rm -f "$GTK4"
    mkdir -p "$(dirname "$GTK4")"
    printf '%s\n@import url("file:///usr/share/themes/%s/gtk-4.0/gtk.css");\n@import url("colors.css");\n' \
        "$GTK4_MARK" "$GTK_THEME_NAME" > "$GTK4"
elif ! grep -qs '@import url("colors.css");' "$GTK4"; then
    { echo '@import url("colors.css");'; cat "$GTK4"; } > "$GTK4.new"
    mv -f "$GTK4.new" "$GTK4"
fi

mkdir -p "$(dirname "$STATE_FILE")"
echo "$mode" > "$STATE_FILE"

if [ "$skip_reload" = "--no-reload" ]; then
    echo "Wrote $mode. Reload skipped."
    exit 0
fi

# Reload. Each app is optional, so a missing one is not an error.
hyprctl reload >/dev/null 2>&1 || true
pkill -x kitty -USR1 2>/dev/null || true
# ghostty rereads its config on SIGUSR2. background-opacity only applies to new
# windows, so a light/dark swap still wants a fresh one.
pkill -x ghostty -USR2 2>/dev/null || true

# Relaunch a daemon the same way autostart.lua started it. Under uwsm a bare
# setsid would put it outside the slice it belongs to, and it would stay there
# until the next login.
relaunch() {
    if systemctl --user -q is-active 'wayland-wm@*.service'; then
        setsid uwsm app -s b -- "$@" </dev/null >/dev/null 2>&1 &
    else
        setsid "$@" </dev/null >/dev/null 2>&1 &
    fi
}

# pkill returns before the process is actually gone. Starting the replacement while
# the old one still holds its wayland surface is what left waybar dead after a switch,
# so poll instead of sleeping a fixed amount.
wait_gone() {
    local i
    for i in $(seq 1 30); do
        pgrep -x "$1" >/dev/null 2>&1 || return 0
        sleep 0.1
    done
    return 1
}

wait_up() {
    local i
    for i in $(seq 1 30); do
        pgrep -x "$1" >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    return 1
}

# $1 is the name pgrep matches, which the kernel truncates to 15 characters. The rest
# is the command line to start again.
restart() {
    local name="$1"; shift
    pgrep -x "$name" >/dev/null 2>&1 || return 0
    pkill -x "$name" || true
    wait_gone "$name" || pkill -9 -x "$name" || true
    relaunch "$@"
    if wait_up "$name"; then return 0; fi
    relaunch "$@"
    if ! wait_up "$name"; then
        echo "warning: $name did not come back after the theme switch" >&2
    fi
}

# waybar and swaync only re-read CSS on start.
restart waybar waybar
restart swaync swaync
restart nwg-dock-hyprla nwg-dock-hyprland -i 32 -nolauncher -l top -p bottom -o eDP-1

notify-send -a "Theme" "Theme applied" "$(jq -r '._meta.name // empty' "$SRC")" 2>/dev/null || true
echo "Applied $mode."
