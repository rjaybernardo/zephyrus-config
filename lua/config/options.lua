-- ==========================================================================
-- OPTIONS & GLOBALS
-- ==========================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Editing
opt.clipboard = "unnamedplus"
opt.inccommand = "split"
opt.ignorecase = true
opt.smartcase = true
opt.confirm = true
opt.swapfile = false
opt.undofile = true
opt.updatetime = 250

-- Indentation (VS Code defaults: spaces; .editorconfig overrides per project)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Folding (disabled)
opt.foldenable = false
opt.foldmethod = "manual"
opt.foldlevel = 99

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:1"
opt.cursorline = true
opt.termguicolors = true
opt.guicursor = "n-v-c-i:block"
opt.winborder = "rounded"
opt.pumheight = 10
opt.wrap = false -- VS Code default; toggle with Alt+Z
opt.mousemodel = "popup_setpos" -- right-click context menu

-- VS Code-like splits / scrolling
opt.splitbelow = true
opt.splitright = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Skip unused remote-plugin providers (faster startup)
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- ==========================================================================
-- PLUGIN GLOBALS (must be set before the plugins are sourced)
-- ==========================================================================

vim.g.live_server = { port = 8080 }

-- Mappings are defined in config/keymaps.lua
vim.g.tmux_navigator_no_mappings = 1

vim.g.VM_maps = {
	["Find Under"] = "<C-n>",
	["Find Subword Under"] = "<C-n>",
	["Select All"] = "<C-A-n>",
	["Add Cursor Down"] = "<C-Down>",
	["Add Cursor Up"] = "<C-Up>",
}

-- ==========================================================================
-- FILETYPES
-- ==========================================================================

vim.filetype.add({
	extension = {
		liquid = "liquid",
	},
})
