-- ==========================================================================
-- TREESITTER (nvim-treesitter main branch API) + AUTOTAG
-- ==========================================================================

local ok, treesitter = pcall(require, "nvim-treesitter")
if ok then
	treesitter.setup({
		install_dir = vim.fn.stdpath("data") .. "/site",
	})

	local languages = {
		"lua", "vim", "bash", "regex",
		"markdown", "markdown_inline",
		"javascript", "typescript", "tsx", "prisma",
		"html", "css", "json", "liquid",
		"yaml", "toml", "dockerfile",
		"gitcommit", "gitattributes",
		"python", "cuda",
	}

	treesitter.install(languages)

	-- Map filetype -> parser at event time (e.g. typescriptreact -> tsx).
	-- Resolving it here instead would miss aliases nvim-treesitter
	-- registers after init.lua runs.
	local wanted = {}
	for _, lang in ipairs(languages) do
		wanted[lang] = true
	end

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true }),
		callback = function(args)
			local lang = vim.treesitter.language.get_lang(args.match)
			if not wanted[lang] then
				return
			end
			if pcall(vim.treesitter.start, args.buf, lang) then
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end,
	})
end

-- Sticky scroll: keep the enclosing function/class header visible
local ok_context, context = pcall(require, "treesitter-context")
if ok_context then
	context.setup({ max_lines = 3, trim_scope = "inner" })
end

local ok_autotag, autotag = pcall(require, "nvim-ts-autotag")
if ok_autotag then
	autotag.setup({
		opts = {
			enable_close = true,
			enable_rename = true,
			enable_close_on_slash = true,
		},
	})
end
