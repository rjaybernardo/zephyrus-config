-- ==========================================================================
-- OIL
-- ==========================================================================

local ok, oil = pcall(require, "oil")
if not ok then
	return
end

oil.setup({
	default_file_explorer = true,
	skip_confirm_for_simple_edits = true,
	delete_to_trash = true,
	view_options = { show_hidden = true },
})

vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory (Oil)" })
