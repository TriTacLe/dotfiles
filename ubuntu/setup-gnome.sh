#!/bin/bash

# Setup GNOME styling to match Arch/Hyprland look
set -e

echo "Setting up GNOME styling..."

# Install required packages
echo "Installing dependencies..."
sudo apt update
sudo apt install -y gnome-tweaks gnome-shell-extension-prefs \
    chrome-gnome-shell sassc

# Install Dash to Panel extension
echo "Installing Dash to Panel extension..."
if ! gnome-extensions list 2>/dev/null | grep -q "dash-to-panel"; then
    # Get latest version info
    LATEST_VERSION=$(curl -s "https://extensions.gnome.org/extension/1160/dash-to-panel/" | grep -oP 'data-version="\K[0-9]+' | head -1)
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION="65"  # fallback version
    fi
    
    # Download and install
    wget -O /tmp/dash-to-panel.zip \
        "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.io.v${LATEST_VERSION}.shell-extension.zip" || \
    wget -O /tmp/dash-to-panel.zip \
        "https://github.com/home-sweet-gnome/dash-to-panel/releases/download/v61/dash-to-panel@jderose9.github.io.zip"
    
    mkdir -p ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.io
    rm -rf ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.io/*
    unzip -o /tmp/dash-to-panel.zip -d \
        ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.io/
    
    # Enable extension
    gnome-extensions enable dash-to-panel@jderose9.github.io 2>/dev/null || true
fi

# Install Blur My Shell (for transparency effects)
echo "Installing Blur My Shell..."
if ! gnome-extensions list 2>/dev/null | grep -q "blur-my-shell"; then
    # Try to get latest version
    LATEST_VERSION=$(curl -s "https://extensions.gnome.org/extension/3193/blur-my-shell/" | grep -oP 'data-version="\K[0-9]+' | head -1)
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION="65"  # fallback version
    fi
    
    wget -O /tmp/blur-my-shell.zip \
        "https://extensions.gnome.org/extension-data/blur-my-shellaunetx.github.io.v${LATEST_VERSION}.shell-extension.zip" || \
    wget -O /tmp/blur-my-shell.zip \
        "https://github.com/aunetx/blur-my-shell/releases/download/v65/blur-my-shell@aunetx.zip"
    
    mkdir -p ~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx
    rm -rf ~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/*
    unzip -o /tmp/blur-my-shell.zip -d \
        ~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/
    
    gnome-extensions enable blur-my-shell@aunetx 2>/dev/null || true
fi

# Install User Themes extension (usually already installed)
echo "Installing User Themes extension..."
if ! gnome-extensions list 2>/dev/null | grep -q "user-theme"; then
    wget -O /tmp/user-theme.zip \
        "https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.io.v59.shell-extension.zip" 2>/dev/null || \
    wget -O /tmp/user-theme.zip \
        "https://github.com/gnome-shell-extensions/gnome-shell-extensions/releases/download/46.0/user-theme@gnome-shell-extensions.gcampax.github.io.zip"
    
    mkdir -p ~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.io
    rm -rf ~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.io/*
    unzip -o /tmp/user-theme.zip -d \
        ~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.io/
    
    gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.io 2>/dev/null || true
fi

# Install Catppuccin theme
echo "Installing Catppuccin GTK theme..."
if [ ! -d ~/.themes/Catppuccin-Mocha ]; then
    mkdir -p ~/.themes
    cd /tmp
    
    # Try to download latest release
    wget -O catppuccin-theme.zip \
        "https://github.com/catppuccin/gtk/releases/latest/download/Catppuccin-Mocha.zip" 2>/dev/null || \
    wget -O catppuccin-theme.zip \
        "https://github.com/catppuccin/gtk/releases/download/v1.0.3/Catppuccin-Mocha.zip"
    
    unzip -o catppuccin-theme.zip -d ~/.themes/ 2>/dev/null || echo "Theme download failed, will use default"
fi

# Install Catppuccin icons
echo "Installing Catppuccin icons..."
if [ ! -d ~/.icons/Catppuccin-Mocha ]; then
    mkdir -p ~/.icons
    cd /tmp
    
    # Try to download latest release
    wget -O catppuccin-icons.zip \
        "https://github.com/catppuccin/papirus-folders/releases/latest/download/Catppuccin-Mocha.zip" 2>/dev/null || \
    wget -O catppuccin-icons.zip \
        "https://github.com/catppuccin/papirus-folders/releases/download/v1.0.0/Catppuccin-Mocha.zip"
    
    unzip -o catppuccin-icons.zip -d ~/.icons/ 2>/dev/null || echo "Icons download failed, will use default"
fi

# Configure Dash to Panel settings
echo "Configuring Dash to Panel..."
gsettings set org.gnome.shell.extensions.dash-to-panel panel-positions \
    '{"0":"BOTTOM"}'
gsettings set org.gnome.shell.extensions.dash-to-panel panel-sizes \
    '{"0":48}'
gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-button false
gsettings set org.gnome.shell.extensions.dash-to-panel show-window-previews false
gsettings set org.gnome.shell.extensions.dash-to-panel isolate-workspaces false
gsettings set org.gnome.shell.extensions.dash-to-panel click-action 'CYCLE'
gsettings set org.gnome.shell.extensions.dash-to-panel scroll-icon-action 'CYCLE'
gsettings set org.gnome.shell.extensions.dash-to-panel show-tooltip false
gsettings set org.gnome.shell.extensions.dash-to-panel animate-show-apps false
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-focused 'METRO'
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-unfocused 'DOTS'
gsettings set org.gnome.shell.extensions.dash-to-panel tray-padding 12
gsettings set org.gnome.shell.extensions.dash-to-panel status-icon-padding 12

# Transparency for panel
gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-opacity true
gsettings set org.gnome.shell.extensions.dash-to-panel trans-panel-opacity 0.85

# Configure Blur My Shell
echo "Configuring Blur My Shell..."
gsettings set org.gnome.shell.extensions.blur-my-shell.panel blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.panel customize true
gsettings set org.gnome.shell.extensions.blur-my-shell.panel sigma 30
gsettings set org.gnome.shell.extensions.blur-my-shell.panel brightness 0.6

# Apply theme settings
echo "Applying theme settings..."
gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha'
gsettings set org.gnome.desktop.interface icon-theme 'Catppuccin-Mocha'
gsettings set org.gnome.shell.extensions.user-theme name 'Catppuccin-Mocha'

# Cursor theme
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'

# Font settings
gsettings set org.gnome.desktop.interface document-font-name 'Sans 11'
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 11'

# Window settings
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.shell.extensions.user-theme name 'Catppuccin-Mocha'

# Disable Ubuntu Dock (we use Dash to Panel now)
gsettings set org.gnome.shell.extensions.ding show-home false 2>/dev/null || true

# Tiling Assistant (already installed on Ubuntu)
echo "Configuring Tiling Assistant..."
gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false
gsettings set org.gnome.shell.extensions.tiling-assistant enable-raise-tile-group false
gsettings set org.gnome.shell.extensions.tiling-assistant maximize-with-gap true
gsettings set org.gnome.shell.extensions.tiling-assistant window-gap 8

# Keybindings for tiling (like Hyprland)
echo "Setting up window management keybindings..."
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super><Shift>m']"

# Workspace keybindings
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"

gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Super><Shift>5']"

# Focus windows (like i3/Hyprland)
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Super><Shift>Tab']"

# Screenshots
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['Print']"
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['<Shift>Print']"
gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "['<Alt>Print']"

# Terminal shortcut
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
    name 'Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
    command 'ghostty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
    binding '<Super>Return'

# Application launcher (Rofi)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ \
    name 'Application Launcher'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ \
    command 'rofi -show drun'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ \
    binding '<Super>d'

# Lock screen
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ \
    name 'Lock Screen'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ \
    command 'swaylock'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ \
    binding '<Super>l'

# Logout menu
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ \
    name 'Logout Menu'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ \
    command 'wlogout'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ \
    binding '<Super><Shift>e'

# Add Swaync to startup applications
echo "Adding Swaync to startup applications..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/swaync.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Swaync
Comment=Notification Center
Exec=swaync
X-GNOME-Autostart-enabled=true
EOF

echo ""
echo "================================"
echo "Setup complete!"
echo "================================"
echo ""
echo "You need to log out and back in for all changes to take effect."
echo ""
echo "New features:"
echo "- Dash to Panel at bottom (like waybar)"
echo "- Blur effects on panel"
echo "- Catppuccin Mocha theme"
echo "- Tiling window management"
echo "- Swaync notification center"
echo "- Swaylock lock screen"
echo "- Rofi application launcher"
echo "- Wlogout power menu"
echo ""
echo "Keybindings:"
echo "- Super+Return    : Open terminal"
echo "- Super+D         : Application launcher (Rofi)"
echo "- Super+L         : Lock screen (Swaylock)"
echo "- Super+Shift+E   : Power menu (Wlogout)"
echo "- Super+Q         : Close window"
echo "- Super+F         : Fullscreen"
echo "- Super+1-5       : Switch to workspace"
echo "- Super+Shift+1-5 : Move window to workspace"
echo ""
echo "To tweak further, open:"
echo "  gnome-tweaks"
echo "  gnome-extensions-app"
