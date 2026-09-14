# Shared zsh config, sourced first by every OS .zshrc. The OS files add only
# what differs: package manager aliases, platform paths, the macOS prompt.

# Per-machine .env (project paths, prefs). set -a exports every line.
for _df in "$DOTFILES_DIR" "$HOME/Desktop/dotfiles" "$HOME/dotfiles" "$HOME/.dotfiles"; do
    if [[ -n "$_df" && -f "$_df/.env" ]]; then
        set -a; source "$_df/.env"; set +a
        export DOTFILES_DIR="$_df"
        break
    fi
done
unset _df
: "${DOTFILES_DIR:=$HOME/Desktop/dotfiles}"

# PATH
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.npm-global/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH"
# Runtimes: mise when installed (versions in ~/.config/mise/config.toml),
# else the per-tool initialisers it replaces.
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
else
    if [[ -d "$HOME/.bun" ]]; then
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
    fi
    [[ -f "$HOME/.deno/env" ]] && source "$HOME/.deno/env"
fi

# Environment
export EDITOR='nvim'
export VISUAL='nvim'
export TERMINAL_EMULATOR='ghostty'
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# History
export HISTSIZE=12000
export SAVEHIST=10000
export HISTFILE=~/.zshhist
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS HIST_IGNORE_DUPS HIST_FIND_NO_DUPS

# Completion
autoload -Uz compinit && compinit -d ~/.config/zsh/.zcompdump
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Plugins through antidote. The bundle list is stowed; the static file it
# writes next to it is generated and untracked. The first start on a machine
# clones antidote and the plugins, which takes a moment; do not interrupt it.
is_linux() { [[ $OSTYPE == linux* ]] }
is_macos() { [[ $OSTYPE == darwin* ]] }
# The distro package ships gitstatusd; the git clone would download it on
# first prompt. Only let antidote fetch p10k when no package is installed.
P10K_SYSTEM=/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
need_p10k() { is_linux && [[ ! -r $P10K_SYSTEM ]] }
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
if [[ ! -d ~/.antidote ]] && command -v git &>/dev/null; then
    git clone -q --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote
fi
if [[ -r ~/.antidote/antidote.zsh ]]; then
    source ~/.antidote/antidote.zsh
    antidote load ~/.config/zsh/.zsh_plugins.txt ~/.config/zsh/.zsh_plugins.zsh
fi

[[ -r $P10K_SYSTEM ]] && source $P10K_SYSTEM

# Tab accepts the autosuggestion when there is one, else completes.
_accept_or_complete() {
    if [[ -n "$POSTDISPLAY" ]]; then zle autosuggest-accept; else zle expand-or-complete; fi
}
zle -N _accept_or_complete
bindkey '^I' _accept_or_complete

# fzf. New releases ship their own zsh setup; older distro builds still
# install the two scripts under /usr/share.
if command -v fzf &>/dev/null; then
    source <(fzf --zsh 2>/dev/null)
    if ! (( $+functions[fzf-history-widget] )); then
        for _f in /usr/share/fzf/key-bindings.zsh /usr/share/fzf/completion.zsh \
                  /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/doc/fzf/examples/completion.zsh \
                  ~/.fzf.zsh; do
            [[ -f "$_f" ]] && source "$_f"
        done
        unset _f
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {}'"
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
fi

# thefuck without the slow eval of its --alias output.
if command -v thefuck &>/dev/null; then
    fuck() {
        TF_PYTHONIOENCODING=$PYTHONIOENCODING
        export TF_SHELL=zsh TF_ALIAS=fuck PYTHONIOENCODING=utf-8
        TF_SHELL_ALIASES=$(alias); export TF_SHELL_ALIASES
        TF_HISTORY="$(fc -ln -10)"; export TF_HISTORY
        TF_CMD=$(thefuck THEFUCK_ARGUMENT_PLACEHOLDER "$@") && eval "$TF_CMD"
        unset TF_HISTORY
        export PYTHONIOENCODING=$TF_PYTHONIOENCODING
        test -n "$TF_CMD" && print -s "$TF_CMD"
    }
    alias fk='fuck'
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
    alias cd='z'
    alias zi='z -i'
fi

