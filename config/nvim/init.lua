-- bootstrap lazy.nvim
require("config.options")
require("config.keymaps")
require("config.lazy")
-- Depois do lazy: vim.lsp.enable() resolve as configs na hora (lê lsp/*.lua do
-- runtimepath), então os defaults do nvim-lspconfig só existem se o plugin já
-- estiver no rtp.
require("config.lsp")
