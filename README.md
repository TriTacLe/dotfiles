# dotfiles

Dotfiles for Arch Linux, Ubuntu, macOS, and a headless Arch server. Managed with GNU Stow. The base config is shared; each person keeps their identity and preferences in a local, gitignored profile.

Massive creds to [filip-rs](https://github.com/filip-rs/)

## Install

```bash
git clone git@github.com:TriTacLe/dotfiles.git
cd dotfiles
bash install.sh
```

The script detects OS and distro, then runs the appropriate installer. On first run it creates `profiles/<login>/` from `profiles/example/` and asks for the git name and email. Nothing personal is committed. See `profiles/README.md` for the file map and how to switch profiles.

For the headless server role on Arch, pin it first:

```bash
echo "server" > ~/.dotfiles-role
bash install.sh
```

Per-machine shell variables live in `profiles/<name>/profile.env`, symlinked to `.env` in the repo root and sourced by the shell at startup.

## What's included

- `shared/stow/` - packages every machine gets: git, nvim, lazygit, zsh, mise, tmux, kitty,
  ghostty, alacritty, hypr, waybar, swaync, wofi, nwg-dock, nwg-look,
  wlogout, zathura, backgrounds, scripts, ipython.
- `arch/`, `ubuntu/`, `macos/`, `server/` - per-OS installer plus the packages only that
  OS uses (fastfetch and pacseek on Arch, rofi and swaylock on Ubuntu, starship on macOS).
- `<os>/stow/hypr-host/` - per-host Hyprland overlay holding the machine-specific bits:
  monitor names, resolutions, scale, GPU env, touchpad device.
- `profiles/` - local per-person overrides for git, zsh, nvim, Ghostty, and Claude.
  Only `profiles/example/` and `profiles/README.md` are tracked.
- `shared/scripts/` - `config.sh` (shared shell library and profile bootstrap) and
  `verify-system.sh` (repo health checks, run before deploying to a fresh machine).
- `arch/packages/`, `ubuntu/packages/` - package lists, regenerated automatically by the
  pacman/apt post-transaction hook.
- `justfile` - the stow package lists. `just stow arch` (or ubuntu, macos, server) restows
  everything on this machine. `just profile` creates or refreshes the local profile links.

## Claude config

The installer links `~/.claude` to the directory named by `CLAUDE_CONFIG_DIR` or
`CLAUDE_CONFIG_REPO` in `profile.env`. With neither set it uses the bundled
`claude-config` submodule when that is initialized. The profile's `CLAUDE.local.md` and
`settings.local.json` are linked into whichever directory is active and stay untracked.

## Adding a new machine

1. Create a host overlay at `<os>/stow/hypr-host/.config/hypr/host.lua` if needed.
2. Run `install.sh` and fill in the profile prompt.
