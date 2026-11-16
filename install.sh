#!/usr/bin/env bash
# Bootstrap a macOS / Ubuntu machine from this repo. Idempotent.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh tmux)
have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
clone() { [[ -d $2 ]] || git clone --depth=1 "$1" "$2"; }   # clone <url> <dir>

# --- 1. Packages
log "Packages"
if [[ $(uname -s) == Darwin ]]; then
  have brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$( (/opt/homebrew/bin/brew || /usr/local/bin/brew) shellenv 2>/dev/null)" || true
  brew install zsh tmux stow git curl uv
else
  sudo apt-get update
  sudo apt-get install -y zsh tmux stow git curl
  export PATH="$HOME/.local/bin:$PATH"
  have uv || curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# --- 2. Oh My Zsh, pure prompt, TPM
log "Frameworks"
if [[ ! -d $HOME/.oh-my-zsh ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# --- 3. Symlink configs (existing regular files are moved to *.bak)
log "Stow"
for pkg in "${PACKAGES[@]}"; do
  while IFS= read -r -d '' f; do
    t="$HOME/${f#"$DOTFILES_DIR/$pkg/"}"
    [[ -f $t && ! -L $t ]] && mv -v "$t" "$t.bak"
  done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
done
stow -d "$DOTFILES_DIR" -t "$HOME" -R "${PACKAGES[@]}"

# --- 4. TPM plugins (resurrect, continuum, menus, mem-cpu-load)
log "Tmux plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

# --- 5. Default shell
zsh_path="$(command -v zsh)"
if [[ ${SHELL:-} != "$zsh_path" ]]; then
  log "Setting default shell to $zsh_path"
  grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$zsh_path" "$USER"
fi

log "Done. Put machine-specific config in ~/.zshrc.local (see zsh/.zshrc.local.example), then restart your shell."
