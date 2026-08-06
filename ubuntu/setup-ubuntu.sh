#!/bin/bash

# Ubuntu Dotfiles Setup Script
# Installs Arch-like tools on Ubuntu

set -e

echo "Setting up Ubuntu with Arch-like tools..."
echo ""

# Update system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install essential build tools
echo "Installing build essentials..."
sudo apt install -y build-essential git curl wget software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release

# Install ZSH and make it default
echo "Installing ZSH..."
sudo apt install -y zsh
if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
    echo "Making ZSH the default shell..."
    chsh -s "$(which zsh)"
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Powerlevel10k theme
echo "Installing Powerlevel10k theme..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# Install ZSH plugins
echo "Installing ZSH plugins..."

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# Install modern CLI tools
echo "Installing modern CLI tools..."

# eza (modern ls)
if ! command -v eza &> /dev/null; then
    echo "Installing eza..."
    sudo apt install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
fi

# bat (modern cat)
if ! command -v bat &> /dev/null; then
    echo "Installing bat..."
    sudo apt install -y bat
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/batcat ~/.local/bin/bat
    fi
fi

# fd (modern find)
if ! command -v fd &> /dev/null; then
    echo "Installing fd..."
    sudo apt install -y fd-find
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(which fdfind)" ~/.local/bin/fd
    fi
fi

# fzf (fuzzy finder)
if ! command -v fzf &> /dev/null; then
    echo "Installing fzf..."
    sudo apt install -y fzf
fi

# zoxide (smart cd)
if ! command -v zoxide &> /dev/null; then
    echo "Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# btop (system monitor)
if ! command -v btop &> /dev/null; then
    echo "Installing btop..."
    sudo apt install -y btop || {
        echo "btop not in repos, installing from source..."
        sudo snap install btop
    }
fi

# lazygit (TUI for git)
if ! command -v lazygit &> /dev/null; then
    echo "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
fi

# neofetch or fastfetch
if ! command -v fastfetch &> /dev/null && ! command -v neofetch &> /dev/null; then
    echo "Installing neofetch..."
    sudo apt install -y neofetch
fi

# thefuck (command corrector)
if ! command -v thefuck &> /dev/null; then
    echo "Installing thefuck..."
    sudo apt install -y thefuck
fi

# yt-dlp (video downloader)
if ! command -v yt-dlp &> /dev/null; then
    echo "Installing yt-dlp..."
    sudo wget -qO /usr/local/bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
fi

# Neovim (if not installed)
if ! command -v nvim &> /dev/null; then
    echo "Installing Neovim..."
    sudo apt install -y neovim
fi

# Tmux (if not installed)
if ! command -v tmux &> /dev/null; then
    echo "Installing tmux..."
    sudo apt install -y tmux
fi

# TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install Wayland rice tools
echo "Installing Wayland rice tools..."

# Rofi (Wayland fork)
if ! command -v rofi &> /dev/null; then
    echo "Installing Rofi (Wayland)..."
    sudo apt install -y rofi-wayland || {
        echo "rofi-wayland not available, building from source..."
        sudo apt install -y build-essential git meson ninja-build pkg-config \
            libglib2.0-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf2.0-dev \
            libxkbcommon-dev libxkbcommon-x11-dev libwayland-dev wayland-protocols \
            libxcb-aux-dev libxcb-xinerama0-dev libxcb-randr0-dev \
            libxcb-icccm4-dev libstartup-notification0-dev
        rm -rf /tmp/rofi-wayland
        git clone https://github.com/lbonn/rofi.git /tmp/rofi-wayland
        cd /tmp/rofi-wayland
        git checkout wayland
        meson setup build
        ninja -C build
        sudo ninja -C build install
        cd /
        rm -rf /tmp/rofi-wayland
    }
fi

# Swaync (notification daemon)
if ! command -v swaync &> /dev/null; then
    echo "Installing Swaync..."
    sudo apt install -y swaync || {
        echo "swaync not in repos, installing from source..."
        sudo apt install -y meson ninja-build libgtk-3-dev libgtk-layer-shell-dev \
            libjson-glib-dev libgee-0.8-dev valac
        git clone https://github.com/ErikReider/SwayNotificationCenter.git /tmp/swaync
        cd /tmp/swaync
        meson build
        ninja -C build
        sudo ninja -C build install
        cd /
        rm -rf /tmp/swaync
    }
fi

# Swaylock
if ! command -v swaylock &> /dev/null; then
    echo "Installing Swaylock..."
    sudo apt install -y swaylock
fi

