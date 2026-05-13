# macOS Zsh Configuration

# Source per-machine .env if present (paths, prefs)
for _df in "$DOTFILES_DIR" "$HOME/dotfiles" "$HOME/Desktop/dotfiles" "$HOME/.dotfiles"; do
    if [[ -n "$_df" && -f "$_df/.env" ]]; then
        set -a; source "$_df/.env"; set +a
        export DOTFILES_DIR="$_df"
        break
    fi
done
unset _df

# ============================================
# Oh My Zsh
# ============================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    brew
    macos
    colored-man-pages
    command-not-found
    copypath
    copyfile
    dirhistory
    history
    sudo
)

source $ZSH/oh-my-zsh.sh

# ============================================
# PATH Configuration
# ============================================

# Homebrew (Apple Silicon)
if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || /usr/libexec/java_home)
export PATH="$JAVA_HOME/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Node/NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# ============================================
# Prompt
# ============================================
eval "$(starship init zsh)"

# ============================================
# FZF
# ============================================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# ============================================
# Zoxide
# ============================================
eval "$(zoxide init zsh)"
alias cd='z'

# ============================================
# The Fuck
# ============================================
eval "$(thefuck --alias)"

# ============================================
# Navigation Aliases
# ============================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias home='cd ~'
alias desktop='cd ~/Desktop'
alias downloads='cd ~/Downloads'
alias documents='cd ~/Documents'
# Dev-dir aliases: guard on existence (paths from .env override defaults)
[[ -d "${DOTFILES_DIR:-$HOME/dotfiles}" ]] && alias dotfiles="cd ${DOTFILES_DIR:-$HOME/dotfiles}"
[[ -d "${DEV_DIR:-$HOME/dev}" ]] && alias dev="cd ${DEV_DIR:-$HOME/dev}"
[[ -d "${DEV_DIR:-$HOME/dev}/personal" ]] && alias personal="cd ${DEV_DIR:-$HOME/dev}/personal"
[[ -d "${DEV_DIR:-$HOME/dev}/ntnu" ]] && alias ntnu="cd ${DEV_DIR:-$HOME/dev}/ntnu"
[[ -d "${ORBIT_DIR:-${DEV_DIR:-$HOME/dev}/orbit}" ]] && alias orbit="cd ${ORBIT_DIR:-${DEV_DIR:-$HOME/dev}/orbit}"
[[ -d "${DEV_DIR:-$HOME/dev}/duxpace" ]] && alias duxpace="cd ${DEV_DIR:-$HOME/dev}/duxpace"
[[ -d "${DEV_DIR:-$HOME/dev}/work" ]] && alias work="cd ${DEV_DIR:-$HOME/dev}/work"

# ============================================
# System Aliases
# ============================================
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias today='date +%Y-%m-%d'
alias week='date +%V'
alias timestamp='date +%s'

# ============================================
# Config Shortcuts
# ============================================
alias zshrc='nvim ~/.zshrc'
alias zshrcs='source ~/.zshrc'
alias vimrc='nvim ~/.config/nvim/init.lua'
alias gitconfig='nvim ~/.gitconfig'
alias tmuxconf='nvim ~/.tmux.conf'
alias starshipconf='nvim ~/.config/starship.toml'
alias kittyconf='nvim ~/.config/kitty/kitty.conf'

# ============================================
# Network
# ============================================
alias ip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias ping='ping -c 5'
alias ports='lsof -i -P | grep LISTEN'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# ============================================
# macOS Specific
# ============================================
alias finder='open -a Finder'
alias hide='chflags hidden'
alias unhide='chflags nohidden'
alias cleanup='find . -type f -name "*.DS_Store" -ls -delete'
alias emptytrash='sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl'
alias update='brew update && brew upgrade && brew cleanup'
alias ql='qlmanage -p 2>/dev/null'
alias showhidden='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidehidden='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'

# ============================================
# SSH
# ============================================
alias sshkey='cat ~/.ssh/id_ed25519.pub | pbcopy'
alias sshconf='nvim ~/.ssh/config'
alias sshhosts='cat ~/.ssh/config | grep "Host " | sed "s/Host //"'

# ============================================
# Fun/Misc
# ============================================
alias weather='curl wttr.in'
alias moon='curl wttr.in/moon'
alias shrug='echo "¯\_(ツ)_/¯" | pbcopy'

# Copy file content to clipboard
copy() { cat "$1" | pbcopy }

# ============================================
# Stow Management
# ============================================
: "${DOTFILES_DIR:=$HOME/dotfiles}"

stow-all() {
    stow -d "$DOTFILES_DIR/shared/stow" -t ~ --no-folding git nvim starship lazygit backgrounds zsh
    stow -d "$DOTFILES_DIR/macos/stow" -t ~ --no-folding zsh tmux alacritty ghostty kitty neofetch
    stow -d "$DOTFILES_DIR" -t ~/.claude -R claude-config
}

stow-pkg() {
    if [ -z "$1" ]; then echo "Usage: stow-pkg <package>"; return 1; fi
    local pkg="$1"
    if [[ "$pkg" == "claude-config" ]]; then
        stow -d "$DOTFILES_DIR" -t ~/.claude -R claude-config
        return
    fi
    [[ -d "$DOTFILES_DIR/shared/stow/$pkg" ]] && stow -d "$DOTFILES_DIR/shared/stow" -t ~ --no-folding -R "$pkg"
    [[ -d "$DOTFILES_DIR/macos/stow/$pkg" ]] && stow -d "$DOTFILES_DIR/macos/stow" -t ~ --no-folding -R "$pkg"
}

unstow-pkg() {
    if [ -z "$1" ]; then echo "Usage: unstow-pkg <package>"; return 1; fi
    local pkg="$1"
    if [[ "$pkg" == "claude-config" ]]; then
        stow -d "$DOTFILES_DIR" -t ~/.claude -D claude-config
        return
    fi
    [[ -d "$DOTFILES_DIR/shared/stow/$pkg" ]] && stow -d "$DOTFILES_DIR/shared/stow" -t ~ --no-folding -D "$pkg"
    [[ -d "$DOTFILES_DIR/macos/stow/$pkg" ]] && stow -d "$DOTFILES_DIR/macos/stow" -t ~ --no-folding -D "$pkg"
}

# ============================================
# Shared config + secrets
# ============================================
[ -f ~/.config/zsh/shared.zsh ] && source ~/.config/zsh/shared.zsh
[ -f ~/.zshenv.secrets ] && source ~/.zshenv.secrets

# ============================================
# Welcome Message
# ============================================
if [[ -o interactive ]]; then
    if command -v fastfetch &>/dev/null; then
        fastfetch
    elif command -v neofetch &>/dev/null; then
        neofetch
    else
        echo "Hei, $(whoami)!"
        echo "System: $(sw_vers -productName) $(sw_vers -productVersion)"
    fi
fi
