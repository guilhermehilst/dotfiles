![logo](assets/dotfiles-logo.png)

# Dotfiles

Dotfiles pessoais de macOS

## Instalação

```bash
git clone https://github.com/guilhermehilst/dotfiles.git
cd dotfiles
./script/install
```

O `./script/install` precisa rodar a partir da raiz do repositório. Ele:

1. Instala as Command Line Tools do Xcode (se faltarem).
2. Pergunta interativamente nome e e-mail do git e gera o `~/.gitconfig.local`.
3. Instala o Homebrew (se faltar) e roda `brew bundle` com o
   [Brewfile](config/homebrew/Brewfile).
4. Instala o oh-my-zsh e os plugins `zsh-autosuggestions` e
   `zsh-syntax-highlighting`.
5. Aplica os `defaults` do macOS (Finder, Dock, screenshots, teclado, etc.).
6. Cria os symlinks das configs para o `$HOME`.

Arquivos pré-existentes no destino são movidos para `~/.dotfiles-backup/` antes de
qualquer symlink ser criado. O install é idempotente — rodar de novo não quebra nada.

## O que está incluído

| Ferramenta | Config | Observações |
| --- | --- | --- |
| **Neovim** | `config/nvim` → `~/.config/nvim` | Setup em Lua baseado em lazy.nvim |
| **Ghostty** | `config/ghostty/config` | Terminal principal, tema Gruvbox Material |
| **Alacritty** | `config/alacritty/alacritty.toml` | Config presente, **ainda não fiada** no installer |
| **tmux** | `config/tmux/tmux.conf` → `~/.tmux.conf` | Prefixo `C-a`, copy-mode vi |
| **Vim** | `config/vim/vimrc` → `~/.vimrc` | Config base com vim-plug |
| **zsh** | `config/zsh/zshrc` → `~/.zshrc` | oh-my-zsh, tema `robbyrussell`, aliases com eza |
| **git** | `config/git/gitconfig` → `~/.gitconfig` | Config global + `gitignore_global` |
| **lazygit** | `config/lazygit/config.yml` | Comandos custom de fetch/prune |
| **GitHub CLI** | `config/gh/config.yml` | `gh` via HTTPS, alias `co` |
| **tig** | `config/tig/tigrc` → `~/.tigrc` | Cores e tema |
| **Karabiner** | `config/karabiner/karabiner.json` | Vi mode com `opt + jk` |
| **mise** | `config/mise/config.toml` → `~/.config/mise/` | Gerencia versões de ruby e go |
| **Claude Code** | `config/claude` → `~/.claude` | Commands e skills versionados |
| **Homebrew** | `config/homebrew/Brewfile` | Instalado via `brew bundle` (não é symlink) |

Todo o ferramental (neovim, ripgrep, eza, fzf, mise, RTK, nerd fonts, casks, etc.)
vem do [Brewfile](config/homebrew/Brewfile) via `brew bundle`.

## Overrides locais

Configuração específica de máquina (não versionada) fica em arquivos `*.local`, que
as configs versionadas carregam se existirem:

- `~/.local.zsh` — PATHs, `pyenv`/`goenv`/`nvm`, `libpq`, etc.
- `~/.gitconfig.local` — nome/e-mail do git (gerado pelo installer).

## Inspirações

- <https://dotfiles.github.io/inspiration/>
- <https://github.com/mathiasbynens/dotfiles>
- <https://github.com/holman/dotfiles>
- <https://github.com/hmarr/dotfiles>
- <https://github.com/amandeepmittal/dotfiles>
- <https://github.com/theherk/commons>
- <https://github.com/driesvints/dotfiles>
