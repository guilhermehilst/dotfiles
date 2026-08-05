---@type vim.lsp.Config
return {
  settings = {
    yaml = {
      -- Desliga o schemaStore nativo do yamlls para o catálogo vir de uma única
      -- fonte, a mesma que o jsonls usa (evita schema duplicado/divergente).
      schemaStore = {
        enable = false,
        url = "",
      },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
}
