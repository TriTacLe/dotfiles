# server/

Profile for headless Arch hosts running self-hosted apps.

## Install convention

On server hosts the dotfiles repo lives at `~/dotfiles/` (not `~/Desktop/dotfiles/`).
Headless boxes don't have a Desktop, so the repo lives at a server-conventional path:

```sh
git clone https://github.com/TriTacLe/dotfiles.git ~/dotfiles
cd ~/dotfiles && git submodule update --init --recursive
echo server > ~/.dotfiles-role
sudo bash server/scripts/server-init.sh        # root setup (sshd, ufw, /srv, lid)
bash server/install-server.sh                  # packages + stow + xdg
sudo bash server/scripts/strip-desktop.sh      # only if reinstalling onto a desktop-flavored Arch
```

## Layout

- `install-server.sh` — pacman packages + CLI-only stow set + XDG user-dirs
- `scripts/server-init.sh` — one-time root setup (sshd hardening, UFW, /srv, lid policy)
- `scripts/strip-desktop.sh` — remove Hyprland / GUI / audio packages (idempotent)
- `scripts/svc-new.sh` — provision a `/srv/<name>/` service slot
- `packages/packages.txt` — pacman package list
- `packages/aur.txt` — AUR package list (currently empty)
- `etc/` — root-owned config (sshd hardening, logind lid policy, XDG user-dirs)
- `stow/` — server-specific stow packages (placeholder)

## When the server profile is picked

`install.sh` checks `~/.dotfiles-role`. If it contains `server`, this folder is
used instead of `arch/install-arch.sh` on Arch hosts.

```sh
echo server > ~/.dotfiles-role
```

## What it installs

- Container runtime: `docker`, `docker-compose`, `docker-buildx`
- Networking: `cloudflared`, `tailscale`, `nginx`, `certbot`
- Hardening: `fail2ban`
- Backups: `restic`, `borg`
- Observability: `atop`, `sysstat`, `htop`, `btop`, `duf`, `iotop`, `lsof`
- Diagnostics: `bind-tools`, `inetutils`, `rsync`

## Stow set

CLI essentials only — shares the shell, editor, git, tmux, scripts, and prompt
configs with desktop hosts via `shared/stow/`. Plus `arch/stow/zsh` (zsh-defer)
and `arch/stow/pacseek`.

No `hypr`, `waybar`, `swaync`, `wofi`, `kitty`, `ghostty`, `alacritty`, etc.

## Service layout

Each Docker-compose stack lives under `/srv/<name>/` and runs as a dedicated
system user `svc_<name>` (uid <1000, no shell, no home). This isolates
services from each other and from the admin account — a container escape
gets you `svc_immich`, not `tri` and not root.

Layout:

```
/srv/<name>/
├── compose.yml   # owned by tri (you edit)
├── .env                 # PUID/PGID for svc_<name>
└── data/                # owned by svc_<name>:svc_<name>, mode 750
```

Provision a new slot:

```sh
sudo bash server/scripts/svc-new.sh <name>
```

## Root setup (one-time)

`server/scripts/server-init.sh` (run with sudo) handles:

- `/srv` directory creation
- sshd hardening drop-in copied from `server/etc/ssh/sshd_config.d/`
- UFW firewall install + rules (deny incoming, allow ssh from anywhere,
  allow everything on the tailnet interface)

Re-run safely; it's idempotent.

## Public exposure

No router ports are forwarded. Public web traffic is meant to flow through
**Cloudflare Tunnel** (`cloudflared`, installed), which dials out and needs
no inbound firewall rules. Tailnet (`tailscale0`) is fully trusted by UFW so
admin access just works over tailscale.
