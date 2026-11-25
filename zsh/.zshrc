export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$HOME/dotfiles/bin:$PATH
export EDITOR='vim'

# Rust (cargo, rustc, zoxide, pueue)
[[ -f $HOME/.cargo/env ]] && . "$HOME/.cargo/env"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # prompt is pure, loaded below
# Must be set before oh-my-zsh.sh loads the zsh-patina plugin
export ZSH_PATINA_CONFIG_PATH="${${(%):-%x}:A:h}/patina.toml"   # resolves the stow symlink back to the repo
zstyle ':omz:update' mode auto
ENABLE_CORRECTION="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"
# you-should-use is cloned by install.sh; the rest ship with oh-my-zsh
plugins=(
  git
  sudo
  extract
  you-should-use
  zsh-autosuggestions
  zoxide
  zsh-patina
)
source $ZSH/oh-my-zsh.sh

# Keep history per-tab (no live sharing); run `hr` to pull in other tabs' commands
unsetopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
alias hr='fc -R'
unalias gap 2>/dev/null
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases   # tracked: pueue, uvr

# Prompt: pure (cloned to ~/.zsh/pure by install.sh)
fpath+=("$HOME/.zsh/pure")
autoload -U promptinit; promptinit
prompt pure
zstyle ':prompt:pure:user' color green
zstyle ':prompt:pure:host' color green

# Optional tools: only load if present on this machine
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PYENV_ROOT="$HOME/.pyenv"
if [[ -d $PYENV_ROOT/bin ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - zsh)"
  eval "$(pyenv virtualenv-init -)"
fi

# Machine-specific config (docker aliases, CUDA, proxies, tokens). Untracked.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
