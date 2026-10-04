-- ==========================================================================
-- MINI.NVIM
-- ==========================================================================

local ok_icons, icons = pcall(require, "mini.icons")
if ok_icons then
	icons.setup()
	icons.mock_nvim_web_devicons()
end

for _, mod in ipairs({ "pairs", "statusline", "tabline" }) do
	local ok, m = pcall(require, "mini." .. mod)
	if ok then
		m.setup()
	end
end

local ok_indent, indentscope = pcall(require, "mini.indentscope")
if ok_indent then
	indentscope.setup({
		symbol = "│",
		options = { try_as_border = true },
	})
end
