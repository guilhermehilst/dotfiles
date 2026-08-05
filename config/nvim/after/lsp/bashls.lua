---@type vim.lsp.Config
return {
  settings = {
    bashIde = {
      -- Sem shellcheck o bashls praticamente não emite diagnostics; resolve via
      -- $PATH, que é onde o Homebrew instala.
      shellcheckPath = "shellcheck",
      shfmt = {
        -- Indenta os corpos de case, como nos script/* do repo.
        caseIndent = true,
        -- A largura do indent vem do tabSize que o Neovim envia no
        -- textDocument/formatting (shiftwidth = 2 em config/options.lua).
      },
    },
  },
}
