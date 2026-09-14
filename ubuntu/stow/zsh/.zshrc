# Ubuntu zsh config. Everything shared lives in ~/.config/zsh/shared.zsh.

# p10k instant prompt, must stay at the top.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.config/zsh/shared.zsh

alias update='sudo apt update && sudo apt upgrade -y'
alias inst='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias autoremove='sudo apt autoremove'
alias pkgfnd='dpkg -l | grep'
alias py='python3'
alias lsblk='lsblk --output NAME,SIZE,TYPE,MOUNTPOINT,MODEL'
alias rofi-launch='rofi -show drun'
alias rofi-run='rofi -show run'
alias rofi-window='rofi -show window'
alias lock='swaylock'
alias logout-menu='wlogout'

[[ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
