# Подхватывает окружение из zsh: PATH, переменные и алиасы из ~/.zshrc и др.
# zsh запускается только когда эти файлы меняются, результат кэшируется.
# Отключить: set -U fish_zsh_import off

set -q __FISH_ZSH_IMPORT; and return # защита от рекурсии (exec fish в .zshrc)
test "$fish_zsh_import" = off; and return
command -q zsh; or return

function __zsh_import_build -a cache
    set -l tmp (mktemp -d)
    # Снимаем окружение и алиасы после загрузки всех файлов zsh
    env __FISH_ZSH_IMPORT=1 zsh -l -i -c "env -0 >$tmp/env; alias -L >$tmp/aliases" </dev/null >/dev/null 2>&1 &
    set -l pid $last_pid
    for i in (seq 150) # не дольше 15 секунд
        kill -0 $pid 2>/dev/null; or break
        sleep 0.1
    end
    kill $pid 2>/dev/null

    if not test -s $tmp/env
        rm -rf $tmp
        echo "zsh-import: не удалось прочитать окружение zsh" >&2
        return 1
    end

    set -l skip PWD OLDPWD SHLVL _ SHELL HOME USER LOGNAME TMPDIR TERM COLORTERM \
        TERM_PROGRAM TERM_PROGRAM_VERSION TERMINFO TERMINFO_DIRS LINES COLUMNS \
        ZSH ZDOTDIR PS1 PS2 PS3 PS4 PROMPT RPROMPT SSH_AUTH_SOCK __FISH_ZSH_IMPORT

    mkdir -p (path dirname $cache)
    begin
        echo "# Сгенерировано из zsh "(date "+%Y-%m-%d %H:%M")" — не редактировать"

        # Переменные: только те, что zsh добавил или изменил
        set -l zsh_path
        for line in (string split0 <$tmp/env)
            set -l kv (string split -m1 = -- $line)
            set -l name $kv[1]
            set -l value $kv[2]
            string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- $name; or continue
            contains -- $name $skip; and continue
            string match -qr '^(GHOSTTY|P9K|_P9K|POWERLEVEL9K|ITERM|LC_TERMINAL|XPC_|__CF|fish_|__fish)' -- $name; and continue
            if test $name = PATH
                set zsh_path (string split : -- $value)
                continue
            end
            set -q $name; and test "$$name" = "$value"; and continue
            echo "set -gx $name "(string escape -- $value)
        end

        # PATH: каталоги из zsh, которых нет в fish, добавляем в начало
        set -l extra
        for p in $zsh_path
            contains -- $p $PATH; or set -a extra $p
        end
        if set -q extra[1]
            echo "fish_add_path -gP "(string escape -- $extra)
        end

        # Алиасы: только обычные, без конфликтов с функциями и сокращениями fish.
        # Определяются на первом промпте, когда плагины уже загружены.
        echo "status is-interactive; or return"
        echo "function __zsh_import_aliases --on-event fish_prompt"
        echo "    functions -e __zsh_import_aliases"
        for line in (cat $tmp/aliases 2>/dev/null)
            set -l m (string match -r '^alias ([A-Za-z0-9_][A-Za-z0-9_.+-]*)=(.*)$' -- $line)
            or continue
            set -l name $m[2]
            set -l body $m[3]
            if string match -qr "^'.*'\$" -- $body
                set body (string sub -s 2 -e -1 -- $body | string replace -a "'\\''" "'")
            end
            string match -qr '^[0-9.]+$' -- $name; and continue # cd -N и ... из oh-my-zsh
            builtin -q $name; and continue
            test -f $__fish_config_dir/functions/$name.fish; and continue
            fish -n -c "$body" 2>/dev/null; or continue # синтаксис не для fish
            echo "    abbr -q $name; or function $name --wraps="(string escape -- $body)" --description 'alias из zsh'; $body \$argv; end"
        end
        echo end
    end >$cache

    rm -rf $tmp
end

set -l zdot $HOME
set -q ZDOTDIR; and set zdot $ZDOTDIR
set -l sources
for f in .zshenv .zprofile .zshrc .zlogin
    test -f $zdot/$f; and set -a sources $zdot/$f
end

if set -q sources[1]
    set -l cache_home $HOME/.cache
    set -q XDG_CACHE_HOME; and set cache_home $XDG_CACHE_HOME
    set -l cache $cache_home/fish/zsh_import.fish

    set -l stale (not test -f $cache; and echo 1)
    for f in $sources
        test $f -nt $cache; and set stale 1
    end
    test -n "$stale"; and __zsh_import_build $cache
    test -f $cache; and source $cache
end
functions -e __zsh_import_build

# Менеджеры версий, которым нужна интеграция с fish
if status is-interactive
    command -q direnv; and direnv hook fish | source
    command -q mise; and mise activate fish | source
    command -q pyenv; and pyenv init - fish | source
    command -q rbenv; and rbenv init - fish | source
    command -q conda; and conda shell.fish hook | source

    # nvm и sdkman написаны на bash — запускаем через bass
    not set -q NVM_DIR; and test -s $HOME/.nvm/nvm.sh; and set -gx NVM_DIR $HOME/.nvm
    if set -q NVM_DIR; and test -s $NVM_DIR/nvm.sh
        function nvm --description 'nvm через bass'
            bass source $NVM_DIR/nvm.sh --no-use ';' nvm $argv
        end
    end
    not set -q SDKMAN_DIR; and test -s $HOME/.sdkman/bin/sdkman-init.sh; and set -gx SDKMAN_DIR $HOME/.sdkman
    if set -q SDKMAN_DIR; and test -s $SDKMAN_DIR/bin/sdkman-init.sh
        function sdk --description 'sdkman через bass'
            bass source $SDKMAN_DIR/bin/sdkman-init.sh ';' sdk $argv
        end
    end
end
