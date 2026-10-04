-- ==========================================================================
-- LSP, MASON, NAVIC & DIAGNOSTICS
-- ==========================================================================

-- Servers to enable. Mason installs all of these except vtsls and
-- shopify_theme_ls, which are installed separately (npm / Shopify CLI).
local servers = {
	"lua_ls",
	"basedpyright",
	"vtsls",
	"html",
	"cssls",
	"jsonls",
	"eslint",
	"emmet_ls",
	"shopify_theme_ls",
	"tailwindcss",
}

local mason_servers = {
	"lua_ls",
	"basedpyright",
	"html",
	"cssls",
	"emmet_ls",
	"jsonls",
	"eslint",
	"tailwindcss",
}

-- --------------------------------------------------------------------------
-- Mason
-- --------------------------------------------------------------------------

local ok_mason, mason = pcall(require, "mason")
if ok_mason then
	mason.setup()
end

local ok_mason_lsp, mason_lsp = pcall(require, "mason-lspconfig")
if ok_mason_lsp then
	mason_lsp.setup({
		ensure_installed = mason_servers,
		automatic_enable = false, -- enabled explicitly below
	})
end

-- --------------------------------------------------------------------------
-- Diagnostics
-- --------------------------------------------------------------------------

local severity = vim.diagnostic.severity

vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		spacing = 4,
		source = "if_many",
	},
	signs = {
		text = {
			[severity.ERROR] = "󰅚 ",
			[severity.WARN] = "󰀪 ",
			[severity.HINT] = "󰌶 ",
			[severity.INFO] = "󰋽 ",
		},
	},
	float = { source = "if_many" },
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

-- --------------------------------------------------------------------------
-- Navic (breadcrumbs, rendered by config/winbar.lua). auto_attach picks one server per buffer, so
-- multiple symbol providers (e.g. html + emmet) don't conflict.
-- --------------------------------------------------------------------------

local ok_navic, navic = pcall(require, "nvim-navic")
if ok_navic then
	navic.setup({
		lsp = {
			auto_attach = true,
			preference = { "vtsls" },
		},
		highlight = true,
		separator = " › ",
	})
end

-- --------------------------------------------------------------------------
-- Server configs
-- --------------------------------------------------------------------------
-- Built-in LSP keymaps (0.11+/0.12): K, grn rename, gra code action,
-- grr references, gri implementation, grt type definition, gO symbols,
-- grx codelens, [d / ]d diagnostics. :lsp manages clients.
-- Default client capabilities already include snippet support.

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = {
				-- Only the Neovim runtime: indexing every plugin on the
				-- runtimepath makes lua_ls slow to start.
				library = { vim.env.VIMRUNTIME },
				checkThirdParty = false,
			},
			telemetry = { enable = false },
		},
	},
})

vim.lsp.config("emmet_ls", {
	-- emmet-ls advertises completionItem/resolve but doesn't implement it,
	-- which prints "Unhandled method" while browsing the completion menu.
	on_init = function(client)
		local provider = client.server_capabilities.completionProvider
		if provider then
			provider.resolveProvider = false
		end
	end,
	filetypes = {
		"html",
		"css",
		"scss",
		"sass",
		"less",
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"liquid",
	},
})

vim.lsp.config("tailwindcss", {
	filetypes = {
		"html",
		"css",
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"liquid",
	},
	init_options = {
		userLanguages = { liquid = "html" },
	},
})

vim.lsp.config("cssls", {
	settings = {
		css = {
			validate = true,
			lint = { unknownAtRules = "ignore" },
		},
	},
})

vim.lsp.enable(servers)
