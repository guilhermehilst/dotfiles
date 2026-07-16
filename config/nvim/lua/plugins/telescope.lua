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
      -- Variantes que incluem também arquivos do .gitignore (mantendo .git de fora)
      {
        "<leader>fF",
        function()
          require("telescope.builtin").find_files({
            find_command = { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!**/.git/*", "-L" },
          })
        end,
        desc = "Find Files (inclui .gitignore) Telescope",
      },
      {
        "<leader>fG",
        function()
          require("telescope.builtin").live_grep({
            additional_args = function()
              return { "--no-ignore" }
            end,
          })
        end,
        desc = "Live Grep (inclui .gitignore) Telescope",
      },
    },
    opts = {
      defaults = {
        -- Base do ripgrep para live_grep/grep_string: inclui dotfiles e exclui .git
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--glob",
          "!**/.git/*",
        },
        mappings = {
          i = {
            ["<c-t>"] = "file_tab",
          },
        },
      },
      pickers = {
        find_files = {
          -- Inclui dotfiles, exclui .git, respeita .gitignore, segue symlinks
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*", "-L" },
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
}
