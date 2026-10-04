-- ==========================================================================
-- COMPLETION (native, Neovim 0.12)
-- ==========================================================================
-- LSP buffers: vim.lsp.completion with autotrigger on every keystroke.
-- Other buffers: built-in 'autocomplete' with words from open buffers.
-- Loaded after mini.nvim so the <CR> mapping can wrap mini.pairs.

local opt = vim.opt

opt.autocomplete = true
opt.complete = ".^5,w^5,b^5,u^5"
opt.completeopt = { "menuone", "noselect", "popup" }
opt.pumborder = "rounded"

require("snippets").setup()

-- CodeCompanion chat: its /slash commands, #context and @tools come from the
-- buffer's omnifunc (nvim-cmp used to supply them), so autocomplete must ask it.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("user_codecompanion_completion", { clear = true }),
	pattern = "codecompanion",
	callback = function(args)
		vim.bo[args.buf].complete = "o," .. vim.o.complete
	end,
})

-- --------------------------------------------------------------------------
-- LSP completion
-- --------------------------------------------------------------------------

local has_icons, icons = pcall(require, "mini.icons")

local function convert(item)
	local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Text"
	local icon = has_icons and icons.get("lsp", kind) or nil
	return { kind = icon and (icon .. " " .. kind) or kind }
end

-- Order merged results like the old nvim-cmp priorities: language servers,
-- then snippets, then emmet (which offers every word as an HTML tag).
local client_rank = { snippets = 2, emmet_ls = 3 }

local function rank(item)
	local client = vim.lsp.get_client_by_id(item.user_data.nvim.lsp.client_id)
	return client and client_rank[client.name] or 1
end

local function compare(a, b)
	local ra, rb = rank(a), rank(b)
	if ra ~= rb then
		return ra < rb
	end
	local ia, ib = a.user_data.nvim.lsp.completion_item, b.user_data.nvim.lsp.completion_item
	return (ia.sortText or ia.label) < (ib.sortText or ib.label)
end

-- Servers only trigger on characters like "." by default.
-- Adding every word character makes completion appear as you type.
local word_chars = vim.split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", "")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_completion", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not (client and client:supports_method("textDocument/completion")) then
			return
		end

		local provider = client.server_capabilities.completionProvider
		provider.triggerCharacters = vim.list.unique(vim.list_extend(vim.deepcopy(provider.triggerCharacters or {}), word_chars))

		vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true, convert = convert, cmp = compare })

		-- LSP drives the menu here; built-in autocomplete would open a competing one.
		vim.bo[args.buf].autocomplete = false
	end,
})

-- --------------------------------------------------------------------------
-- Keymaps (same feel as the old nvim-cmp setup)
-- --------------------------------------------------------------------------

local map = vim.keymap.set
local pumvisible = function()
	return vim.fn.pumvisible() == 1
end

-- Tab: jump through snippet placeholders first, then cycle the menu.
map({ "i", "s" }, "<Tab>", function()
	if vim.snippet.active({ direction = 1 }) then
		return "<cmd>lua vim.snippet.jump(1)<cr>"
	end
	return pumvisible() and "<C-n>" or "<Tab>"
end, { expr = true, desc = "Next snippet field / completion item" })

map({ "i", "s" }, "<S-Tab>", function()
	if vim.snippet.active({ direction = -1 }) then
		return "<cmd>lua vim.snippet.jump(-1)<cr>"
	end
	return pumvisible() and "<C-p>" or "<S-Tab>"
end, { expr = true, desc = "Previous snippet field / completion item" })

map("i", "<C-j>", function()
	return pumvisible() and "<C-n>" or "<C-j>"
end, { expr = true, desc = "Next completion item" })

map("i", "<C-k>", function()
	return pumvisible() and "<C-p>" or "<C-k>"
end, { expr = true, desc = "Previous completion item" })

-- Enter accepts (first item if none selected); <C-y> applies LSP edits
-- and snippet expansion. Otherwise fall through to mini.pairs.
map("i", "<CR>", function()
	if pumvisible() then
		return vim.fn.complete_info({ "selected" }).selected == -1 and "<C-n><C-y>" or "<C-y>"
	end
	return _G.MiniPairs and MiniPairs.cr() or "<CR>"
end, { expr = true, desc = "Accept completion / newline" })

map("i", "<C-Space>", function()
	if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" }) > 0 then
		vim.lsp.completion.get()
	else
		vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", false)
	end
end, { desc = "Trigger completion" })
