-- bootstrap lazy.nvim
require("config.options")
require("config.keymaps")
require("config.lazy")
-- Depois do lazy: vim.lsp.enable() resolve as configs na hora (lê lsp/*.lua do
-- runtimepath), então os defaults do nvim-lspconfig e o require("schemastore")
-- dos after/lsp/ só existem se os plugins já estiverem no rtp.
require("config.lsp")
