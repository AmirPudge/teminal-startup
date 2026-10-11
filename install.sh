#!/usr/bin/env bash
# Установка конфигов Ghostty + fish + starship на macOS.
# Повторный запуск безопасен: уже стоящее пропускается.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAY_RESPECTS_VERSION="0.8.8"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# Создаёт симлинк, сохраняя существующий файл как .bak
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak"
    echo "    бэкап: $dst.bak"
  fi
  ln -s "$src" "$dst"
  echo "    $dst -> $src"
}

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Устанавливаю Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
BREW_PREFIX="$(brew --prefix)"

info "Пакеты из Brewfile"
brew bundle --file="$REPO/Brewfile"

# 2. pay-respects (нет в Homebrew, берём релиз с GitHub)
if ! command -v pay-respects >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/pay-respects" ]; then
  info "Устанавливаю pay-respects $PAY_RESPECTS_VERSION"
  case "$(uname -m)" in
    arm64) arch="aarch64" ;;
    *) arch="x86_64" ;;
  esac
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/pr.tar.zst" \
    "https://github.com/iffse/pay-respects/releases/download/v$PAY_RESPECTS_VERSION/pay-respects-$PAY_RESPECTS_VERSION-$arch-apple-darwin.tar.zst"
  tar -xf "$tmp/pr.tar.zst" -C "$tmp"
  mkdir -p "$HOME/.local/bin"
  # Модуль request-ai не ставим: он отправляет команды во внешний AI-сервис
  cp "$tmp/pay-respects" "$tmp/_pay-respects-module-100-runtime-rules" "$HOME/.local/bin/"
  rm -rf "$tmp"
fi

# 3. Конфиги
info "Симлинки конфигов"
link "$REPO/fish/config.fish" "$HOME/.config/fish/config.fish"
link "$REPO/fish/fish_plugins" "$HOME/.config/fish/fish_plugins"
link "$REPO/fish/conf.d/00-zsh-import.fish" "$HOME/.config/fish/conf.d/00-zsh-import.fish"
link "$REPO/starship/starship.toml" "$HOME/.config/starship.toml"

# Ghostty: локальный файл подключает общий конфиг из репо и задаёт путь к fish
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_DIR"
if [ -e "$GHOSTTY_DIR/config.ghostty" ] && ! grep -q "$REPO/ghostty/config.ghostty" "$GHOSTTY_DIR/config.ghostty"; then
  mv "$GHOSTTY_DIR/config.ghostty" "$GHOSTTY_DIR/config.ghostty.bak"
  echo "    бэкап: $GHOSTTY_DIR/config.ghostty.bak"
fi
cat > "$GHOSTTY_DIR/config.ghostty" <<EOF
# Создано $REPO/install.sh — общие настройки в репозитории
config-file = $REPO/ghostty/config.ghostty
command = $BREW_PREFIX/bin/fish --login --interactive
EOF
echo "    $GHOSTTY_DIR/config.ghostty"

touch "$HOME/.hushlogin"

# 4. Плагины fish
info "Плагины fish (fisher)"
fish -c '
  if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
  end
  fisher update
' </dev/null

if command -v docker >/dev/null 2>&1; then
  docker completion fish > "$HOME/.config/fish/completions/docker.fish"
fi

# 5. fish как оболочка по умолчанию
FISH="$BREW_PREFIX/bin/fish"
if [ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" != "$FISH" ]; then
  if [ -t 0 ]; then
    info "Делаю fish оболочкой по умолчанию (нужен пароль)"
    grep -qx "$FISH" /etc/shells || echo "$FISH" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$FISH"
  else
    info "Чтобы сделать fish оболочкой по умолчанию:"
    echo "    echo $FISH | sudo tee -a /etc/shells && chsh -s $FISH"
  fi
fi

info "Готово. Открой новое окно Ghostty."
