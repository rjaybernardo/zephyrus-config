-- ==========================================================================
-- RENDER MARKDOWN (markdown files + CodeCompanion chat buffers)
-- ==========================================================================

local ok, render_markdown = pcall(require, "render-markdown")
if not ok then
	return
end

render_markdown.setup({
	render_modes = { "n", "c", "t" },
	file_types = { "markdown", "codecompanion" },
	code = {
		style = "minimal",
		left_pad = 0,
		right_pad = 0,
		border = "thin",
	},
	max_file_size = 10.0,
})

local map = vim.keymap.set

map("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle Markdown rendering" })
map("n", "<leader>me", "<cmd>RenderMarkdown enable<cr>", { desc = "Enable Markdown rendering" })
map("n", "<leader>md", "<cmd>RenderMarkdown disable<cr>", { desc = "Disable Markdown rendering" })
