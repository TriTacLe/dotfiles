# Stow package lists live here. The installers call `just stow <os>`.

dotfiles := justfile_directory()

shared_desktop := "git nvim lazygit backgrounds zsh mise tmux alacritty ghostty kitty hypr waybar swaync wofi nwg-dock nwg-look wlogout scripts ipython zathura"
shared_macos := "git nvim lazygit backgrounds zsh mise scripts ipython"
shared_cli := "git nvim lazygit zsh mise tmux scripts ipython"
arch_pkgs := "zsh fastfetch hypr-host pacseek systemd"
ubuntu_pkgs := "zsh rofi swaylock fontconfig systemd hypr-host sway"
macos_pkgs := "zsh tmux alacritty ghostty kitty neofetch starship"
server_pkgs := "zsh pacseek"

# Restow every package for an OS: arch, ubuntu, macos or server
stow os: (_stow os "-R")

# Remove every stowed link for an OS
unstow os: (_stow os "-D")

_stow os flag:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{os}}" in
        arch)   shared="{{shared_desktop}}"; dir=arch;   pkgs="{{arch_pkgs}}" ;;
        ubuntu) shared="{{shared_desktop}}"; dir=ubuntu; pkgs="{{ubuntu_pkgs}}" ;;
        macos)  shared="{{shared_macos}}";   dir=macos;  pkgs="{{macos_pkgs}}" ;;
        server) shared="{{shared_cli}}";     dir=arch;   pkgs="{{server_pkgs}}" ;;
        *) echo "unknown os '{{os}}', expected arch, ubuntu, macos or server" >&2; exit 1 ;;
    esac
    mkdir -p ~/.config
    # -R because --no-folding links files one by one, so a rename would
    # otherwise leave a stale link behind.
    stow -d "{{dotfiles}}/shared/stow" -t ~ --no-folding {{flag}} $shared
    stow -d "{{dotfiles}}/$dir/stow" -t ~ --no-folding {{flag}} $pkgs
    [ "{{flag}}" = "-R" ] && ln -sfn "{{dotfiles}}/claude-config" ~/.claude || true
