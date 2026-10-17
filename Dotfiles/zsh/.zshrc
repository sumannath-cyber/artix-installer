# ~/.zshrc

export EDITOR=nano
export VISUAL=nano

autoload -Uz compinit
compinit

PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
