local keymap = vim.keymap -- for conciseness
local cmd = vim.cmd -- for conciseness

-- "CTRL + \"   ---> Toggle Neotree
keymap.set("n", "<C-\\>", "<Cmd>Neotree toggle<CR>")

-- "CTRL + t"   ---> New tab
keymap.set("n", "<C-t>", "<Cmd>tabnew<CR>")

-- alias tc to tabclose
cmd.cabbrev("tc", "tabclose")

-- Copy file path
keymap.set("n", "<leader>fp", "<Cmd>let @+ = expand('%')<CR>", { desc = "Copy file path" })

keymap.set("n", "<leader>fn", "<Cmd>let @+ = expand('%:t')<CR>", { desc = "Copy file name" })


-- comment line and block // space+c+space
keymap.set("n", "<leader>c<leader>", ":normal gcc<CR><DOWN>", { desc = "Toggle comment line" })
-- <Esc> - exists visual mode.
-- :normal executes keystrokes in normal mode.
-- gv - restores selection.
-- gc - toggles comment
-- <CR> sends the command
keymap.set("v", "<leader>c<leader>", "<Esc>:normal gvgc<CR>", { desc = "Toggle comment block" })
