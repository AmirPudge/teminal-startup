# Перенесено из ~/.zshrc

# PATH (в zsh: export PATH="$HOME/.local/bin:$PATH")
fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/go/bin

set -gx TERM xterm-256color

if status is-interactive
    set -g fish_greeting

    # z / zi — прыжки по каталогам (zoxide)
    zoxide init fish | source

    # f / fuck — исправить последнюю команду (pay-respects)
    pay-respects fish --alias fuck | source
    alias f fuck

    # fzf: Ctrl+R история, Ctrl+Alt+F файлы, Ctrl+Alt+L git log, Ctrl+Alt+S git status
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
end

# Промпт
if status is-interactive
    starship init fish | source
end
