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

Dotfiles
Machine-specific display settings (monitor names, DPI, scale) are in per-host Hyprland overlays.

## Adding a new machine

1. Create a host overlay at `<os>/stow/hypr-host/host.conf` if needed.
2. Run `install.sh`.
