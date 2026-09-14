# macOS zsh config. Everything shared lives in ~/.config/zsh/shared.zsh.

# Homebrew first so the shared PATH lines land ahead of it.
[[ -d /opt/homebrew/bin ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

source ~/.config/zsh/shared.zsh

export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || /usr/libexec/java_home)
export PATH="$JAVA_HOME/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

command -v starship &>/dev/null && eval "$(starship init zsh)"

alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias today='date +%Y-%m-%d'
alias week='date +%V'
alias timestamp='date +%s'
alias ip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias ping='ping -c 5'
alias ports='lsof -i -P | grep LISTEN'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias finder='open -a Finder'
alias hide='chflags hidden'
alias unhide='chflags nohidden'
alias cleanup='find . -type f -name "*.DS_Store" -ls -delete'
alias emptytrash='sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl'
alias update='brew update && brew upgrade && brew cleanup'
alias ql='qlmanage -p 2>/dev/null'
alias showhidden='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidehidden='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias sshkey='cat ~/.ssh/id_ed25519.pub | pbcopy'
alias sshconf='nvim ~/.ssh/config'
alias sshhosts='cat ~/.ssh/config | grep "Host " | sed "s/Host //"'
alias weather='curl wttr.in'
alias moon='curl wttr.in/moon'
alias starshipconf='nvim ~/.config/starship.toml'

if [[ -o interactive ]]; then
    if command -v fastfetch &>/dev/null; then fastfetch
    elif command -v neofetch &>/dev/null; then neofetch
    else echo "Hei, $(whoami)!"; echo "System: $(sw_vers -productName) $(sw_vers -productVersion)"
    fi
fi
