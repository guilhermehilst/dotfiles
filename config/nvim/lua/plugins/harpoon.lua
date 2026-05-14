if true then return {} end

return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",

    opts = {
      file_with_line = {
        create_list_item = function()
          -- local file_path = vim.fn.expand("%:p") -- Absolute file path
          local file_path = vim.fn.expand("%")
          local line_number = vim.fn.line(".")

          if file_path == "" then
            return nil
          end

          return {
            value = file_path .. ":" .. line_number,
            context = { file_path = file_path, line_number = line_number },
          }
        end,
      },
    },

    config = function(_, opts)
      local harpoon = require('harpoon')
      harpoon:setup(opts)

      -- basic telescope configuration
      local conf = require("telescope.config").values

      local function toggle_telescope(harpoon_files)
        local file_paths = {}

        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        local make_finder = function()
          local paths = {}
          for _, item in ipairs(harpoon_files.items) do
            table.insert(paths, item.value)
          end

          return require('telescope.finders').new_table { results = paths }
        end

        require("telescope.pickers").new({}, {
          prompt_title = "Harpoon",
          -- layout_config = {
          --   width = 0.5, -- 50% width
          --   height = 0.4, -- 40% height
          -- },
          finder = require("telescope.finders").new_table({
            results = file_paths,
            entry_maker = function(entry)
              local file, line = entry:match("([^:]+):(%d+)")

              return {
                value = entry,
                display = entry,
                ordinal = entry,
                filename = file,
                lnum = tonumber(line),

                path = file,
              }
            end
          }),

          previewer = require("telescope.previewers").new_buffer_previewer({
            define_preview = function(self, entry)
              local conf = require("telescope.config").values

              conf.buffer_previewer_maker(
                entry.filename,
                self.state.bufnr,
                { bufname = self.state.bufname }
              )

              if entry.lnum then
                vim.defer_fn(function()
                  if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
                    return
                  end

                  if not vim.api.nvim_win_is_valid(self.state.winid) then
                    return
                  end

                  -- ativar numeros de linha no preview
                  vim.wo[self.state.winid].number = true

                  local line_count = vim.api.nvim_buf_line_count(self.state.bufnr)
                  local target = math.min(entry.lnum, line_count)

                  pcall(vim.api.nvim_win_set_cursor, self.state.winid, { target, 0 })

                  -- centraliza a linha
                  vim.api.nvim_win_call(self.state.winid, function()
                    vim.cmd("normal! zz")
                  end)

                  -- highlight na linha inteira
                  local ns = vim.api.nvim_create_namespace("harpoon_preview")
                  vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns, 0, -1)
                  vim.api.nvim_buf_set_extmark(self.state.bufnr, ns, target - 1, 0, {
                    line_hl_group = "TelescopePreviewLine",
                  })
                end, 20)
              end
            end,
          });
          -- previewer = false,
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_buffer_number, map)
            -- Delete selected entry from the list
            map('i', '<C-d>', function()
              local state = require 'telescope.actions.state'
              local selected_entry = state.get_selected_entry()
              local current_picker = state.get_current_picker(prompt_buffer_number)
              print(selected_entry.index)
              harpoon:list("file_with_line"):remove_at(selected_entry.index)
              current_picker:refresh(make_finder())
            end)
            return true
          end,
        }):find()
      end

      vim.keymap.set("n", "<leader>ha", function() harpoon:list("file_with_line"):add() end, { desc = "Add to Harpoon"})
      vim.keymap.set("n", "<leader>hs", function() toggle_telescope(harpoon:list("file_with_line")) end, { desc = "Open Harpoon Window" })
      vim.keymap.set("n", "<leader>hc", function() harpoon:list("file_with_line"):clear() end, { desc = "Clear Harpoon List"})
      -- vim.keymap.set("n", "<leader>hs", function() harpoon.ui:toggle_quick_menu(harpoon:list("file_with_line")) end, { desc = "Open harpoon window" })
    end
}
