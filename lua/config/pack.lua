-- ==========================================================================
-- PLUGINS (Neovim 0.12 native vim.pack)
-- ==========================================================================
-- Built in, so no plugin needed: completion + snippets (vim.lsp.completion,
-- vim.snippet), commenting (gc/gcc), LSP config (vim.lsp.config/enable),
-- treesitter incremental selection (v_an / v_in), :Undotree.
--
-- Removing a plugin from this list does not delete it from disk; run
-- :lua vim.pack.del({ "name" }) for that.

local gh = function(repo)
	return "https://github.com/" .. repo
end

-- Keep nvim-treesitter parsers in sync with plugin updates.
-- Must be registered before vim.pack.add() so it fires on first install.
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("user_pack_changed", { clear = true }),
	callback = function(ev)
		local data = ev.data
		if not (data and data.spec) then
			return
		end

		if data.spec.name == "nvim-treesitter" and (data.kind == "install" or data.kind == "update") then
			if not data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end
	end,
})

vim.pack.add({
	-- Colorscheme
	{ src = gh("catppuccin/nvim"), name = "catppuccin" },

	-- File explorers
	gh("stevearc/oil.nvim"),
	gh("MunifTanjim/nui.nvim"),
	{ src = gh("nvim-neo-tree/neo-tree.nvim"), version = vim.version.range("3") },

	-- Editing / navigation
	gh("mg979/vim-visual-multi"),
	gh("christoomey/vim-tmux-navigator"),

	-- LSP
	gh("neovim/nvim-lspconfig"),
	gh("mason-org/mason.nvim"),
	gh("mason-org/mason-lspconfig.nvim"),

	-- Treesitter
	gh("nvim-treesitter/nvim-treesitter"),
	gh("windwp/nvim-ts-autotag"),
	gh("nvim-treesitter/nvim-treesitter-context"), -- sticky scroll

	-- Search / Git
	gh("nvim-lua/plenary.nvim"),
	gh("nvim-telescope/telescope.nvim"),
	gh("lewis6991/gitsigns.nvim"),
	gh("kdheepak/lazygit.nvim"),

	-- Formatting
	gh("stevearc/conform.nvim"),

	-- Live server
	"https://git.barrettruth.com/barrettruth/live-server.nvim",

	-- Mini (icons, pairs, statusline, tabline, indentscope)
	gh("nvim-mini/mini.nvim"),

	-- UI
	gh("SmiteshP/nvim-navic"),
	gh("folke/which-key.nvim"),
	gh("MeanderingProgrammer/render-markdown.nvim"),

	-- AI (local Ollama + VectorCode RAG, optional Claude Code over ACP)
	gh("olimorris/codecompanion.nvim"),
	gh("Davidyz/VectorCode"),
	gh("lalitmee/codecompanion-spinners.nvim"),
})
