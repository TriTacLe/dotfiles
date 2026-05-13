# Ubuntu Zsh Configuration

# Enable Powerlevel10k instant prompt — must stay near top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================
# PATH
# ============================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Bun
if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
fi

# ============================================
# Oh My Zsh
# ============================================
export ZSH="$HOME/.oh-my-zsh"
export TERMINAL_EMULATOR="ghostty"

if [ -d "$ZSH/custom/themes/powerlevel10k" ] || [ -f "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme" ]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
else
    ZSH_THEME="robbyrussell"
fi

HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

plugins=(git)
[ -d "$ZSH/custom/plugins/zsh-autosuggestions" ] && plugins+=(zsh-autosuggestions)
[ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ] && plugins+=(zsh-syntax-highlighting)
[ -d "$ZSH/custom/plugins/fzf" ] && plugins+=(fzf)
[ -d "$ZSH/custom/plugins/zoxide" ] && plugins+=(zoxide)

source $ZSH/oh-my-zsh.sh

# ============================================
# FZF
# ============================================
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if command -v fzf &>/dev/null; then
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {}'"
    export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
fi

# ============================================
# Zoxide
# ============================================
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
    alias cd='z'
    alias zi='z -i'
fi

# ============================================
# The Fuck
# ============================================
if command -v thefuck &>/dev/null && thefuck --version &>/dev/null; then
    eval "$(thefuck --alias)"
fi

# ============================================
# Powerlevel10k
# ============================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
[[ -f /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]] && \
    source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# ============================================
# Ubuntu-specific aliases
# ============================================
alias update='sudo apt update && sudo apt upgrade -y'
alias inst='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias autoremove='sudo apt autoremove'
alias pkgfnd='dpkg -l | grep'

alias c='clear'
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias please='sudo'
alias fking='sudo'
alias py='python3'

alias dotfiles='cd ~/dotfiles'
alias project='cd ~/Desktop/projects'
alias desktop='cd ~/Desktop'
alias documents='cd ~/Documents'
alias downloads='cd ~/Downloads'

alias zshconf='nvim ~/.zshrc && source ~/.zshrc'
alias bashconf='nvim ~/.bashrc && source ~/.bashrc'
alias vimconf='nvim ~/.config/nvim/init.lua'

alias bt='sudo systemctl start bluetooth'
alias wifilist='nmcli device wifi list'
alias wificonnect='nmcli device wifi connect --ask'
alias fnd='ls -a | grep -i'
alias lsblk='lsblk --output NAME,SIZE,TYPE,MOUNTPOINT,MODEL'

alias rofi-launch='rofi -show drun'
alias rofi-run='rofi -show run'
alias rofi-window='rofi -show window'
alias lock='swaylock'
alias logout-menu='wlogout'

if command -v eza &>/dev/null; then
    alias ls='eza --icons=auto'
    alias l='eza -la --icons=auto'
    alias ll='eza -l --icons=auto'
    alias lss='eza --tree --icons=auto --level=2'
    alias lsss='eza --tree --icons=auto --level=3'
    alias lssss='eza --tree --icons=auto --level=4'
else
    alias ls='ls --color=auto'
    alias l='ls -la'
    alias la='ls -la'
    alias ll='ls -l'
fi

if command -v bat &>/dev/null; then
    alias cat='bat --style=plain --paging=never'
    alias catl='bat'
fi

if command -v btop &>/dev/null; then
    alias top='btop'
    alias htop='btop'
fi

if command -v yazi &>/dev/null; then
    alias y='yazi'
    alias ya='yazi'
fi

if command -v fastfetch &>/dev/null; then
    alias fetch='fastfetch'
    alias neofetch='fastfetch'
elif command -v neofetch &>/dev/null; then
    alias fetch='neofetch'
fi

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
    fi
fi
