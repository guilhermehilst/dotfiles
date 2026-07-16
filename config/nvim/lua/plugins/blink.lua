return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "enter" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      menu = { auto_show = false },
      documentation = { auto_show = false, auto_show_delay_ms = 200 },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    signature = { enabled = true },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
  config = function(_, opts)
    require("blink.cmp").setup(opts)

    -- Anexa as capabilities do blink a todos os servers (vim.lsp.config nativo).
    -- Roda durante o lazy.setup, antes de qualquer LSP anexar a um buffer.
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })
  end,
}
