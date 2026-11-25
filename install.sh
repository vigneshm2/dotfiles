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
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x $b ]] && { eval "$("$b" shellenv)"; break; }
  done
  brew install zsh tmux stow git curl uv rust zoxide pueue zsh-patina
else
  export PATH="$HOME/.local/bin:$PATH"
  # Skip apt's zsh (5.8.1 on Ubuntu 22.04) if one is already on PATH, e.g. a source build in ~/.local
  apt_pkgs=(tmux stow git curl build-essential cmake g++)
  have zsh || apt_pkgs+=(zsh)
  sudo apt-get update
  sudo apt-get install -y "${apt_pkgs[@]}"
  have uv || curl -LsSf https://astral.sh/uv/install.sh | sh
  # Rust toolchain (rustup), then cargo-built tools (zoxide, pueue)
  have cargo || curl -fsSL https://sh.rustup.rs | sh -s -- -y
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
  have zoxide || cargo install --locked zoxide
  have pueue  || cargo install --locked pueue pueued
  have zsh-patina || cargo install --locked zsh-patina
fi

# --- 2. Oh My Zsh, plugins, pure prompt, TPM
log "Frameworks"
if [[ ! -d $HOME/.oh-my-zsh ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/you-should-use"
clone https://github.com/michel-kraemer/zsh-patina "$ZSH_CUSTOM/plugins/zsh-patina"
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
# TPM reads TMUX_PLUGIN_MANAGER_PATH from the tmux server environment. A server that
# was already running (or one that didn't load ~/.tmux.conf) won't have it, so set it.
tmux has-session 2>/dev/null || tmux new-session -d -s dotfiles-install
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
"$HOME/.tmux/plugins/tpm/bin/install_plugins"
# tmux-mem-cpu-load is C++ and must be compiled (needs cmake + g++)
mem="$HOME/.tmux/plugins/tmux-mem-cpu-load"
if [[ -d $mem && ! -x $mem/tmux-mem-cpu-load ]]; then
  (cd "$mem" && cmake . && make)
fi
tmux kill-session -t dotfiles-install 2>/dev/null || true

# --- 5. Default shell
zsh_path="$(command -v zsh)"
if [[ ${SHELL:-} != "$zsh_path" ]]; then
  log "Setting default shell to $zsh_path"
  grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$zsh_path" "$USER"
fi

# --- 6. zsh-patina self-check (informational only; never fails the install)
if have zsh-patina; then
  log "zsh-patina check"
  ZSH_PATINA_CONFIG_PATH="$DOTFILES_DIR/zsh/patina.toml" zsh-patina check || \
    echo "    zsh-patina reported problems (see above). If it is the zsh version (needs >= 5.9), build a newer zsh into ~/.local, or ignore this and keep your current zsh."
fi

log "Done. For machine-specific config , run for e.g.:"
echo "    cp $DOTFILES_DIR/zshrc.local.example ~/.zshrc.local"
