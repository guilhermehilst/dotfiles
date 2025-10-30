-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.ignorecase = true

-- scrolling
opt.number = true
opt.relativenumber = false
opt.cursorline = false

-- Disable LazyVim auto format
vim.g.autoformat = false
