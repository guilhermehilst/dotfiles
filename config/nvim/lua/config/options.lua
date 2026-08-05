-- Set leader to space " "
--
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- Disable LazyVim auto format
vim.g.autoformat = false

-- opt.autowrite = true -- Enable auto write

-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically. Requires Neovim >= 0.10.0
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard

-- File management
opt.backup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
opt.confirm = true -- Confirm to save changes before exiting modified buffer

-- Text layout
opt.tabstop = 2 -- Number of spaces tabs count for
opt.shiftwidth = 2 -- Size of an indent
opt.softtabstop = 2
opt.expandtab = true
opt.wrap = false -- Disable line wrap
opt.linebreak = true -- Wrap lines at convenient points
opt.smartindent = true -- Insert indents automatically
opt.autoindent = true -- Keep identation from previous line
opt.shiftround = true -- Round indent
opt.list = true -- Sets how neovim will display certain whitespace characters in the editor.
opt.listchars = { -- Sets how neovim will display certain whitespace characters in the editor.
  trail = "•",
  nbsp = "␣",
  tab = "» "
}
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.inccommand = "nosplit" -- preview incremental substitute

-- UI
opt.laststatus = 3 -- global statusline
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
opt.conceallevel = 0
opt.cursorline = false -- Disable highlighting of the current line
opt.number = true
opt.relativenumber = false
opt.hlsearch = true
opt.termguicolors = true -- True color support
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.scrolloff = 4 -- Lines of context
opt.sidescrolloff = 8 -- Columns of context
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.winbar = ''
-- winborder é global: qualquer float que não passe border explícito herda dele
-- (blink.cmp, which-key, neo-tree...). A borda do hover do LSP é aplicada
-- pontualmente no mapeamento de K em lua/config/lsp.lua.
-- opt.winborder = 'single'
opt.mouse = "a" -- Enable mouse mode
-- opt.breakindent = true
opt.completeopt = "menu,menuone,noselect"
opt.spelloptions = "camel"
opt.showmode = false -- Dont show mode, since it's already in the status line
opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]
opt.winminwidth = 5 -- Minimum window width
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode

-- Configure how new splits should be opened
opt.splitright = true -- Put new windows right of current
opt.splitbelow = true -- Put new windows below current

-- Search
opt.ignorecase = true
opt.smartcase = true -- Don't ignore case with capitals

opt.foldlevel = 99
-- opt.formatexpr = "v:lua.require'lazyvim.util'.format.formatexpr()"
-- opt.formatoptions = "jcroqlnt" -- tcqj
-- opt.grepformat = "%f:%l:%c:%m"
-- opt.grepprg = "rg --vimgrep"
opt.jumpoptions = "view"
opt.pumblend = 10 -- Popup blend
-- opt.pumheight = 10 -- Maximum number of entries in a popup
-- opt.ruler = false -- Disable the default ruler
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
-- opt.shortmess:append({ W = true, I = true, c = true, C = true })
-- opt.spelllang = { "en" }
-- opt.splitkeep = "screen"
-- opt.wildmode = "longest:full,full" -- Command-line completion mode

-- Fix markdown indentation settings
-- vim.g.markdown_recommended_style = 0
