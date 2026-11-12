# dotfiles

Arch Linux, Ubuntu, macOS and a headless Arch server, managed with GNU Stow. Hyprland on
the desktops, zsh and Neovim everywhere, one JSON palette driving the colours of every app.

Built for my machines, kept forkable: nothing personal is tracked, every machine-specific
value has a place outside git, and `install.sh` runs clean on a fresh box without touching
`/etc` unless asked.

## Install

Needs `git` and `sudo`. The installer adds `stow`, `just`, `jq` and the desktop manifest below.

```bash
git clone https://github.com/TriTacLe/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

It detects the OS, stows the package set for it, creates your profile under `profiles/<login>/`
and asks for your git name and email. Nothing is written outside your home.

Variants:

```bash
echo server > ~/.dotfiles-role && bash install.sh   # headless Arch: CLI packages only
bash install.sh --system                             # Arch desktop plus the /etc tuning below
bash install.sh --system-undo                        # remove that tuning again
```

A real `~/.zshrc`, `~/.gitconfig` or any other file in the way is moved to
`~/.dotfiles-backup/<timestamp>/` before linking, and the installer says so.

`--system` installs a 16 GB swapfile under /home, moves the pacman cache there, and drops
power, journald and zram settings into `/etc`. It is sized for a laptop with a small root
partition. Read `arch/install-arch.sh` before passing it.

## Make it yours

Everything that is yours lives in one place, `profiles/<login>/`, which is gitignored:

| Profile file | Linked to | Read by |
| --- | --- | --- |
| `gitconfig.local` | `~/.gitconfig.local` | `[include]` at the end of the stowed `.gitconfig` |
| `profile.env` | `<repo>/.env` | `shared.zsh` at shell start, with `set -a` |
| `zshrc.local` | `~/.zshrc.local` | sourced near the end of `shared.zsh` |
| `nvim.lua` | `~/.config/nvim/lua/config/local.lua` | `pcall(require, "config.local")` in `init.lua` |
| `ghostty.conf` | `~/.config/ghostty/local` | `config-file = ?local` |
| `hypr.lua` | `~/.config/hypr/host_local.lua` | `pcall(require, "host_local")` at the end of `hyprland.lua` |
| `CLAUDE.local.md`, `settings.local.json` | `~/.claude/` | Claude Code, if you use it |

Edit, then `just profile` to refresh the links. See `profiles/README.md`.

`KEYBINDINGS.md` lists every bind, generated from the config.

Machine hardware has its own layer: `<os>/stow/hypr-host/.config/hypr/host.lua` holds my
monitors, touchpad, dock output and Norwegian keyboard. It loads after the shared config and
before your `hypr.lua`, so you can override it without editing it, or drop `hypr-host` from
the `justfile` list and write your own. The shared config defaults to a US layout.

## What gets stowed

`justfile` holds the lists. `just stow arch` (or `ubuntu`, `macos`, `server`) restows
everything for this machine; `just unstow <os>` removes every link.

| Set | Packages | Notes |
| --- | --- | --- |
| `shared_desktop` | git nvim lazygit zsh mise tmux alacritty ghostty kitty hypr waybar swaync wofi nwg-dock nwg-look wlogout zathura gtk backgrounds scripts ipython | Arch and Ubuntu desktops |
| `shared_cli` | git nvim lazygit zsh mise tmux scripts ipython | server |
| `shared_macos` | git nvim lazygit zsh mise backgrounds scripts ipython | macOS |
| `arch` | zsh fastfetch hypr-host pacseek systemd | on top of `shared_desktop` |
| `ubuntu` | zsh rofi swaylock fontconfig systemd hypr-host sway | on top of `shared_desktop` |
| `macos` | zsh tmux alacritty ghostty kitty neofetch starship | on top of `shared_macos` |
| `server` | zsh pacseek | on top of `shared_cli` |

Each package is a plain stow package: `stow -d shared/stow -t ~ waybar` takes one config
and nothing else.

`claude-config/` is a private submodule holding my Claude Code setup. The clone warns and
carries on without it. Point `DOTFILES_CLAUDE_REPO` in your `profile.env` at your own.

## Theme

`theme_apply.sh <name>` reads one palette from `shared/stow/hypr/.config/hypr/themes/*.json`
and writes generated colour files for Hyprland, hyprlock, waybar, swaync, wlogout, nwg-dock,
wofi, ghostty, kitty, alacritty, Neovim, the zsh prompt and GTK 3 and 4. Generated files are
gitignored. Add a theme by adding a JSON file; `theme` in the shell toggles light and dark.

## Packages

`arch/packages/desktop.txt` and `aur-desktop.txt` are the curated manifests the Arch installer
installs, grouped and commented; `ubuntu/packages/desktop.txt` is the apt one. The AUR half
needs `paru` or `yay` and is skipped with a note otherwise. `packages.txt` and `aur.txt` next to them
are snapshots written by the pacman and apt post-transaction hooks: what my machines have
installed, never installed by the installer. `server/packages/packages.txt` and
`macos/Brewfile` are installed as before.

## Layout

- `shared/stow/`: packages every OS can use, one directory per program.
- `<os>/`: installer, OS-only stow packages, `/etc` files, package snapshots.
- `shared/scripts/`: `config.sh` (shared bash library, profile logic), `verify-system.sh`
  (repo health checks), `tests/run.sh`.
- `profiles/`: per-person overrides, see above.
- `MACHINES.md`: notes on my hosts.

## Credits

Theme pipeline, Hyprland Lua layout and the host overlay idea follow
[filip-rs/arch-dotfiles](https://github.com/filip-rs/arch-dotfiles). MIT, see `LICENSE`.
