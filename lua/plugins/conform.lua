-- ==========================================================================
-- CONFORM (formatting)
-- ==========================================================================

local ok, conform = pcall(require, "conform")
if not ok then
	return
end

local LIQUID_PLUGIN = "@shopify/prettier-plugin-liquid/dist/index.js"

-- `npm root -g` is slow; resolve it once and cache the result.
local npm_global_root
local function get_npm_global_root()
	if npm_global_root == nil then
		npm_global_root = false
		if vim.fn.executable("npm") == 1 then
			local out = vim.trim(vim.fn.system({ "npm", "root", "-g" }))
			if vim.v.shell_error == 0 and out ~= "" then
				npm_global_root = out
			end
		end
	end
	return npm_global_root or nil
end

-- Prefer the project's plugin, fall back to a globally installed one.
local function find_liquid_plugin(dirname)
	local node_modules = vim.fs.find("node_modules", { path = dirname, upward = true })[1]
	for _, root in ipairs({ node_modules, get_npm_global_root() }) do
		local path = root and (root .. "/" .. LIQUID_PLUGIN)
		if path and vim.uv.fs_stat(path) then
			return path
		end
	end
end

local prettier = { "prettier" }

conform.setup({
	formatters_by_ft = {
		javascript = prettier,
		typescript = prettier,
		javascriptreact = prettier,
		typescriptreact = prettier,
		css = prettier,
		html = prettier,
		json = prettier,
		markdown = prettier,
		liquid = { "prettier_liquid" },
	},

	formatters = {
		prettier_liquid = {
			command = function(_, ctx)
				return vim.fs.find("node_modules/.bin/prettier", { path = ctx.dirname, upward = true })[1]
					or "prettier"
			end,
			args = function(_, ctx)
				local args = { "--stdin-filepath", ctx.filename, "--parser", "liquid-html" }
				local plugin = find_liquid_plugin(ctx.dirname)
				if plugin then
					vim.list_extend(args, { "--plugin", plugin })
				end
				return args
			end,
			stdin = true,
		},
	},

	format_on_save = function()
		if vim.g.disable_autoformat then
			return nil
		end
		return { timeout_ms = 2000, lsp_format = "fallback" }
	end,
})

vim.keymap.set("n", "<leader>=", function()
	conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format current file" })

vim.keymap.set("n", "<leader>uf", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	vim.notify("Auto-format on save: " .. (vim.g.disable_autoformat and "DISABLED" or "ENABLED"))
end, { desc = "Toggle auto-format on save" })
