return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make"
      }
    },
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
          -- find_command = { "rg", "--files", "--hidden", "--ignore-case", "--glob", "!**/.git/*", "-L" },
          find_command = { "rg", "--files", "--hidden", "--ignore-case", "--glob", "!**/.git/*", "-L" },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,                    -- false will only do exact matching
          case_mode = "ignore_case",        -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        }
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      require("telescope").load_extension("fzf")
    end,
  },

  {
    "nvim-telescope/telescope-symbols.nvim",
    keys = {
      { "<leader>fe", "<cmd>lua require('telescope.builtin').symbols{ sources = {'emoji', 'gitmoji'} }<CR>", desc = "Find Emojis Telescope" },
    }
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

