-- ==========================================================================
-- WINBAR (VS Code style breadcrumbs: path › symbol › symbol)
-- ==========================================================================

local M = {}

local excluded_filetypes = {
	["neo-tree"] = true,
	oil = true,
	help = true,
	qf = true,
	checkhealth = true,
	undotree = true,
	nvimundotree = true,
}

function M.render()
	local path = vim.fn.expand("%:~:.")
	if path == "" then
		return ""
	end

	local parts = { (path:gsub("%%", "%%%%")) }

	local ok, navic = pcall(require, "nvim-navic")
	if ok and navic.is_available() then
		local location = navic.get_location()
		if location ~= "" then
			table.insert(parts, location)
		end
	end

	return " " .. table.concat(parts, " › ")
end

vim.o.winbar = "%{%v:lua.require'config.winbar'.render()%}"

-- Hide the bar in sidebars, special buffers and terminals.
local group = vim.api.nvim_create_augroup("user_winbar", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	callback = function(args)
		if excluded_filetypes[args.match] or vim.bo[args.buf].buftype == "nofile" then
			vim.wo.winbar = ""
		end
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	group = group,
	callback = function()
		vim.wo.winbar = ""
	end,
})

return M
