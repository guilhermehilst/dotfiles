--
-- It overrides the following keys to always use the black hole register: c, C, s, S, d, D, x, X.
-- On this configuration, the action "d" deletes and save to clipboard

return {
  "gbprod/cutlass.nvim",
  opts = {
    -- your configuration comes here
    -- or don't set opts to use the default settings
    -- refer to the configuration section below

    -- Set "d" to delete and save to clipboard
    cut_key = "d"
  }
}

