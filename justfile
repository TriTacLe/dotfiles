# Stow package lists live here. The installers call `just stow <os>`.

dotfiles := justfile_directory()

shared_desktop := "git nvim lazygit backgrounds zsh mise tmux alacritty ghostty kitty hypr waybar swaync wofi nwg-dock nwg-look wlogout scripts ipython zathura gtk"
shared_macos := "git nvim lazygit backgrounds zsh mise scripts ipython"
shared_cli := "git nvim lazygit zsh mise tmux scripts ipython"
arch_pkgs := "zsh fastfetch hypr-host pacseek systemd"
ubuntu_pkgs := "zsh rofi swaylock fontconfig systemd hypr-host sway"
macos_pkgs := "zsh tmux alacritty ghostty kitty neofetch starship"
server_pkgs := "zsh pacseek"

# Restow every package for an OS: arch, ubuntu, macos or server
stow os: (_stow os "-R")

# Homebrew has no post-install hook, so unlike pacman and apt this is manual.
# Snapshot installed brew packages into macos/Brewfile and commit any change
pkgtrack-macos:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{dotfiles}}"
    brew bundle dump --file=macos/Brewfile --force --no-describe
    git add macos/Brewfile
    if git diff --cached --quiet -- macos/Brewfile; then
        echo "Brewfile unchanged"
        exit 0
    fi
    host=$(hostname -s 2>/dev/null || hostname)
    git commit -m "[AUTO] [$(date '+%Y-%m-%d')] [$host:macos] brew snapshot" -- macos/Brewfile
    if git push; then
        echo "Pushed successfully"
    else
        echo "push refused, master is protected: push a branch and open a PR" >&2
    fi

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
    # ~/.claude is one symlink to the claude-config submodule, not a stow tree.
    # Guarded the same way link_claude_config is: never clobber a real directory.
    if [ "{{flag}}" = "-R" ]; then
        if [ -d ~/.claude ] && [ ! -L ~/.claude ]; then
            echo "~/.claude is a real directory, leaving it alone" >&2
        else
            ln -sfn "{{dotfiles}}/claude-config" ~/.claude
        fi
    elif [ -L ~/.claude ]; then
        rm -f ~/.claude
    fi
