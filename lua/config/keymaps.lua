-- ==========================================================================
-- GENERAL KEYMAPS (plugin-specific maps live with their plugin module)
-- ==========================================================================

local map = vim.keymap.set

-- Tmux navigation
map({ "n", "i", "t" }, "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { silent = true, desc = "Navigate left" })
map({ "n", "t" }, "<C-j>", "<cmd>TmuxNavigateDown<cr>", { silent = true, desc = "Navigate down" })
map({ "n", "t" }, "<C-k>", "<cmd>TmuxNavigateUp<cr>", { silent = true, desc = "Navigate up" })
map({ "n", "i", "t" }, "<C-l>", "<cmd>TmuxNavigateRight<cr>", { silent = true, desc = "Navigate right" })

-- Window resize
map("n", "<C-S-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-S-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-S-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Window navigation
map("n", "<leader>wh", "<C-w>h", { desc = "Go to left window" })
map("n", "<leader>wj", "<C-w>j", { desc = "Go to lower window" })
map("n", "<leader>wk", "<C-w>k", { desc = "Go to upper window" })
map("n", "<leader>wl", "<C-w>l", { desc = "Go to right window" })

-- Buffers ("file tabs")
map("n", "H", "<cmd>bprevious<cr>", { desc = "Previous file tab" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next file tab" })
map("n", "<leader>co", "<cmd>%bd|e#|bd#<cr>", { desc = "Close all other file tabs" })

map("n", "<leader>x", function()
	local current = vim.api.nvim_get_current_buf()
	local alternate = vim.fn.bufnr("#")

	if alternate > 0 and vim.api.nvim_buf_is_valid(alternate) and vim.bo[alternate].buflisted then
		vim.cmd("buffer #")
	else
		vim.cmd("bnext")
	end

	-- Last listed buffer: replace it with an empty one so the window stays open.
	if vim.api.nvim_get_current_buf() == current then
		vim.cmd("enew")
	end
	vim.cmd("bdelete " .. current)
end, { desc = "Close current file tab" })

-- Move lines
map("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-Down>", ":m '>+1<cr>gv=gv", { silent = true, desc = "Move selection down" })
map("v", "<A-Up>", ":m '<-2<cr>gv=gv", { silent = true, desc = "Move selection up" })

-- Indent while keeping the selection
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Search
map("n", "<leader>ch", "<cmd>nohlsearch<cr>", { desc = "Clear search highlights" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

-- Terminal
map("n", "<leader>th", "<cmd>split | terminal<cr>", { desc = "Terminal (horizontal split)" })
map("n", "<leader>tv", "<cmd>vsplit | terminal<cr>", { desc = "Terminal (vertical split)" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Diagnostics
map("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic under cursor" })

map("n", "<leader>ud", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

map("n", "<leader>q", function()
	for _, win in ipairs(vim.fn.getwininfo()) do
		if win.quickfix == 1 then
			vim.cmd("cclose")
			return
		end
	end
	vim.diagnostic.setqflist()
end, { desc = "Toggle quickfix diagnostics" })

map("n", "<leader>uh", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })

-- Comment toggle, VS Code style (native gc/gcc; <C-_> is what most terminals send)
for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
	map("n", lhs, "gcc", { remap = true, desc = "Toggle comment" })
	map("v", lhs, "gc", { remap = true, desc = "Toggle comment" })
end

-- Built-in undo tree (0.12)
map("n", "<leader>uu", function()
	vim.cmd.packadd("nvim.undotree")
	vim.cmd.Undotree()
end, { desc = "Toggle undo tree" })

-- Keymap listing
map("n", "<leader>?", "<cmd>nmap<cr>", { desc = "List all normal-mode keymaps" })
