# Arch Zsh Configuration

# Enable Powerlevel10k instant prompt — must stay near top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Source per-machine .env if present (monitor layout, paths, prefs)
for _df in "$DOTFILES_DIR" "$HOME/dotfiles" "$HOME/Desktop/dotfiles" "$HOME/.dotfiles"; do
    if [[ -n "$_df" && -f "$_df/.env" ]]; then
        set -a; source "$_df/.env"; set +a
        export DOTFILES_DIR="$_df"
        break
    fi
done
unset _df

# ============================================
# PATH
# ============================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Deno
[[ -f "$HOME/.deno/env" ]] && source "$HOME/.deno/env"

# ============================================
# Shell setup
# ============================================
export ZSH="$HOME/.oh-my-zsh"
export TERMINAL_EMULATOR="ghostty"
export BROWSER=librewolf
export GH_CONFIG_DIR="$HOME/.config/gh"
export NVM_DIR=/usr/share/nvm
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"

ZSH_THEME="powerlevel10k"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"

plugins=(git)

autoload -Uz compinit && compinit -d ~/.config/zsh/.zcompdump

# ============================================
# Plugins (deferred for faster startup)
# ============================================
if [[ -f /usr/share/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh
elif [[ -f ~/.config/zsh/zsh-defer/zsh-defer.plugin.zsh ]]; then
    source ~/.config/zsh/zsh-defer/zsh-defer.plugin.zsh
fi

[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    zsh-defer source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

function _accept_or_complete() {
    if [[ -n "$POSTDISPLAY" ]]; then
        zle autosuggest-accept
    else
        zle expand-or-complete
    fi
}
zle -N _accept_or_complete
bindkey '^I' _accept_or_complete

# ============================================
# FZF
# ============================================
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

# ============================================
# Zoxide
# ============================================
eval "$(zoxide init zsh)"
alias cd='z'

# ============================================
# The Fuck
# ============================================
fuck() {
    TF_PYTHONIOENCODING=$PYTHONIOENCODING
    export TF_SHELL=zsh
    export TF_ALIAS=fuck
    TF_SHELL_ALIASES=$(alias)
    export TF_SHELL_ALIASES
    TF_HISTORY="$(fc -ln -10)"
    export TF_HISTORY
    export PYTHONIOENCODING=utf-8
    TF_CMD=$(thefuck THEFUCK_ARGUMENT_PLACEHOLDER "$@") && eval $TF_CMD
    unset TF_HISTORY
    export PYTHONIOENCODING=$TF_PYTHONIOENCODING
    test -n "$TF_CMD" && print -s $TF_CMD
}
alias fk='fuck'

# ============================================
# Arch-specific aliases
# ============================================
alias c='clear'
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias please='sudo'
alias py='python'
alias o='opencode'
alias claudd='claude --dangerously-skip-permissions'

alias nfch='neofetch'
alias fetch='fastfetch'
alias lss='eza --tree --icons --level=2'
alias lsss='eza --tree --icons --level=3'
alias lssss='eza --tree --icons --level=4'
alias tree='eza --tree --icons'
alias la='eza --long --header --icons --git --all --group-directories-first --sort=type'
alias cat='bat --paging=never'
alias fnd='ls -a | grep -i'

alias wifilist='nmcli device wifi list'
alias wificonnect='nmcli device wifi connect --ask'
alias performance='sudo cpupower frequency-set -g performance'
alias bt='sudo systemctl start bluetooth'
alias btui='bluetuith'
alias systat='sudo systemctl status'
alias systart='sudo systemctl restart'
alias ports='netstat -tulanp'
alias myip='curl -s ifconfig.me'
alias serialfix='sudo chmod +766 /dev/ttyACM0'
alias qrc='qrencode -t UTF8'
alias nvide='nohup neovide & disown'
alias pyvenv='chmod +x .venv/bin/activate && source .venv/bin/activate'
alias mkvenv='py -m venv .venv && chmod +x .venv/bin/activate && source .venv/bin/activate'
alias gpt='chatgpt.sh -cc'
alias hypr-fix='export HYPRLAND_INSTANCE_SIGNATURE=$(\ls -t /run/user/1000/hypr | head -n1)'
alias hyprconf='cd ~/.config/hypr && nvim ~/.config/hypr/hyprland.conf'
alias yt-480='yt-dlp -f "bestvideo[height=480][fps=30]+bestaudio/best[height=480][fps=30]" --cookies-from-browser firefox'
alias yt-720='yt-dlp -f "bestvideo[height=720][fps=60]+bestaudio/best[height=720][fps=60]" --cookies-from-browser firefox'
alias yt-1080='yt-dlp -f "bestvideo[height=1080][fps=60]+bestaudio/best[height=1080][fps=60]" --cookies-from-browser firefox'
alias yt-mp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --cookies-from-browser firefox'
alias cpufetch='cpufetch --style fancy --color 230,50,45:240,230,230:0,0,0:250,70,65:170,170,170'
alias zshconf='nvim ~/.zshrc +6 && source ~/.zshrc'
alias mdep='mvn dependency:analyze'
alias sbu='./mvnw spring-boot:run -Dspring-boot.run.profiles=local'
alias testw='npm run test:watch'
alias cov='npm run test:coverage'
alias lint='npm run lint'
alias lintf='npm run lint:fix'
alias fmt='npm run format'

# Project shortcuts (only defined when dir exists)
[[ -d "${DOTFILES_DIR:-$HOME/dotfiles}" ]] && alias dotfiles="cd ${DOTFILES_DIR:-$HOME/dotfiles}"
[[ -d "${PROJECTS_DIR:-$HOME/Desktop/personal}" ]] && alias personal="cd ${PROJECTS_DIR:-$HOME/Desktop/personal}"
[[ -d "${ORBIT_DIR:-$HOME/Desktop/orbit}" ]] && alias orbit="cd ${ORBIT_DIR:-$HOME/Desktop/orbit}"
[[ -n "$MOENMARIN_DIR" && -d "$MOENMARIN_DIR" ]] && alias moenmarin="cd $MOENMARIN_DIR"
[[ -n "$DATAING_DIR" && -d "$DATAING_DIR" ]] && alias dataing="cd $DATAING_DIR"

# ============================================
# Host-specific config
# ============================================
case "$HOST" in
    arch*)
        alias update='sudo pacman -Syyu && paru && hyprpm update'
        alias refreshmirrors='rate-mirrors arch | sudo tee /etc/pacman.d/mirrorlist'
        alias pkgfnd='pacman -Q | grep'

        case "$HOST" in
            archflipper)
                [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
                [ -f ~/.fzf-git.sh ] && source ~/.fzf-git.sh
                ;;
        esac
        ;;
    debian*|i5server)
        alias inst='sudo apt install'
        alias update='sudo apt update && sudo apt upgrade'
        ;;
    *)
        alias update="echo 'no system-specific update command defined'"
        ;;
