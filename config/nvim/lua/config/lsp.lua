vim.lsp.enable({
    "ruby-lsp",
    "gopls",
    "lua_ls",
    "bashls",
    "jsonls",
    "yamlls",
    "marksman"
})

vim.diagnostic.config({
    virtual_lines = true,
    -- virtual_text = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
    },
})

-- O Neovim 0.11+ já mapeia grn/gra/grr/gri/grt/K por padrão, mas não gd — o gd
-- nativo é uma busca textual de declaração local. Mapeia por buffer para não
-- perder esse comportamento onde não há LSP.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
        end

        if client:supports_method("textDocument/definition") then
            map("gd", vim.lsp.buf.definition, "Go to definition (LSP)")
        end

        -- Borda só aqui, em vez de opt.winborder global (ver config/options.lua),
        -- para não colocar borda nos floats de todos os plugins.
        if client:supports_method("textDocument/hover") then
            map("K", function()
                vim.lsp.buf.hover({ border = "single" })
            end, "Hover (LSP)")

            -- ESC fecha o hover, somando aos jeitos nativos (mover o cursor,
            -- entrar em insert, ou q com o float focado). O winid do float fica
            -- em b:lsp_floating_preview; o Neovim limpa essa var sozinho.
            map("<Esc>", function()
                local win = vim.b[args.buf].lsp_floating_preview
                if win and vim.api.nvim_win_is_valid(win) then
                    -- Mesma teardown do close_preview_window() interno: sem
                    -- remover o augroup sobra autocmd apontando pra janela morta.
                    pcall(vim.api.nvim_del_augroup_by_name, "nvim.preview_window_" .. win)
                    pcall(vim.api.nvim_win_close, win, true)
                    return
                end

                -- Sem hover aberto, repassa o ESC nativo.
                vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
            end, "Close LSP hover")
        end
    end,
})

-- Go: organiza imports (auto-import) + formata ao salvar.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function(args)
        local client = vim.lsp.get_clients({ bufnr = args.buf, name = "gopls" })[1]
        if not client then
            return
        end

        local enc = client.offset_encoding or "utf-16"
        local params = vim.lsp.util.make_range_params(0, enc)
        params.context = { only = { "source.organizeImports" } }

        local results = vim.lsp.buf_request_sync(args.buf, "textDocument/codeAction", params, 1000)
        for _, res in pairs(results or {}) do
            for _, action in pairs(res.result or {}) do
                if action.edit then
                    vim.lsp.util.apply_workspace_edit(action.edit, enc)
                end
            end
        end

        vim.lsp.buf.format({ bufnr = args.buf, async = false })
    end,
})

-- Extras

