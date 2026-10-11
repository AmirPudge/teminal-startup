# config

Мой терминал на macOS: Ghostty + fish + starship.

## Установка

```sh
git clone https://github.com/AmirPudge/teminal-startup ~/config
~/config/install.sh
```

Скрипт:
- ставит Homebrew (если нет) и пакеты из `Brewfile`;
- ставит [pay-respects](https://github.com/iffse/pay-respects) в `~/.local/bin`;
- делает симлинки конфигов (старые файлы сохраняются как `.bak`);
- ставит плагины fish через fisher;
- делает fish оболочкой по умолчанию.

Конфиги подключены симлинками, поэтому правки сразу попадают в репозиторий — остаётся закоммитить.

## Что внутри

| Путь | Куда ставится |
|---|---|
| `ghostty/config.ghostty` | подключается из `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` |
| `fish/config.fish` | `~/.config/fish/config.fish` |
| `fish/fish_plugins` | `~/.config/fish/fish_plugins` |
| `fish/conf.d/00-zsh-import.fish` | `~/.config/fish/conf.d/00-zsh-import.fish` |
| `starship/starship.toml` | `~/.config/starship.toml` |

## Возможности

- `z <папка>` / `zi` — прыжки по каталогам (zoxide)
- `Ctrl+R` — поиск по истории, `Ctrl+Alt+F` — файлы, `Ctrl+Alt+L` — git log, `Ctrl+Alt+S` — git status (fzf.fish)
- `f` / `fuck` — исправить последнюю команду (pay-respects)
- git-сокращения из oh-my-zsh: `gst`, `gco`, `gp`… (plugin-git)
- автодополнение docker
- промпт starship с пресетом nerd-font-symbols
- шрифт JetBrainsMono Nerd Font Mono, цвета Alacritty по умолчанию

Плагины обновляются командой `fisher update`.

## Переезд с zsh

Ничего переписывать не нужно — fish сам подхватывает настройки zsh
(`fish/conf.d/00-zsh-import.fish`):

- **PATH и переменные** из `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.zlogin`;
- **алиасы** (кроме тех, что написаны на синтаксисе zsh, и глобальных `alias -g`);
- **менеджеры версий**: pyenv, rbenv, conda, mise, direnv подключаются автоматически,
  `nvm` и `sdk` работают через [bass](https://github.com/edc/bass).

zsh запускается только когда меняются его файлы, результат кэшируется
в `~/.cache/fish/zsh_import.fish`, поэтому fish стартует быстро.
Изменения в `.zshrc` подхватятся в новом окне.

Не переносятся функции zsh и скрипты, подключаемые через `source` —
их нужно переписать под fish в `config.fish`.

Отключить импорт: `set -U fish_zsh_import off`. Вернуться на zsh: `chsh -s /bin/zsh`.