# Ctrl-R goes to atuin. Up arrow stays plain zsh history.
if command -v atuin &>/dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# Aliases: editor, git, tmux, docker, build tools
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gm='git commit -m'
alias gp='git pull'
alias gpl='git pull'
alias gps='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -D'
alias gsw='git switch'
alias lg='lazygit'
alias t='tmux'
alias ta='tmux attach'
alias tl='tmux ls'
alias tk='tmux kill-session'
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps'
alias di='docker images'
alias dprune='docker system prune -f'
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
alias mdep='mvn dependency:analyze'
alias sbr='./mvnw spring-boot:run'
alias sbu='./mvnw spring-boot:run -Dspring-boot.run.profiles=local'
alias ni='npm install'
alias nid='npm install --save-dev'
alias ns='npm start'
alias nb='npm run build'
alias nd='npm run dev'
alias nr='npm run'
alias nu='npm update'
alias nclean='rm -rf node_modules package-lock.json && npm install'
alias testw='npm run test:watch'
alias cov='npm run test:coverage'
alias lint='npm run lint'
alias lintf='npm run lint:fix'
alias fmt='npm run format'
alias gr='./gradlew'
alias grb='./gradlew build'
alias grc='./gradlew clean'
alias grcb='./gradlew clean build'
alias grt='./gradlew test'
alias grr='./gradlew bootRun'

# Files and navigation
if command -v eza &>/dev/null; then
    alias ls='eza --icons=auto --group-directories-first'
    alias l='eza -la --icons=auto --group-directories-first'
    alias ll='eza -l --icons=auto --group-directories-first'
    alias la='eza -la --icons=auto --group-directories-first --sort=type'
    alias lt='eza --tree --icons=auto'
    alias tree='eza --tree --icons=auto'
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
command -v btop &>/dev/null && alias top='btop' && alias htop='btop'
command -v yazi &>/dev/null && alias y='yazi'
if command -v fastfetch &>/dev/null; then
    alias fetch='fastfetch'
elif command -v neofetch &>/dev/null; then
    alias fetch='neofetch'
fi
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias c='clear'
alias please='sudo'
alias fnd='ls -a | grep -i'
alias py='python'
alias o='opencode'
alias claudd='claude --dangerously-skip-permissions'
alias myip='curl -s ifconfig.me'
alias qrc='qrencode -t UTF8'
alias nvide='nohup neovide & disown'
alias pyvenv='chmod +x .venv/bin/activate && source .venv/bin/activate'
alias mkvenv='py -m venv .venv && chmod +x .venv/bin/activate && source .venv/bin/activate'
alias zshconf='nvim ~/.zshrc && source ~/.zshrc'
alias yt-480='yt-dlp -f "bestvideo[height=480][fps=30]+bestaudio/best[height=480][fps=30]" --cookies-from-browser firefox'
alias yt-720='yt-dlp -f "bestvideo[height=720][fps=60]+bestaudio/best[height=720][fps=60]" --cookies-from-browser firefox'
alias yt-1080='yt-dlp -f "bestvideo[height=1080][fps=60]+bestaudio/best[height=1080][fps=60]" --cookies-from-browser firefox'
alias yt-mp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --cookies-from-browser firefox'
if command -v nmcli &>/dev/null; then
    alias wifilist='nmcli device wifi list'
    alias wificonnect='nmcli device wifi connect --ask'
fi
if command -v systemctl &>/dev/null; then
    alias bt='sudo systemctl start bluetooth'
    alias systat='sudo systemctl status'
    alias systart='sudo systemctl restart'
fi
if command -v hyprctl &>/dev/null; then
    alias hypr-fix='export HYPRLAND_INSTANCE_SIGNATURE=$(\ls -t /run/user/1000/hypr | head -n1)'
    alias hyprconf='cd ~/.config/hypr && nvim ~/.config/hypr/hyprland.lua'
fi

# Project shortcuts, only when the dir exists. Paths come from .env.
[[ -d "$DOTFILES_DIR" ]] && alias dotfiles="cd $DOTFILES_DIR"
[[ -d "${PROJECTS_DIR:-$HOME/Desktop/personal}" ]] && alias personal="cd ${PROJECTS_DIR:-$HOME/Desktop/personal}"
[[ -d "${ORBIT_DIR:-$HOME/Desktop/orbit}" ]] && alias orbit="cd ${ORBIT_DIR:-$HOME/Desktop/orbit}"
[[ -n "$MOENMARIN_DIR" && -d "$MOENMARIN_DIR" ]] && alias moenmarin="cd $MOENMARIN_DIR"
[[ -n "$DATAING_DIR" && -d "$DATAING_DIR" ]] && alias dataing="cd $DATAING_DIR"