local function restart_lsp(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    for _, client in ipairs(clients) do
        vim.lsp.stop_client(client.id)
    end

    vim.defer_fn(function()
        vim.cmd('edit')
    end, 100)
end

vim.api.nvim_create_user_command('LspRestart', function()
    restart_lsp()
end, {})

local function lsp_status()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    if #clients == 0 then
        print("󰅚 No LSP clients attached")
        return
    end

    print("󰒋 LSP Status for buffer " .. bufnr .. ":")
    print("─────────────────────────────────")

    for i, client in ipairs(clients) do
        print(string.format("󰌘 Client %d: %s (ID: %d)", i, client.name, client.id))
        print("  Root: " .. (client.config.root_dir or "N/A"))
        print("  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))

        -- Check capabilities
        local caps = client.server_capabilities
        local features = {}
        if caps.completionProvider then table.insert(features, "completion") end
        if caps.hoverProvider then table.insert(features, "hover") end
        if caps.definitionProvider then table.insert(features, "definition") end
        if caps.referencesProvider then table.insert(features, "references") end
        if caps.renameProvider then table.insert(features, "rename") end
        if caps.codeActionProvider then table.insert(features, "code_action") end
        if caps.documentFormattingProvider then table.insert(features, "formatting") end

        print("  Features: " .. table.concat(features, ", "))
        print("")
    end
end

vim.api.nvim_create_user_command('LspStatus', lsp_status, { desc = "Show detailed LSP status" })

local function check_lsp_capabilities()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    if #clients == 0 then
        print("No LSP clients attached")
        return
    end

    for _, client in ipairs(clients) do
        print("Capabilities for " .. client.name .. ":")
        local caps = client.server_capabilities

        local capability_list = {
            { "Completion",                caps.completionProvider },
            { "Hover",                     caps.hoverProvider },
            { "Signature Help",            caps.signatureHelpProvider },
            { "Go to Definition",          caps.definitionProvider },
            { "Go to Declaration",         caps.declarationProvider },
            { "Go to Implementation",      caps.implementationProvider },
            { "Go to Type Definition",     caps.typeDefinitionProvider },
            { "Find References",           caps.referencesProvider },
            { "Document Highlight",        caps.documentHighlightProvider },
            { "Document Symbol",           caps.documentSymbolProvider },
            { "Workspace Symbol",          caps.workspaceSymbolProvider },
            { "Code Action",               caps.codeActionProvider },
            { "Code Lens",                 caps.codeLensProvider },
            { "Document Formatting",       caps.documentFormattingProvider },
            { "Document Range Formatting", caps.documentRangeFormattingProvider },
            { "Rename",                    caps.renameProvider },
            { "Folding Range",             caps.foldingRangeProvider },
            { "Selection Range",           caps.selectionRangeProvider },
        }

        for _, cap in ipairs(capability_list) do
            local status = cap[2] and "✓" or "✗"
            print(string.format("  %s %s", status, cap[1]))
        end
        print("")
    end
end

vim.api.nvim_create_user_command('LspCapabilities', check_lsp_capabilities, { desc = "Show LSP capabilities" })

local function lsp_diagnostics_info()
    local bufnr = vim.api.nvim_get_current_buf()
    local diagnostics = vim.diagnostic.get(bufnr)

    local counts = { ERROR = 0, WARN = 0, INFO = 0, HINT = 0 }

    for _, diagnostic in ipairs(diagnostics) do
        local severity = vim.diagnostic.severity[diagnostic.severity]
        counts[severity] = counts[severity] + 1
    end

    print("󰒡 Diagnostics for current buffer:")
    print("  Errors: " .. counts.ERROR)
    print("  Warnings: " .. counts.WARN)
    print("  Info: " .. counts.INFO)
    print("  Hints: " .. counts.HINT)
    print("  Total: " .. #diagnostics)
end

vim.api.nvim_create_user_command('LspDiagnostics', lsp_diagnostics_info, { desc = "Show LSP diagnostics count" })


local function lsp_info()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    print("═══════════════════════════════════")
    print("           LSP INFORMATION          ")
    print("═══════════════════════════════════")
    print("")

    -- Basic info
    print("󰈙 Language client log: " .. vim.lsp.log.get_filename())
    print("󰈔 Detected filetype: " .. vim.bo.filetype)
    print("󰈮 Buffer: " .. bufnr)
    print("󰈔 Root directory: " .. (vim.fn.getcwd() or "N/A"))
    print("")

    if #clients == 0 then
        print("󰅚 No LSP clients attached to buffer " .. bufnr)
        print("")
        print("Possible reasons:")
        print("  • No language server installed for " .. vim.bo.filetype)
        print("  • Language server not configured")
        print("  • Not in a project root directory")
        print("  • File type not recognized")
        return
    end

    print("󰒋 LSP clients attached to buffer " .. bufnr .. ":")
    print("─────────────────────────────────")

    for i, client in ipairs(clients) do
        print(string.format("󰌘 Client %d: %s", i, client.name))
        print("  ID: " .. client.id)
        print("  Root dir: " .. (client.config.root_dir or "Not set"))
        -- cmd pode ser uma função em vez de tabela: jsonls e yamlls usam a forma
        -- de função para preferir o binário local em node_modules/.bin.
        local cmd = client.config.cmd
        print("  Command: " .. (type(cmd) == "table" and table.concat(cmd, " ") or "<function>"))
        print("  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))

        -- Server status
        if client:is_stopped() then
            print("  Status: 󰅚 Stopped")
        else
            print("  Status: 󰄬 Running")
        end

        -- Workspace folders
        if client.workspace_folders and #client.workspace_folders > 0 then
            print("  Workspace folders:")
            for _, folder in ipairs(client.workspace_folders) do
                print("    • " .. folder.name)
            end
        end

        -- Attached buffers count
        local attached_buffers = {}
        for buf, _ in pairs(client.attached_buffers or {}) do
            table.insert(attached_buffers, buf)
        end
        print("  Attached buffers: " .. #attached_buffers)

        -- Key capabilities
        local caps = client.server_capabilities
        local key_features = {}
        if caps.completionProvider then table.insert(key_features, "completion") end
        if caps.hoverProvider then table.insert(key_features, "hover") end
        if caps.definitionProvider then table.insert(key_features, "definition") end
        if caps.documentFormattingProvider then table.insert(key_features, "formatting") end
        if caps.codeActionProvider then table.insert(key_features, "code_action") end

        if #key_features > 0 then
            print("  Key features: " .. table.concat(key_features, ", "))
        end

        print("")
    end

    -- Diagnostics summary
    local diagnostics = vim.diagnostic.get(bufnr)
    if #diagnostics > 0 then
        print("󰒡 Diagnostics Summary:")
        local counts = { ERROR = 0, WARN = 0, INFO = 0, HINT = 0 }

        for _, diagnostic in ipairs(diagnostics) do
            local severity = vim.diagnostic.severity[diagnostic.severity]
            counts[severity] = counts[severity] + 1
        end

        print("  󰅚 Errors: " .. counts.ERROR)
        print("  󰀪 Warnings: " .. counts.WARN)
        print("  󰋽 Info: " .. counts.INFO)
        print("  󰌶 Hints: " .. counts.HINT)
        print("  Total: " .. #diagnostics)
    else
        print("󰄬 No diagnostics")
    end

    print("")
    print("Use :LspLog to view detailed logs")
    print("Use :LspCapabilities for full capability list")
end

-- Create command
vim.api.nvim_create_user_command('LspInfo', lsp_info, { desc = "Show comprehensive LSP information" })