esac

# ============================================
# Powerlevel10k
# ============================================
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ -f /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]] && \
    source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# ============================================
# Arch-specific functions
# ============================================
dnsfix() {
    sudo tee /etc/resolv.conf > /dev/null <<'EOF'
# Generated by NetworkManager
search home
nameserver 1.1.1.1
options edns0 trust-ad
EOF
}

conv() {
    if [ -z "$1" ]; then echo "Usage: conv inputfile [outputfile]"; return 1; fi
    local input="$1"
    local output="${2:-${input%.*}.mov}"
    ffmpeg -i "$input" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "$output"
}

cpy() {
    if [[ -f "$1" ]]; then cat "$1" | wl-copy; else echo "$1" | wl-copy; fi
}

xclip() {
    if [[ "$1" == "-out" || "$1" == "-o" ]]; then wl-paste
    else wl-copy; fi
}

pdf() { zathura "$1" & disown && pkill $TERMINAL_EMULATOR }
th() { thunar . & disown && pkill $TERMINAL_EMULATOR }
sunshine_start() { export DISPLAY:=1; sunshine }

cheatf() {
    cheat $(cheat -l | cut -d' ' -f1 | fzf --preview 'cheat {}' --preview-window=right:70%)
}
alias cht='cheatf'
alias cg='cheat git'
alias cgz='cheat zsh'
alias cgp='cheat python'
alias cgd='cheat docker'

# ============================================
# OpenClaw completions
# ============================================
[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

# ============================================
# Shared config + secrets
# ============================================
[ -f ~/.config/zsh/shared.zsh ] && source ~/.config/zsh/shared.zsh
[ -f ~/.zshenv.secrets ] && source ~/.zshenv.secrets

# SDKMAN — must stay at end
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
