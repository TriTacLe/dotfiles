# dotfiles

Personal dotfiles for Arch Linux, Ubuntu, macOS, and a headless Arch server. Managed with GNU Stow.

Massive creds to [filip-rs](https://github.com/filip-rs/)

## Install

```bash
git clone git@github.com:TriTacLe/dotfiles.git
cd dotfiles
bash install.sh
```

The script detects OS and distro, then runs the appropriate installer. For the headless server role on Arch, pin it first:

```bash
echo "server" > ~/.dotfiles-role
bash install.sh
```

## What's included

- `shared/stow/` - packages every machine gets: git, nvim, lazygit, zsh, tmux, kitty,
  ghostty, alacritty, hypr, waybar, swaync, wofi, avizo, wob, nwg-dock, nwg-look,
  wlogout, zathura, backgrounds, scripts, ipython.
- `arch/`, `ubuntu/`, `macos/`, `server/` - per-OS installer plus the packages only that
  OS uses (fastfetch and pacseek on Arch, rofi and swaylock on Ubuntu, starship on macOS).
- `<os>/stow/hypr-host/` - per-host Hyprland overlay holding the machine-specific bits:
  monitor names, resolutions, scale, GPU env, touchpad device.
- `shared/scripts/` - `config.sh` (shared shell library) and `verify-system.sh`
  (repo health checks, run before deploying to a fresh machine).
- `arch/packages/`, `ubuntu/packages/` - package lists, regenerated automatically by the
  pacman/apt post-transaction hook.

## Adding a new machine

1. Create a host overlay at `<os>/stow/hypr-host/.config/hypr/host.lua` if needed.
2. Run `install.sh`.