# Functions
gacp() { git add .; git commit -m "$*"; git push; }
mkcd() { mkdir -p "$1" && cd "$1"; }
ff() { find . -name "$1" 2>/dev/null; }
fstr() { grep -r "$1" . 2>/dev/null; }
backup() { cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"; }
serve() { python3 -m http.server "${1:-8000}"; }
branch() { git branch 2>/dev/null | grep '*' | sed 's/* //'; }
killport() { lsof -ti:"$1" | xargs kill -9 2>/dev/null || echo "No process on port $1"; }
conv() {
    if [[ -z "$1" ]]; then echo "Usage: conv inputfile [outputfile]"; return 1; fi
    ffmpeg -i "$1" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "${2:-${1%.*}.mov}"
}
extract() {
    [[ -f "$1" ]] || { echo "'$1' is not a valid file"; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz)         tar xJf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.zip)            unzip "$1" ;;
        *.rar)            unrar x "$1" ;;
        *.Z)              uncompress "$1" ;;
        *.7z)             7z x "$1" ;;
        *)                echo "'$1' cannot be extracted" ;;
    esac
}
# Clipboard: wl-copy on Wayland, pbcopy on macOS.
if command -v wl-copy &>/dev/null; then
    cpy() { if [[ -f "$1" ]]; then wl-copy < "$1"; else echo "$1" | wl-copy; fi; }
    xclip() { if [[ "$1" == "-out" || "$1" == "-o" ]]; then wl-paste; else wl-copy; fi; }
elif command -v pbcopy &>/dev/null; then
    cpy() { if [[ -f "$1" ]]; then pbcopy < "$1"; else echo "$1" | pbcopy; fi; }
fi
command -v zathura &>/dev/null && pdf() { zathura "$1" & disown; pkill "$TERMINAL_EMULATOR"; }
command -v thunar &>/dev/null && th() { thunar . & disown; pkill "$TERMINAL_EMULATOR"; }
if command -v cheat &>/dev/null; then
    cheatf() { cheat "$(cheat -l | cut -d' ' -f1 | fzf --preview 'cheat {}' --preview-window=right:70%)"; }
    alias cht='cheatf'
    alias cg='cheat git'
    alias cgz='cheat zsh'
    alias cgp='cheat python'
    alias cgd='cheat docker'
fi

# Keybindings
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[127;5u' backward-kill-word
bindkey '^[[127;3u' backward-kill-line

# Activate a project venv on cd.
chpwd() {
    [[ -d .venv ]] && source .venv/bin/activate
    [[ -d venv ]] && source venv/bin/activate
}

# Stow one package from whichever tree holds it.
stow-pkg() {
    [[ -n "$1" ]] || { echo "Usage: stow-pkg <package>"; return 1; }
    # ~/.claude is one symlink to the submodule, not a stow tree of per-file links
    if [[ "$1" == "claude-config" ]]; then ln -sfn "$DOTFILES_DIR/claude-config" ~/.claude; return; fi
    for _d in shared arch ubuntu macos; do
        [[ -d "$DOTFILES_DIR/$_d/stow/$1" ]] && stow -d "$DOTFILES_DIR/$_d/stow" -t ~ --no-folding -R "$1"
    done
    unset _d
}
unstow-pkg() {
    [[ -n "$1" ]] || { echo "Usage: unstow-pkg <package>"; return 1; }
    if [[ "$1" == "claude-config" ]]; then [[ -L ~/.claude ]] && rm ~/.claude; return; fi
    for _d in shared arch ubuntu macos; do
        [[ -d "$DOTFILES_DIR/$_d/stow/$1" ]] && stow -d "$DOTFILES_DIR/$_d/stow" -t ~ --no-folding -D "$1"
    done
    unset _d
}

# Prompt config for p10k (Linux). macOS runs starship from its own file.
is_linux && [[ -f ~/.config/zsh/.p10k.zsh ]] && source ~/.config/zsh/.p10k.zsh

[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"
[[ -f ~/.zshenv.secrets ]] && source ~/.zshenv.secrets

# SDKMAN only until mise takes over Java. It wants to be last.
if ! command -v mise &>/dev/null; then
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
