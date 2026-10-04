-- ==========================================================================
-- ENTRY POINT
-- ==========================================================================
-- Core config lives in lua/config/, plugin setup in lua/plugins/.
-- Order matters: options and plugin globals must exist before plugins load.

require("config.options")
require("config.pack")
require("config.keymaps")
require("config.vscode")
require("config.autocmds")
require("config.winbar")

-- Each plugin module is loaded in isolation so one broken module
-- doesn't take down the rest of the config.
local plugin_modules = {
	"colorscheme",
	"mini",
	"oil",
	"neotree",
	"treesitter",
	"git",
	"conform",
	"telescope",
	"lsp",
	"completion",
	"live-server",
	"render-markdown",
	"ai",
	"which-key", -- last, so it sees every mapping
}

for _, name in ipairs(plugin_modules) do
	local ok, err = pcall(require, "plugins." .. name)
	if not ok then
		vim.notify(("Failed to load plugins.%s:\n%s"):format(name, err), vim.log.levels.ERROR)
	end
end
