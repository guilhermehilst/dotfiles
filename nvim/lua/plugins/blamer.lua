return {
  "APZelos/blamer.nvim",
  lazy = true,
  keys = {
    {"<leader>gb", ":BlamerToggle<CR>", desc = "Toggle Git Blame"}
  },
  init = function()
    vim.g.blamer_enabled = false
    vim.g.blamer_show_in_visual_modes = true
    vim.g.blamer_show_in_insert_modes = false
    vim.g.blamer_delay = 100
    vim.g.blamer_template = '|<commit-short>| <author>, <committer-time> • <summary>'
  end,
}
