# Justfile for dotfiles management
# https://github.com/catppuccin/just

[install]
 brew bundle --file=macos/Brewfile

[update]
 brew bundle --file=macos/Brewfile --upgrade

[stow]
 just --justfile=.justfile stow macos

[backup]
 just --justfile=.justfile backup-dotfiles

[switch]
 just --justfile=.justfile switch-profile