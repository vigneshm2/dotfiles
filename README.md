# dotfiles

Setup for a new Ubuntu (apt) or macOS (brew) machine. Configs are symlinked into
`$HOME` with GNU stow.

## New machine

    git clone <repo-url> ~/dotfiles
    cd ~/dotfiles && ./install.sh

`install.sh` is idempotent. It installs packages (zsh, tmux, stow, uv, rust, zoxide,
pueue), Oh My Zsh with the you-should-use plugin, the pure prompt and tmux plugins,
then stows the configs and sets zsh as the default shell. Existing config files are
moved to `*.bak` first. Restart the shell afterwards.

## Layout

Each top-level directory is a stow package that mirrors `$HOME`:

- `zsh/`  - `.zshrc`, `.zsh_aliases`
- `tmux/` - `.tmux.conf`
- `bin/`  - personal scripts, on PATH via `~/dotfiles/bin` (not stowed)

Edit `~/.zshrc` etc. as usual. They are symlinks, so the change lands in this repo.

## Machine-specific config

Copy `zshrc.local.example` to `~/.zshrc.local` and edit it. It is gitignored,
so proxies, certs and per-machine aliases stay out of the repo.

## Adding things

- New config: create `<pkg>/<path mirroring $HOME>`, add `<pkg>` to `PACKAGES` in
  `install.sh`, then run `stow -R <pkg>` from `~/dotfiles`.
- New script: drop it in `bin/` and `chmod +x`.

See `todo.txt` for planned work.
