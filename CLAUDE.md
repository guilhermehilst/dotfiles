# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal macOS dotfiles, successor to the older [laptop](https://github.com/guilhermehilst/laptop) repo.

## Common commands

- `./script/install` — full install: sets up git config and symlinks tracked dotfiles into `$HOME`. Must run from the repo root (the entrypoint does `export DOTFILES_ROOT=$(pwd -P)`).
- No build, lint, or test commands exist in this repo.

`script/link_dotfiles` and `script/setup_git` are not standalone executables — they're sourced by `script/install` and depend on `DOTFILES_ROOT`, `SCRIPT_PATH`, and the helpers in [script/helpers/utils](script/helpers/utils) being loaded first.

## Architecture: what actually gets installed

[script/install](script/install) is the entrypoint. It sources, in order: [script/helpers/utils](script/helpers/utils) (logging + `link_dotfile`/`move_to_backup_dir` helpers), [script/xcode_select](script/xcode_select), [script/setup_git](script/setup_git), [script/homebrew](script/homebrew), [script/oh_my_zsh](script/oh_my_zsh), [script/set_macos_defaults](script/set_macos_defaults), then [script/link_dotfiles](script/link_dotfiles).

`link_dotfile <name> <source> <dest>` symlinks `$DOTFILES_ROOT/<source>` → `$HOME/<dest>`. If the destination already exists and isn't already the correct symlink, it's moved to `~/.dotfiles-backup/<dest>` first.

Currently-active symlinks (defined in [script/link_dotfiles](script/link_dotfiles) and [script/setup_git](script/setup_git)):

- `config/nvim` → `~/.config/nvim`
- `config/ghostty/config` → `~/.config/ghostty/config`
- `config/lazygit/config.yml` → `~/.config/lazygit/config.yml`
- `config/claude` → `~/.claude`
- `config/git/gitconfig` → `~/.gitconfig`
- `config/git/gitignore_global` → `~/.gitignore_global`
- `config/zsh/zshrc` → `~/.zshrc`

Other `config/*` directories (`alacritty`, `tmux`, `vim`, `gh`, `tig`, `karabiner`) are scaffolded but **not** wired into the installer. Adding a new config means adding the files AND a corresponding `link_dotfile` call.

## Shell / zsh setup

[script/oh_my_zsh](script/oh_my_zsh) installs oh-my-zsh non-destructively (`KEEP_ZSHRC=yes RUNZSH=no CHSH=no`, so it never touches our `.zshrc` or changes the default shell), then git-clones the `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins into `$ZSH_CUSTOM/plugins`. Both steps are idempotent (guarded by directory checks).

The committed `config/zsh/zshrc` is intentionally minimal (oh-my-zsh bootstrap + essential aliases). Machine- or tool-specific setup (pyenv, goenv, nvm, libpq, etc.) belongs in `~/.local.zsh`, which the committed `.zshrc` sources if present — the same local-override pattern as `~/.gitconfig.local`. Don't add machine-specific paths to the tracked `zshrc`.

## Git setup quirk

[script/setup_git](script/setup_git) interactively prompts for name/email and renders `config/git/gitconfig_local` (which contains literal `AUTHORNAME`/`AUTHOREMAIL` placeholders) into `~/.gitconfig.local` via `sed`. The committed `gitconfig_local` is a template, not a working config — don't "fix" the placeholders.

## Claude Code config layout

`config/claude/` is symlinked to `~/.claude/` as a whole, but [.gitignore](.gitignore) tracks only `commands/`, `skills/`, and `agents/` under it. Everything else (sessions, projects, todos, telemetry, history, plugins, etc.) is machine-local state and intentionally ignored.

When adding a Claude command or skill, place it in `config/claude/commands/<name>.md` or `config/claude/skills/<skill-name>/SKILL.md` and it'll be tracked automatically.

## Conventions

- Commit messages follow Conventional Commits in **Portuguese (BR)**. See [config/claude/commands/commit.md](config/claude/commands/commit.md) for the exact rules: imperative verbs (`adiciona`, not `adicionado`), description ≤50 chars including `tipo(escopo):`, no Claude/AI attribution.
- Claude commands and skills in this repo are authored in Portuguese (BR).
