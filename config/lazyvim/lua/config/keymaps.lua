-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- "CTRL + \"   ---> Toggle Neotree
vim.keymap.set("n", "<C-\\>", "<Cmd>Neotree toggle<CR>")

-- "CTRL + t"   ---> New tab
vim.keymap.set("n", "<C-t>", "<Cmd>tabnew<CR>")

-- alias tc to tabclose
vim.cmd.cabbrev("tc", "tabclose")

-- Copy file path
vim.keymap.set("n", "<leader>fp", "<Cmd>let @+ = expand('%')<CR>", { desc = "Copy file path" })
