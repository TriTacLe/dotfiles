# Shared Zsh Configuration — sourced by all OS-specific .zshrc files
# Place: ~/.config/zsh/shared.zsh

# ============================================
# History
# ============================================
export HISTSIZE=12000
export SAVEHIST=10000
export HISTFILE=~/.zshhist
export HISTDUP=erase
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS

# ============================================
# Editor
# ============================================
export EDITOR='nvim'
export VISUAL='nvim'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# ============================================
# Git
# ============================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gpl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -D'
alias gsw='git switch'
alias glg='git log --oneline --graph --decorate --all'

gacp() { git add .; git commit -m "$*"; git push }

# ============================================
# Tmux
# ============================================
alias t='tmux'
alias ta='tmux attach'
alias tl='tmux ls'
alias tk='tmux kill-session'
alias lg='lazygit'

# ============================================
# Docker
# ============================================
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps'
alias di='docker images'
alias dprune='docker system prune -f'

# ============================================
# Maven
# ============================================
alias m='mvn'
alias mc='mvn clean'
alias mi='mvn install'
alias mcis='mvn clean install -DskipTests'
alias mci='mvn clean install'
alias mp='mvn package'
alias mcp='mvn clean package'
alias mt='mvn test'
alias mcv='mvn clean verify'
alias mtree='mvn dependency:tree'

# ============================================
# NPM
# ============================================
alias ni='npm install'
alias nid='npm install --save-dev'
alias ns='npm start'
alias nb='npm run build'
alias nd='npm run dev'
alias nr='npm run'
alias nu='npm update'
alias nclean='rm -rf node_modules package-lock.json && npm install'

# ============================================
# Gradle
# ============================================
alias gr='./gradlew'
alias grb='./gradlew build'
alias grc='./gradlew clean'
alias grcb='./gradlew clean build'
alias grt='./gradlew test'
alias grr='./gradlew bootRun'

# Spring Boot
alias sbr='./mvnw spring-boot:run'

# ============================================
# File operations (conditional on available tools)
# ============================================
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias l='eza -la --icons'
    alias ll='eza -l --icons'
    alias la='eza -la --icons --group-directories-first --sort=type'
    alias lt='eza --tree --icons'
fi
if command -v bat &>/dev/null; then
    alias cat='bat --style=plain --paging=never'
fi
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

# ============================================
# Functions
# ============================================

mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.tar.xz)    tar xJf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

ff() { find . -name "$1" 2>/dev/null }
fstr() { grep -r "$1" . 2>/dev/null }
backup() { cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)" }
serve() { python3 -m http.server "${1:-8000}" }
branch() { git branch 2>/dev/null | grep '*' | sed 's/* //' }
killport() { lsof -ti:"$1" | xargs kill -9 2>/dev/null || echo "No process on port $1" }

# ============================================
# Keybindings
# ============================================
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[127;5u' backward-kill-word
bindkey '^[[127;3u' backward-kill-line

# ============================================
# Auto-activate Python venv on cd
# ============================================
chpwd() {
    [[ -d .venv ]] && source .venv/bin/activate
    [[ -d venv ]] && source venv/bin/activate
}

# ============================================
# SSH TERM fix for Ghostty connecting to older servers
# ============================================
ssh() {
    if [[ "$TERM" == "xterm-ghostty" ]]; then
        TERM=xterm-256color command ssh "$@"
    else
        command ssh "$@"
    fi
}
