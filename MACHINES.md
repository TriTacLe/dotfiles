# Machines

Reference for per-host dotfiles decisions. Add a row when a new machine joins.

---

## Ubuntu T14s Gen 2i - ThinkPad (primary)

| Field | Value |
|---|---|
| Hostname | tri-thinkpad (Ubuntu) |
| OS | Ubuntu 24.04.4 LTS |
| Kernel | 6.17.0-23-generic |
| CPU | Intel Core i5-1135G7 (11th Gen, TigerLake) |
| GPU | Intel Iris Xe Graphics (iHD driver) |
| RAM | 16 GB |
| Storage | 256 GB NVMe (~55% used) |
| Display | AU Optronics 0x573D, 14", 1920x1080, eDP-1 |
| DPI | ~157 (scale = 1.0) |
| Touchpad | Synaptics precision (T14s built-in) |
| WM | Hyprland 0.55 (from cppiber PPA) + Sway fallback |
| Display server | Wayland (GDM session) |
| Installer | `ubuntu/install-ubuntu.sh` |
| Hypr host overlay | `ubuntu/stow/hypr-host/host.conf` |

### Portability notes

- `env = WLR_NO_HARDWARE_CURSORS,1` required (Intel Xe cursor glitch on Wayland)
- `env = LIBVA_DRIVER_NAME,iHD` + `VDPAU_DRIVER,va_gl` for Intel VA-API
- Monitor addressed by name `eDP-1` (not description - Intel panels don't expose EDID description reliably)
- scale = 1.0 currently; bump to 1.25 if UI feels too small after DPI audit

---

## Arch Zenbook (daily driver / server)

| Field | Value |
|---|---|
| OS | Arch Linux |
| GPU | AMD (radeonsi driver) |
| Display | AU Optronics 0x1092 (addressed by EDID description) |
| Touchpad | elan1201:00-04f3:3098 |
| WM | Hyprland (latest from pacman/AUR) |
| Installer | `arch/install-arch.sh` |
| Hypr host overlay | `arch/stow/hypr-host/host.conf` |

### Portability notes

- `env = LIBVA_DRIVER_NAME,radeonsi` + `VDPAU_DRIVER,radeonsi` for AMD VA-API
- Monitor addressed by EDID description `desc:AU Optronics 0x1092` (preferred over eDP-1 for AMD - output name stable)
- scale = 1.0

---

## Mac (secondary)

| Field | Value |
|---|---|
| OS | macOS |
| WM | N/A (Aqua) |
| Installer | `macos/install-macos.sh` |
| Hypr host overlay | N/A |

### Portability notes

- No Hyprland, no waybar. Shares: git, nvim, lazygit, backgrounds, zsh, scripts, claude-config.
- Homebrew + Brewfile handles packages.

---

## Future: Arch ThinkPad (pending)

When this machine joins, add a row here and create `arch-thinkpad/stow/hypr-host/host.conf` (or branch on hostname in `arch/stow/hypr-host/host.conf`).

---

## Waybar DPI guide

Shared `style.css` uses pixel-fixed values. If bar/modules look too small or too large on a display, adjust `scale` in that host's `host.conf`:

```
monitor = eDP-1, preferred, 0x0, 1.25   # HiDPI 14" panels
monitor = eDP-1, preferred, 0x0, 1.0    # standard 27"+ at 1440p or lower
```

Reference DPIs:
- 14" 1920x1080 = ~157 DPI
- 15" 1920x1080 = ~141 DPI
- 27" 2560x1440 = ~109 DPI
- 27" 1920x1080 = ~81 DPI
