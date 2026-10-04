-- ==========================================================================
-- AUTOCOMMANDS
-- ==========================================================================

local augroup = function(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
	end,
})

-- Transparent diagnostic virtual text. Re-applied on every colorscheme
-- change, otherwise switching themes would reset it.
vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup("diagnostic_hl"),
	callback = function()
		for _, level in ipairs({ "Error", "Warn", "Info", "Hint" }) do
			local name = "DiagnosticVirtualText" .. level
			local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
			hl.bg = nil
			vim.api.nvim_set_hl(0, name, hl)
		end
	end,
})

-- Reload files changed outside Neovim (e.g. git checkout), like VS Code
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.bo.buftype == "" then
			vim.cmd.checktime()
		end
	end,
})

-- Reopen files at the last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_position"),
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local ft = vim.bo[args.buf].filetype
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) and ft ~= "gitcommit" then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- LazyGit: let <Esc> reach lazygit instead of leaving terminal mode
vim.api.nvim_create_autocmd("TermOpen", {
	group = augroup("lazygit_esc"),
	pattern = "term://*lazygit*",
	callback = function()
		vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = true, nowait = true })
		vim.keymap.set("t", "<Esc><Esc>", "<Esc><Esc>", { buffer = true, nowait = true })
	end,
})
