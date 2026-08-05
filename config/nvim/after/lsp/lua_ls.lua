---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      runtime = {
        -- Neovim roda LuaJIT, não Lua 5.x padrão.
        version = "LuaJIT",
        -- Resolve require("config.options") do mesmo jeito que o Neovim.
        path = { "lua/?.lua", "lua/?/init.lua" },
      },
      workspace = {
        -- Evita o prompt "configurar ambiente como luassert?".
        checkThirdParty = false,
        library = {
          -- Tipos da API do Neovim (vim.api, vim.opt, vim.lsp...).
          vim.env.VIMRUNTIME,
          -- Tipos do luv, usados em vim.uv (ver lua/config/lazy.lua).
          "${3rd}/luv/library",
        },
      },
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
}
