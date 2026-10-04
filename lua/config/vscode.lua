-- ==========================================================================
-- VS CODE KEYBINDINGS
-- ==========================================================================
-- VS Code (Linux) shortcuts layered on top of the Vim ones. Delete this
-- file's require() in init.lua to go back to pure Vim keys.
--
-- Ctrl+Shift / Ctrl+. / Ctrl+` combos need a terminal that reports them
-- (Ghostty, kitty, WezTerm) and, inside tmux, `extended-keys on`.

local map = vim.keymap.set

local function telescope(picker, opts)
	return function()
		require("telescope.builtin")[picker](opts)
	end
end

-- --------------------------------------------------------------------------
-- File / navigation
-- --------------------------------------------------------------------------

map({ "n", "i", "v", "s" }, "<C-s>", "<cmd>write<cr>", { desc = "Save file" })

-- <C-p> (quick open) is defined in plugins/telescope.lua
map("n", "<C-S-p>", telescope("commands"), { desc = "Command palette" })
map("n", "<F1>", telescope("commands"), { desc = "Command palette" })
map("n", "<C-S-f>", telescope("live_grep"), { desc = "Search in files" })
map("n", "<C-S-o>", telescope("lsp_document_symbols"), { desc = "Go to symbol in file" })
map("n", "<C-S-m>", telescope("diagnostics"), { desc = "Problems" })
map("n", "<C-,>", telescope("find_files", { cwd = vim.fn.stdpath("config") }), { desc = "Open settings (Neovim config)" })

map("n", "<C-b>", "<cmd>Neotree toggle<cr>", { desc = "Toggle sidebar" })
map("n", "<C-S-e>", "<cmd>Neotree focus reveal<cr>", { desc = "Focus explorer" })
map("n", "<C-S-g>", "<cmd>LazyGit<cr>", { desc = "Source control (LazyGit)" })

map("n", "<C-Tab>", "<cmd>bnext<cr>", { desc = "Next tab" })
map("n", "<C-S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous tab" })

-- --------------------------------------------------------------------------
-- Editing
-- --------------------------------------------------------------------------

-- Move lines (normal/visual versions live in config/keymaps.lua)
map("i", "<A-Down>", "<Esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-Up>", "<Esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })

-- Copy line up / down
map("n", "<S-A-Down>", "<cmd>t.<cr>", { desc = "Copy line down" })
map("n", "<S-A-Up>", "<cmd>t-1<cr>", { desc = "Copy line up" })
map("i", "<S-A-Down>", "<cmd>t.<cr>", { desc = "Copy line down" })
map("i", "<S-A-Up>", "<cmd>t-1<cr>", { desc = "Copy line up" })
map("v", "<S-A-Down>", ":t'><cr>gv", { silent = true, desc = "Copy selection down" })
map("v", "<S-A-Up>", ":t'<-1<cr>gv", { silent = true, desc = "Copy selection up" })

map("n", "<C-S-k>", "dd", { desc = "Delete line" })
map("i", "<C-S-k>", "<C-o>dd", { desc = "Delete line" })

map("i", "<C-CR>", "<C-o>o", { desc = "Insert line below" })
map("i", "<C-S-CR>", "<C-o>O", { desc = "Insert line above" })

map("n", "<A-z>", "<cmd>set wrap!<cr>", { desc = "Toggle word wrap" })

local function format()
	require("conform").format({ async = true, lsp_format = "fallback" })
end
map({ "n", "v" }, "<S-A-f>", format, { desc = "Format document" })
map({ "n", "v" }, "<C-S-i>", format, { desc = "Format document" })

-- --------------------------------------------------------------------------
-- Code intelligence
-- --------------------------------------------------------------------------

map("n", "<F12>", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "<C-F12>", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "<S-F12>", telescope("lsp_references"), { desc = "Find all references" })
map("n", "<F2>", vim.lsp.buf.rename, { desc = "Rename symbol" })
map({ "n", "v" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Quick fix / code action" })
map("i", "<C-S-Space>", vim.lsp.buf.signature_help, { desc = "Parameter hints" })

map("n", "<F8>", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next problem" })
map("n", "<S-F8>", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous problem" })

-- --------------------------------------------------------------------------
-- Integrated terminal panel (Ctrl+`)
-- --------------------------------------------------------------------------

local term_buf

local function term_alive(buf)
	return buf
		and vim.api.nvim_buf_is_valid(buf)
		and vim.fn.jobwait({ vim.bo[buf].channel }, 0)[1] == -1
end

local function toggle_terminal()
	if term_alive(term_buf) then
		local win = vim.fn.bufwinid(term_buf)
		if win ~= -1 and #vim.api.nvim_tabpage_list_wins(0) > 1 then
			vim.api.nvim_win_hide(win)
			return
		end
	end

	vim.cmd("botright 12split")
	vim.wo.winfixheight = true

	if term_alive(term_buf) then
		vim.api.nvim_win_set_buf(0, term_buf)
	else
		vim.cmd.terminal()
		term_buf = vim.api.nvim_get_current_buf()
		vim.bo[term_buf].buflisted = false -- keep it out of the tabline
	end
	vim.cmd.startinsert()
end

map({ "n", "t" }, "<C-`>", toggle_terminal, { desc = "Toggle terminal panel" })
map("n", "<leader>tt", toggle_terminal, { desc = "Toggle terminal panel" })
