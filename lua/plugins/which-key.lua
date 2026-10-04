-- ==========================================================================
-- WHICH-KEY
-- ==========================================================================

local ok, wk = pcall(require, "which-key")
if not ok then
	return
end

wk.setup({
	preset = "modern",
	delay = 300,
})

wk.add({
	{ "<leader>c", group = "Code / AI" },
	{ "<leader>m", group = "Markdown" },
	{ "<leader>f", group = "Find (Telescope)" },
	{ "<leader>l", group = "Live Server / LazyGit" },
	{ "<leader>t", group = "Terminal" },
	{ "<leader>u", group = "UI Toggles" },
	{ "<leader>w", group = "Windows" },
})

vim.keymap.set("n", "<leader>k", function()
	wk.show({ global = true })
end, { desc = "Show all keymaps (which-key)" })
