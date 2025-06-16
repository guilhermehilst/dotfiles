return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files Telescope" },
      { "<C-p>", "<cmd>lua require('telescope.builtin').find_files()<CR>", desc = "Find Files Telescope" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep Files Telescope" },
    },
    opts = {
      defaults = {
        mappings = {
          i = {
            ["<c-t>"] = "file_tab",
          },
        },
      },
      pickers = {
        find_files = {
          -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
          hidden = true,
          find_command = { "rg", "--files", "--ignore-case", "--glob", "!**/.git/*", "-L" },
        },
      },
    },
  },
  {
    "nvim-telescope/telescope-symbols.nvim",
  },

  -- Custom ripgrep configuration:

  -- I want to search in hidden/dot files.
  -- "--hidden"
  --
  -- I don't want to search in the `.git` directory.
  -- "--glob")
  -- "!**/.git/*")
  --
  --  I want to follow symbolic links
  -- "-L"
  --
}

