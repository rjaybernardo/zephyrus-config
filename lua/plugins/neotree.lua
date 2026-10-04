-- ==========================================================================
-- NEO-TREE
-- ==========================================================================

local ok, neotree = pcall(require, "neo-tree")
if not ok then
	return
end

neotree.setup({
	close_if_last_window = true,
	popup_border_style = "rounded",
	enable_git_status = true,
	enable_diagnostics = true,

	filesystem = {
		filtered_items = {
			visible = true,
			hide_dotfiles = false,
			hide_gitignored = false,
		},
		follow_current_file = { enabled = true },
		use_libuv_file_watcher = true,
		-- Oil is the default directory handler
		hijack_netrw_behavior = "disabled",
	},

	window = {
		position = "left",
		width = 32,
		mappings = {
			["<space>"] = "none",
			["l"] = "open",
			["h"] = "close_node",
		},
	},
})

vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })
