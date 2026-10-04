-- ==========================================================================
-- SNIPPETS (in-process LSP server)
-- ==========================================================================
-- Serves the snippets below as LSP completion items, so they show up in
-- Neovim's native completion menu next to real LSP results and expand
-- with vim.snippet. No snippet engine or completion plugin needed.
--
-- To add snippets: create lua/snippets/<name>.lua returning
-- { trigger = { desc = "...", body = "..." } } and map filetypes to it here.

local M = {}

local js = require("snippets.javascript")

---@type table<string, table<string, { desc: string, body: string }>>
M.by_filetype = {
	javascript = js,
	typescript = js,
	javascriptreact = js,
	typescriptreact = js,
}

local Kind = vim.lsp.protocol.CompletionItemKind
local InsertTextFormat = vim.lsp.protocol.InsertTextFormat

local function completion_items(params)
	local buf = vim.uri_to_bufnr(params.textDocument.uri)
	local items = {}
	for trigger, snip in pairs(M.by_filetype[vim.bo[buf].filetype] or {}) do
		table.insert(items, {
			label = trigger,
			kind = Kind.Snippet,
			detail = snip.desc,
			insertText = snip.body,
			insertTextFormat = InsertTextFormat.Snippet,
			documentation = { kind = "markdown", value = "```" .. vim.bo[buf].filetype .. "\n" .. snip.body .. "\n```" },
		})
	end
	return items
end

local function server(dispatchers)
	local closing = false
	local request_id = 0

	return {
		request = function(method, params, callback)
			request_id = request_id + 1
			if method == "initialize" then
				callback(nil, { capabilities = { completionProvider = {} } })
			elseif method == "textDocument/completion" then
				callback(nil, completion_items(params))
			else
				callback(nil, nil)
			end
			return true, request_id
		end,
		notify = function(method)
			if method == "exit" then
				dispatchers.on_exit(0, 15)
			end
			return true
		end,
		is_closing = function()
			return closing
		end,
		terminate = function()
			closing = true
		end,
	}
end

function M.setup()
	vim.lsp.config("snippets", {
		cmd = server,
		filetypes = vim.tbl_keys(M.by_filetype),
	})
	vim.lsp.enable("snippets")
end

return M
