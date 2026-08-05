---@type vim.lsp.Config
return {
  settings = {
    json = {
      -- O jsonls não tem catálogo próprio: sem isso só valida o que declara
      -- "$schema" inline (como config/nvim/.luarc.json faz).
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
