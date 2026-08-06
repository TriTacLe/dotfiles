# Machines

Per-host dotfiles reference. Add a row when a new machine joins.

---

## Lenovo ThinkPad T14s Gen 2i (Ubuntu)

| Field | Value |
|---|---|
| Hostname | tri-thinkpad |
| OS | Ubuntu 24.04.4 LTS |
| Kernel | 6.17.0-23-generic |
| CPU | Intel Core i5-1135G7 (4c/8t, TigerLake) |
| GPU | Intel Iris Xe Graphics (iHD driver) |
| RAM | 16 GB |
| Storage | 256 GB NVMe |
| Display | AU Optronics 0x573D, 14", 1920x1080, eDP-1 |
| DPI | 157 (scale 1.0) |
| Touchpad | Synaptics precision |
| WM | Hyprland 0.55 (cppiber PPA) + Sway fallback |
| Display server | Wayland (GDM) |
| Installer | `ubuntu/install-ubuntu.sh` |
| Hypr host overlay | `ubuntu/stow/hypr-host/.config/hypr/host.lua` |

### Notes

- `hl.env("WLR_NO_HARDWARE_CURSORS", "1")` kept from the wlroots era; no effect on aquamarine
- `hl.env("LIBVA_DRIVER_NAME", "iHD")` + `hl.env("VDPAU_DRIVER", "va_gl")` for VA-API
- Monitor by connector name `eDP-1` (Intel panels don't reliably expose EDID description)
- scale 1.0

---

## HP ZBook Studio G7 (Arch, daily driver)

| Field | Value |
|---|---|
| Hostname | archlinux |
| OS | Arch Linux |
| Kernel | 6.19.14-arch1-1 |
| CPU | Intel Core i7-10750H (6c/12t, 2.60 GHz) |
| GPU | Intel UHD Graphics (CometLake-H) + NVIDIA Quadro T1000 Mobile |
| RAM | 16 GB |
| Storage | 512 GB NVMe (46 GB root, 422 GB /home) |
| Display | AU Optronics 0x1092, 1920x1080, eDP-1 |
| Touchpad | elan1201:00-04f3:3098 |
| WM | Hyprland 0.56.1 (pacman) |
| Installer | `arch/install-arch.sh` |
| Hypr host overlay | `arch/stow/hypr-host/.config/hypr/host.lua` |

### Notes

- Monitor by EDID description `desc:AU Optronics 0x1092`, scale 1.0
- Hybrid GPU: Intel iGPU drives display, Quadro T1000 for compute
- Root 46 GB (small), home 422 GB - keep root lean

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

## Lenovo ThinkPad L390 Yoga (Arch, server)

| Field | Value |
|---|---|
| Hostname | arch-thinkpad |
| OS | Arch Linux |
| Kernel | 6.19.11-arch1-1 |
| CPU | Intel Core i3-8145U (2c/4t, 2.10 GHz, WhiskeyLake-U) |
| GPU | Intel UHD Graphics 620 (integrated) |
| RAM | 8 GB |
| Storage | 256 GB NVMe (Toshiba KXG6AZNV256G) |
| Role pin | `~/.dotfiles-role` = `server` |
| Installer | `server/install-server.sh` |
| Dotfiles path | `~/dotfiles/` (server convention, not `~/Desktop/dotfiles/`) |
| Hypr host overlay | N/A (headless) |

### Role

Headless server pivot from a former Hyprland desktop install. Hosts Dockerized
apps fronted by Cloudflare Tunnel, with Tailscale for admin access, fail2ban
for any open ports, and restic/borg for backups.

### Portability notes

- No Hyprland, no waybar, no GUI stow packages.
- Shares with desktop hosts: git, nvim, lazygit, zsh, tmux, scripts, ipython. Prompt is
  powerlevel10k via the Arch `.zshrc`; starship is macOS-only.
- Selection is by the `server` role pin (`~/.dotfiles-role`), not by hostname,
  so any Arch host can opt in.

### Service hosting

- Docker stacks live under `/srv/<name>/`, one per service.
- Each service has a dedicated system user `svc_<name>` (uid <1000, no shell);
  container processes run as that user via `PUID/PGID`.
- `tri` owns the compose file and `.env`; the data dir is owned by the
  service user so a container escape stays scoped to that service.
- Provision with `sudo bash server/scripts/svc-new.sh <name>`.

### Hardening

- SSH: key-only, no root login, `AllowUsers tri`, 10 min idle timeout
  (`server/etc/ssh/sshd_config.d/99-hardening.conf`).
- UFW: deny incoming, allow ssh from anywhere, allow all on `tailscale0`.
  No public 80/443 — cloudflared dials out.
- fail2ban watches sshd.

---

## Waybar DPI guide

`style.css` uses fixed pixel values. Adjust `scale` in the host's `host.lua` if bar looks wrong:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.25 })  -- HiDPI 14" panels
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })     -- standard 27"+ at 1440p or lower
```

Reference DPIs:
- 14" 1920x1080 = 157 DPI
- 15" 1920x1080 = 141 DPI
- 27" 2560x1440 = 109 DPI
- 27" 1920x1080 = 81 DPI