# Audio control (used by waybar pulseaudio module)
if ! command -v pamixer &> /dev/null; then
    echo "Installing pamixer..."
    sudo apt install -y pamixer
fi

if ! command -v pavucontrol &> /dev/null; then
    echo "Installing pavucontrol..."
    sudo apt install -y pavucontrol
fi

# Bluetooth tray (waybar exec-once = blueman-applet)
if ! command -v blueman-applet &> /dev/null; then
    echo "Installing blueman..."
    sudo apt install -y blueman
fi

# Norwegian char keybinds: Super+[/;/' -> å/ø/æ
if ! command -v wtype &> /dev/null; then
    echo "Installing wtype..."
    sudo apt install -y wtype
fi

# Avizo volume/brightness overlay (build from source - not in apt)
if ! command -v avizo-client &> /dev/null; then
    echo "Building avizo from source..."
    sudo apt install -y meson ninja-build scdoc libgtk-layer-shell-dev \
        libgirepository1.0-dev valac
    git clone https://github.com/misterdanb/avizo.git /tmp/avizo
    (cd /tmp/avizo && meson setup build && ninja -C build && sudo ninja -C build install)
    rm -rf /tmp/avizo
fi

# Wlogout
if ! command -v wlogout &> /dev/null; then
    echo "Installing Wlogout..."
    sudo apt install -y wlogout || {
        echo "wlogout not in repos, building from source..."
        sudo apt install -y meson ninja-build scdoc wayland-protocols \
            wayland-scanner libgtk-layer-shell-dev
        git clone https://github.com/ArtsyMacaw/wlogout.git /tmp/wlogout
        cd /tmp/wlogout
        meson build
        ninja -C build
        sudo ninja -C build install
        cd /
        rm -rf /tmp/wlogout
    }
fi

# Screenshot tools for Wayland
if ! command -v grim &> /dev/null; then
    echo "Installing grim and slurp..."
    sudo apt install -y grim slurp
fi

if ! command -v wl-copy &> /dev/null; then
    echo "Installing wl-clipboard..."
    sudo apt install -y wl-clipboard
fi

# Fontconfig
if [ ! -d "$HOME/.config/fontconfig" ]; then
    echo "Setting up Fontconfig..."
    mkdir -p ~/.config/fontconfig
fi

# Install Nerd Font
if ! fc-list | grep -q "JetBrainsMono"; then
    echo "Installing JetBrainsMono Nerd Font..."
    mkdir -p ~/.local/share/fonts
    cd /tmp
    wget -O jetbrains-mono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -o jetbrains-mono.zip -d ~/.local/share/fonts/
    fc-cache -fv
    cd /
    rm -f /tmp/jetbrains-mono.zip
fi

# Create necessary directories
mkdir -p ~/.config/{zsh,tmux,git,rofi,swaync,swaylock,wlogout,fontconfig}

# Setup symlinks for dotfiles
echo "Setting up dotfile symlinks..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ZSH
ln -sf "$SCRIPT_DIR/configs/zsh/.zshrc" ~/.zshrc

# Tmux
ln -sf "$SCRIPT_DIR/configs/tmux/.tmux.conf" ~/.tmux.conf

# Git
ln -sf "$SCRIPT_DIR/configs/git/.gitconfig" ~/.gitconfig

# Rofi
ln -sf "$SCRIPT_DIR/configs/rofi/config.rasi" ~/.config/rofi/config.rasi
ln -sf "$SCRIPT_DIR/configs/rofi/catppuccin-mocha.rasi" ~/.config/rofi/catppuccin-mocha.rasi

# Swaync
ln -sf "$SCRIPT_DIR/configs/swaync/config.json" ~/.config/swaync/config.json
ln -sf "$SCRIPT_DIR/configs/swaync/style.css" ~/.config/swaync/style.css

# Swaylock
ln -sf "$SCRIPT_DIR/configs/swaylock/config" ~/.config/swaylock/config

# Wlogout
ln -sf "$SCRIPT_DIR/configs/wlogout/layout" ~/.config/wlogout/layout
ln -sf "$SCRIPT_DIR/configs/wlogout/style.css" ~/.config/wlogout/style.css

# Fontconfig
ln -sf "$SCRIPT_DIR/configs/fontconfig/fonts.conf" ~/.config/fontconfig/fonts.conf

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: source ~/.zshrc"
echo "2. Run p10k configure to set up Powerlevel10k theme"
echo "3. Open tmux and press prefix + I to install tmux plugins"
echo "4. Run ./setup-gnome.sh for GNOME rice setup"
echo ""
echo "If this is your first time, you may need to log out and back in for ZSH to be default."
