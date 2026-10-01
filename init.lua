local local_bin = vim.fn.expand("~/.local/bin")

if not vim.env.PATH:find(local_bin, 1, true) then
	vim.env.PATH = local_bin .. ":" .. vim.env.PATH
end
-- ==========================================================================
-- 1. GLOBAL OPTIONS, CLIPBOARD & LIVE-SERVER VARIABLE
-- ==========================================================================
vim.g.mapleader = " "
vim.opt.inccommand = "split"
vim.opt.clipboard = "unnamedplus"
-- Disable automatic code folding
vim.opt.foldenable = false
vim.opt.foldmethod = "manual"
vim.opt.foldlevel = 99

vim.g.live_server = {
	port = 8080,
}

local opt = vim.opt

opt.number = true
opt.pumheight = 10
opt.updatetime = 250
opt.relativenumber = true
opt.ignorecase = true
opt.smartcase = true
opt.confirm = true
opt.signcolumn = "yes:1"
opt.termguicolors = true
opt.completeopt = { "menu", "menuone", "noselect" }

-- VS Code-like UI behavior
opt.splitbelow = true
opt.splitright = true
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.swapfile = false

-- Visual improvements
vim.opt.guicursor = "n-v-c-i:block"
opt.cursorline = true
vim.o.winborder = "rounded"

-- Prevent unnecessary provider initialization
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0

-- Let vim-tmux-navigator handle mappings
vim.g.tmux_navigator_no_mappings = 1


-- ==========================================================================
-- FILETYPE OVERRIDES
-- ==========================================================================

vim.filetype.add({
	extension = {
		liquid = "liquid",
	},
})


-- ==========================================================================
-- 2. NATIVE PLUGIN MODULE (Neovim 0.12 vim.pack)
-- ==========================================================================

local plugins = {
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	"https://github.com/stevearc/oil.nvim",

	-- Neo-tree
	"https://github.com/MunifTanjim/nui.nvim",
	{
		src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
		version = vim.version.range("3"),
	},

	-- Editing / navigation
	"https://github.com/mg979/vim-visual-multi",
	"https://github.com/christoomey/vim-tmux-navigator",

	-- LSP
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim",

	-- Treesitter
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/windwp/nvim-ts-autotag",

	-- Search / Git
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/kdheepak/lazygit.nvim",

	-- Formatting / snippets
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/L3MON4D3/LuaSnip",
	"https://github.com/rafamadriz/friendly-snippets",

	-- Live server
	"https://git.barrettruth.com/barrettruth/live-server.nvim",

	-- AI
	"https://github.com/olimorris/codecompanion.nvim",
	"https://github.com/Davidyz/VectorCode",
	"https://github.com/lalitmee/codecompanion-spinners.nvim",
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",

	-- Mini
	"https://github.com/nvim-mini/mini.nvim",

	-- Completion
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/hrsh7th/cmp-buffer",
	"https://github.com/hrsh7th/cmp-path",
	"https://github.com/saadparwaiz1/cmp_luasnip",

	-- Navigation / UI
	"https://github.com/SmiteshP/nvim-navic",
	"https://github.com/folke/which-key.nvim",
}

-- Keep nvim-treesitter parsers in sync with plugin updates.
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("NvimTreesitterUpdate", {
		clear = true,
	}),
	callback = function(ev)
		local data = ev.data
		if not data or not data.spec then
			return
		end

		local name = data.spec.name
		local kind = data.kind

		if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
			if not data.active then
				vim.cmd.packadd("nvim-treesitter")
			end

			vim.cmd("TSUpdate")
		end
	end,
})

vim.pack.add(plugins)


-- ==========================================================================
-- 3. MINI.NVIM INTEGRATION
-- ==========================================================================

local has_mini_icons, mini_icons = pcall(require, "mini.icons")
if has_mini_icons then
	mini_icons.setup()
	mini_icons.mock_nvim_web_devicons()
end

local has_mini_comment, mini_comment = pcall(require, "mini.comment")
if has_mini_comment then
	mini_comment.setup()
end

local has_mini_pairs, mini_pairs = pcall(require, "mini.pairs")
if has_mini_pairs then
	mini_pairs.setup()
end

local has_mini_statusline, mini_statusline = pcall(require, "mini.statusline")
if has_mini_statusline then
	mini_statusline.setup()
end

local has_mini_tabline, mini_tabline = pcall(require, "mini.tabline")
if has_mini_tabline then
	mini_tabline.setup()
end

local has_mini_indentscope, mini_indentscope =
    pcall(require, "mini.indentscope")

if has_mini_indentscope then
	mini_indentscope.setup({
		symbol = "│",
		options = {
			try_as_border = true,
		},
	})
end


-- ==========================================================================
-- RENDER MARKDOWN
-- ==========================================================================

local has_render_markdown, render_markdown =
    pcall(require, "render-markdown")

if has_render_markdown then
	render_markdown.setup({
		enabled = true,

		render_modes = {
			"n",
			"c",
			"t",
		},

		file_types = {
			"markdown",
			"codecompanion",
		},

		code = {
			enabled = true,
			style = "minimal",
			left_pad = 0,
			right_pad = 0,
			number = false,
			border = "thin",
		},

		heading = {
			enabled = true,
		},

		bullet = {
			enabled = true,
		},

		checkbox = {
			enabled = true,
		},

		table = {
			enabled = true,
		},

		max_file_size = 10.0,
	})
end


-- Markdown shortcuts

vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", {
	desc = "Toggle Markdown rendering",
})

vim.keymap.set("n", "<leader>me", "<cmd>RenderMarkdown enable<CR>", {
	desc = "Enable Markdown rendering",
})

vim.keymap.set("n", "<leader>md", "<cmd>RenderMarkdown disable<CR>", {
	desc = "Disable Markdown rendering",
})


-- ==========================================================================
-- 4. PLUGIN SETUP & VS CODE STYLING
-- ==========================================================================

vim.cmd.colorscheme("catppuccin-mocha")


-- ==========================================================================
-- MULTI-CURSOR
-- ==========================================================================

vim.g.VM_maps = {
	["Find Under"] = "<C-n>",
	["Find Subword Under"] = "<C-n>",
	["Select All"] = "<C-A-n>",
	["Add Cursor Down"] = "<C-Down>",
	["Add Cursor Up"] = "<C-Up>",
}


-- ==========================================================================
-- DIAGNOSTIC HIGHLIGHTS
-- ==========================================================================

vim.api.nvim_set_hl(
	0,
	"DiagnosticVirtualTextError",
	{ bg = "NONE" }
)

vim.api.nvim_set_hl(
	0,
	"DiagnosticVirtualTextWarn",
	{ bg = "NONE" }
)

vim.api.nvim_set_hl(
	0,
	"DiagnosticVirtualTextInfo",
	{ bg = "NONE" }
)

vim.api.nvim_set_hl(
	0,
	"DiagnosticVirtualTextHint",
	{ bg = "NONE" }
)


-- ==========================================================================
-- OIL
-- ==========================================================================

local has_oil, oil = pcall(require, "oil")

if has_oil then
	oil.setup({
		default_file_explorer = true,
		skip_confirm_for_simple_edits = true,
		delete_to_trash = true,

		view_options = {
			show_hidden = true,
		},
	})

	vim.keymap.set(
		"n",
		"-",
		"<CMD>Oil<CR>",
		{
			desc = "Open parent directory in Oil",
		}
	)
end


-- ==========================================================================
-- NEO-TREE
-- ==========================================================================

local has_neotree, neotree = pcall(require, "neo-tree")

if has_neotree then
	neotree.setup({
		close_if_last_window = true,
		popup_border_style = "rounded",

		enable_git_status = true,
		enable_diagnostics = true,

		filesystem = {
			filtered_items = {
				visible = true,
				hide_dotfiles = false,
				hide_gitignored = false,
			},

			follow_current_file = {
				enabled = true,
			},

			use_libuv_file_watcher = true,
		},

		window = {
			position = "left",
			width = 32,

			mappings = {
				["<space>"] = "none",
				["l"] = "open",
				["h"] = "close_node",
			},
		},
	})

	vim.keymap.set(
		"n",
		"<leader>e",
		"<CMD>Neotree toggle<CR>",
		{
			desc = "Toggle File Explorer",
		}
	)
end


-- ==========================================================================
-- NVIM-TREESITTER 0.12+ API
-- ==========================================================================

local has_ts, treesitter = pcall(require, "nvim-treesitter")

if has_ts then
	treesitter.setup({
		install_dir = vim.fn.stdpath("data") .. "/site",
	})

	local ts_languages = {
		"lua",
		"bash",
		"markdown",
		"cuda",

		"javascript",
		"typescript",
		"tsx",
		"prisma",

		"html",
		"css",
		"json",

		"yaml",
		"toml",
		"dockerfile",

		"vim",
		"markdown_inline",

		"liquid",

		"gitcommit",
		"gitattributes",

		"python",
		"regex",
	}

	treesitter.install(ts_languages)

	vim.api.nvim_create_autocmd("FileType", {
		pattern = {
			"lua",
			"bash",
			"markdown",
			"cuda",

			"javascript",
			"typescript",
			"typescriptreact",
			"javascriptreact",
			"prisma",

			"html",
			"css",
			"json",

			"yaml",
			"toml",
			"dockerfile",

			"vim",

			"gitcommit",
			"gitattributes",

			"python",
			"regex",

			"liquid",
		},

		callback = function(args)
			local ok = pcall(
				vim.treesitter.start,
				args.buf
			)

			if ok then
				vim.bo.indentexpr =
				"v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end,
	})
end


-- ==========================================================================
-- AUTO TAG
-- ==========================================================================

local has_autotag, autotag =
    pcall(require, "nvim-ts-autotag")

if has_autotag then
	autotag.setup({
		opts = {
			enable_close = true,
			enable_rename = true,
			enable_close_on_slash = true,
		},
	})
end


-- ==========================================================================
-- GITSIGNS
-- ==========================================================================

local has_gs, gitsigns = pcall(require, "gitsigns")

if has_gs then
	gitsigns.setup({
		current_line_blame = true,
	})

	vim.keymap.set(
		"n",
		"]c",
		"<cmd>Gitsigns next_hunk<CR>",
		{
			desc = "Next git change",
		}
	)

	vim.keymap.set(
		"n",
		"[c",
		"<cmd>Gitsigns prev_hunk<CR>",
		{
			desc = "Previous git change",
		}
	)
end


-- ==========================================================================
-- CONFORM
-- ==========================================================================

local has_conform, conform =
    pcall(require, "conform")

if has_conform then
	conform.setup({
		formatters_by_ft = {
			javascript = {
				"prettier",
			},

			typescript = {
				"prettier",
			},

			javascriptreact = {
				"prettier",
			},

			typescriptreact = {
				"prettier",
			},

			css = {
				"prettier",
			},

			html = {
				"prettier",
			},

			json = {
				"prettier",
			},

			markdown = {
				"prettier",
			},

			liquid = {
				"prettier_no_path",
			},
		},

		formatters = {
			prettier_no_path = {
				command = function(ctx)
					local local_prettier = vim.fs.find(
						{
							"node_modules/.bin/prettier",
						},
						{
							path = ctx.dirname,
							upward = true,
						}
					)[1]

					return local_prettier or "prettier"
				end,

				args = function(_, ctx)
					local plugin_path

					local node_modules = vim.fs.find(
						{
							"node_modules",
						},
						{
							path = ctx.dirname,
							upward = true,
						}
					)[1]

					if node_modules then
						local local_plugin =
						    node_modules
						    .. "/@shopify/prettier-plugin-liquid/dist/index.js"

						if vim.uv.fs_stat(local_plugin) then
							plugin_path = local_plugin
						end
					end

					if not plugin_path
					    and vim.fn.executable("npm") == 1 then
						local global_root =
						    vim.trim(
							    vim.fn.system({
								    "npm",
								    "root",
								    "-g",
							    })
						    )

						if global_root ~= "" then
							local global_plugin =
							    global_root
							    .. "/@shopify/prettier-plugin-liquid/dist/index.js"

							if vim.uv.fs_stat(global_plugin) then
								plugin_path = global_plugin
							end
						end
					end

					local args = {
						"--stdin-filepath",
						ctx.filename,

						"--parser",
						"liquid-html",
					}

					if plugin_path then
						table.insert(
							args,
							"--plugin"
						)

						table.insert(
							args,
							plugin_path
						)
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

			return {
				timeout_ms = 2000,
				lsp_format = "fallback",
			}
		end,
	})
end


-- ==========================================================================
-- LUASNIP
-- ==========================================================================

local has_luasnip, luasnip =
    pcall(require, "luasnip")

if has_luasnip then
	luasnip.config.setup({
		history = true,
		update_events = "TextChanged,TextChangedI",
	})

	pcall(function()
		require("luasnip.loaders.from_vscode").lazy_load({
			exclude = {
				"javascript",
				"typescript",
				"javascriptreact",
				"typescriptreact",
			},
		})
	end)

	local s = luasnip.snippet
	local fmt = require("luasnip.extras.fmt").fmt
	local i = luasnip.insert_node
	local rep = require("luasnip.extras").rep

	local custom_js_snippets = {

		-- Arrow function
		s(
			"af",
			fmt(
				"({}) => {{\n  {}\n}}",
				{
					i(1, "args"),
					i(0),
				}
			)
		),

		-- Const arrow function
		s(
			"caf",
			fmt(
				"const {} = ({}) => {{\n  {}\n}};",
				{
					i(1, "fnName"),
					i(2, "args"),
					i(0),
				}
			)
		),

		-- Export function
		s(
			"ef",
			fmt(
				"export function {}({}) {{\n  {}\n}}",
				{
					i(1, "functionName"),
					i(2, "args"),
					i(0),
				}
			)
		),

		-- Export const arrow function
		s(
			"eaf",
			fmt(
				"export const {} = ({}) => {{\n  {}\n}};",
				{
					i(1, "functionName"),
					i(2, "args"),
					i(0),
				}
			)
		),

		-- Export const
		s(
			"ec",
			fmt(
				"export const {} = {};",
				{
					i(1, "name"),
					i(0, "value"),
				}
			)
		),

		-- Export default function
		s(
			"edf",
			fmt(
				"export default function {}({}) {{\n  {}\n}}",
				{
					i(1, "functionName"),
					i(2, "args"),
					i(0),
				}
			)
		),

		-- console.log
		s(
			"clg",
			fmt(
				'console.log("{}", {});',
				{
					rep(1),
					i(1, "variable"),
				}
			)
		),

		-- console.error
		s(
			"cle",
			fmt(
				'console.error("{}", {});',
				{
					rep(1),
					i(1, "variable"),
				}
			)
		),

		-- useState
		s(
			"us",
			fmt(
				"const [{}, set{}] = useState({});",
				{
					i(1, "state"),
					i(2, "State"),
					i(3, "null"),
				}
			)
		),

		-- useEffect
		s(
			"ue",
			fmt(
				"useEffect(() => {{\n  {}\n}}, [{}]);",
				{
					i(1),
					i(2),
				}
			)
		),

		-- useRef
		s(
			"ur",
			fmt(
				"const {} = useRef({});",
				{
					i(1, "refName"),
					i(2, "null"),
				}
			)
		),

		-- React component
		s(
			"rafce",
			fmt(
				[[
const {} = () => {{
  return (
    <div>
      {}
    </div>
  );
}};

export default {};
]],
				{
					i(1, "ComponentName"),
					i(0),
					rep(1),
				}
			)
		),

		-- Async arrow function
		s(
			"afc",
			fmt(
				"const {} = async ({}) => {{\n  try {{\n    {}\n  }} catch (error) {{\n    console.error(error);\n  }}\n}};",
				{
					i(1, "fnName"),
					i(2, "args"),
					i(0),
				}
			)
		),
	}

	for _, ft in ipairs({
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
	}) do
		luasnip.add_snippets(
			ft,
			custom_js_snippets
		)
	end
end


-- ==========================================================================
-- GENERAL KEYMAPS
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>u",
	"<Nop>",
	{
		desc = "UI Toggles Group",
	}
)


-- ==========================================================================
-- LIVE SERVER
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>ls",
	"<cmd>LiveServerStart<CR>",
	{
		desc = "Start Live Server",
	}
)

vim.keymap.set(
	"n",
	"<leader>lx",
	"<cmd>LiveServerStop<CR>",
	{
		desc = "Stop Live Server",
	}
)


-- ==========================================================================
-- TMUX NAVIGATION
-- ==========================================================================

vim.keymap.set(
	{ "n", "i", "t" },
	"<C-h>",
	"<cmd>TmuxNavigateLeft<cr>",
	{
		silent = true,
	}
)

vim.keymap.set(
	{ "n", "t" },
	"<C-j>",
	"<cmd>TmuxNavigateDown<cr>",
	{
		silent = true,
	}
)

vim.keymap.set(
	{ "n", "t" },
	"<C-k>",
	"<cmd>TmuxNavigateUp<cr>",
	{
		silent = true,
	}
)

vim.keymap.set(
	{ "n", "i", "t" },
	"<C-l>",
	"<cmd>TmuxNavigateRight<cr>",
	{
		silent = true,
	}
)


-- ==========================================================================
-- WINDOW RESIZE
-- ==========================================================================

vim.keymap.set(
	"n",
	"<C-S-Up>",
	"<cmd>resize +2<CR>",
	{
		desc = "Increase window height",
	}
)

vim.keymap.set(
	"n",
	"<C-S-Down>",
	"<cmd>resize -2<CR>",
	{
		desc = "Decrease window height",
	}
)

vim.keymap.set(
	"n",
	"<C-S-Left>",
	"<cmd>vertical resize -2<CR>",
	{
		desc = "Decrease window width",
	}
)

vim.keymap.set(
	"n",
	"<C-S-Right>",
	"<cmd>vertical resize +2<CR>",
	{
		desc = "Increase window width",
	}
)


-- ==========================================================================
-- WINDOW NAVIGATION
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>wh",
	"<C-w>h",
	{
		desc = "Go to left window",
	}
)

vim.keymap.set(
	"n",
	"<leader>wj",
	"<C-w>j",
	{
		desc = "Go to lower window",
	}
)

vim.keymap.set(
	"n",
	"<leader>wk",
	"<C-w>k",
	{
		desc = "Go to upper window",
	}
)

vim.keymap.set(
	"n",
	"<leader>wl",
	"<C-w>l",
	{
		desc = "Go to right window",
	}
)


-- ==========================================================================
-- BUFFER / TAB NAVIGATION
-- ==========================================================================

vim.keymap.set(
	"n",
	"H",
	"<cmd>bprevious<cr>",
	{
		desc = "Go to previous file tab",
	}
)

vim.keymap.set(
	"n",
	"L",
	"<cmd>bnext<cr>",
	{
		desc = "Go to next file tab",
	}
)

vim.keymap.set(
	"n",
	"<leader>co",
	"<cmd>%bd|e#|bd#<cr>",
	{
		desc = "Close all other file tabs",
	}
)


vim.keymap.set("n", "<leader>x", function()
	local current_buf =
	    vim.api.nvim_get_current_buf()

	local alternate_buf =
	    vim.fn.bufnr("#")

	if alternate_buf > 0
	    and vim.api.nvim_buf_is_valid(alternate_buf)
	    and vim.bo[alternate_buf].buflisted
	then
		vim.cmd("buffer #")
	else
		vim.cmd("bnext")
	end

	if vim.api.nvim_get_current_buf() ~= current_buf then
		vim.cmd("bdelete " .. current_buf)
	else
		vim.cmd("enew")
		vim.cmd("bdelete " .. current_buf)
	end
end, {
	desc = "Close current file tab safely",
})


-- ==========================================================================
-- MOVE LINES
-- ==========================================================================

vim.keymap.set(
	"n",
	"<A-Down>",
	"<cmd>m .+1<cr>==",
	{
		desc = "Move line down",
	}
)

vim.keymap.set(
	"n",
	"<A-Up>",
	"<cmd>m .-2<cr>==",
	{
		desc = "Move line up",
	}
)

vim.keymap.set(
	"v",
	"<A-Down>",
	":m '>+1<cr>gv=gv",
	{
		silent = true,
		desc = "Move visual block down",
	}
)

vim.keymap.set(
	"v",
	"<A-Up>",
	":m '<-2<cr>gv=gv",
	{
		silent = true,
		desc = "Move visual block up",
	}
)


-- ==========================================================================
-- SEARCH / INDENT
-- ==========================================================================

vim.keymap.set(
	"v",
	"<",
	"<gv",
	{
		desc = "Indent left and preserve visual selection",
	}
)

vim.keymap.set(
	"v",
	">",
	">gv",
	{
		desc = "Indent right and preserve visual selection",
	}
)

vim.keymap.set(
	"n",
	"<leader>ch",
	"<cmd>nohlsearch<cr>",
	{
		desc = "Clear search highlights",
	}
)

vim.keymap.set(
	"n",
	"n",
	"nzzzv",
	{
		desc = "Next search result centered",
	}
)

vim.keymap.set(
	"n",
	"N",
	"Nzzzv",
	{
		desc = "Previous search result centered",
	}
)


-- ==========================================================================
-- FORMAT
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>=",
	function()
		require("conform").format({
			async = true,
			lsp_format = "fallback",
		})
	end,
	{
		desc = "Format current file",
	}
)


-- Toggle format on save

vim.keymap.set(
	"n",
	"<leader>uf",
	function()
		vim.g.disable_autoformat =
		    not vim.g.disable_autoformat

		vim.notify(
			"Auto-format on save: "
			.. (
				vim.g.disable_autoformat
				and "DISABLED"
				or "ENABLED"
			)
		)
	end,
	{
		desc = "Toggle Auto-Format on Save",
	}
)


-- ==========================================================================
-- TERMINAL
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>th",
	"<cmd>split | terminal<CR>",
	{
		desc = "Open terminal (Horizontal Split)",
	}
)

vim.keymap.set(
	"n",
	"<leader>tv",
	"<cmd>vsplit | terminal<CR>",
	{
		desc = "Open terminal (Vertical Split)",
	}
)

vim.keymap.set(
	"t",
	"<Esc><Esc>",
	[[<C-\><C-n>]],
	{
		desc = "Exit terminal mode to normal mode",
	}
)


-- ==========================================================================
-- LAZYGIT ESC FIX
-- ==========================================================================

vim.api.nvim_create_autocmd(
	"TermOpen",
	{
		pattern = "term://*lazygit*",

		callback = function()
			vim.keymap.set(
				"t",
				"<Esc>",
				"<Esc>",
				{
					buffer = true,
					nowait = true,
				}
			)

			vim.keymap.set(
				"t",
				"<Esc><Esc>",
				"<Esc><Esc>",
				{
					buffer = true,
					nowait = true,
				}
			)
		end,
	}
)


-- ==========================================================================
-- NAVIC
-- ==========================================================================

local has_navic, navic =
    pcall(require, "nvim-navic")

if has_navic then
	navic.setup({
		lsp = {
			auto_attach = true,

			-- vtsls is the only TypeScript server used.
			preference = {
				"vtsls",
			},
		},

		highlight = true,
		separator = " > ",
	})
end


-- ==========================================================================
-- NVIM-CMP
-- ==========================================================================

local has_cmp, cmp =
    pcall(require, "cmp")

if has_cmp then
	cmp.setup({
		completion = {
			autocomplete = {
				cmp.TriggerEvent.TextChanged,
			},
		},

		snippet = {
			expand = function(args)
				if has_luasnip then
					luasnip.lsp_expand(args.body)
				end
			end,
		},

		formatting = {
			format = function(_, item)
				if has_mini_icons then
					local icon =
					    mini_icons.get(
						    "lsp",
						    item.kind
					    )

					if icon then
						item.kind =
						    icon
						    .. " "
						    .. item.kind
					end
				end

				return item
			end,
		},

		mapping = cmp.mapping.preset.insert({
			["<C-j>"] =
			    cmp.mapping.select_next_item(),

			["<C-k>"] =
			    cmp.mapping.select_prev_item(),

			["<C-b>"] =
			    cmp.mapping.scroll_docs(-4),

			["<C-f>"] =
			    cmp.mapping.scroll_docs(4),

			["<C-Space>"] =
			    cmp.mapping.complete(),

			["<C-e>"] =
			    cmp.mapping.abort(),

			["<CR>"] =
			    cmp.mapping.confirm({
				    select = true,
			    }),

			["<Tab>"] =
			    cmp.mapping(function(fallback)
				    if has_luasnip
				        and luasnip.locally_jumpable(1)
				    then
					    luasnip.jump(1)
				    elseif cmp.visible() then
					    cmp.select_next_item()
				    else
					    fallback()
				    end
			    end, {
				    "i",
				    "s",
			    }),

			["<S-Tab>"] =
			    cmp.mapping(function(fallback)
				    if has_luasnip
				        and luasnip.locally_jumpable(-1)
				    then
					    luasnip.jump(-1)
				    elseif cmp.visible() then
					    cmp.select_prev_item()
				    else
					    fallback()
				    end
			    end, {
				    "i",
				    "s",
			    }),
		}),

		sources = cmp.config.sources({
			{
				name = "nvim_lsp",
				priority = 1000,
			},

			{
				name = "luasnip",
				priority = 750,
			},

			{
				name = "path",
				priority = 500,
			},

			{
				name = "buffer",
				priority = 250,
			},

			{
				name = "codecompanion",
			},
		}),
	})
end


-- ==========================================================================
-- 5. TELESCOPE
-- ==========================================================================

local has_telescope, telescope =
    pcall(require, "telescope")

if has_telescope then
	local builtin =
	    require("telescope.builtin")

	vim.keymap.set(
		"n",
		"<leader>ff",
		builtin.find_files,
		{
			desc = "Fuzzy find files",
		}
	)

	vim.keymap.set(
		"n",
		"<leader>fg",
		builtin.live_grep,
		{
			desc = "Live grep project text",
		}
	)

	vim.keymap.set(
		"n",
		"<leader>fb",
		builtin.buffers,
		{
			desc = "Find open buffers",
		}
	)

	vim.keymap.set(
		"n",
		"<leader>fh",
		builtin.help_tags,
		{
			desc = "Search help docs",
		}
	)

	vim.keymap.set(
		"n",
		"<C-p>",
		builtin.find_files,
		{
			desc = "Quick Open File",
		}
	)
end

vim.keymap.set(
	"n",
	"<leader>?",
	"<CMD>nmap<CR>",
	{
		desc = "List all keymaps",
	}
)

-- ==========================================================================
-- VS CODE COMMENT & DUPLICATE SHORTCUTS
-- ==========================================================================

-- Comment / Uncomment (Ctrl + /)
vim.keymap.set("n", "<C-/>", "gcc", {
	remap = true,
	desc = "Toggle comment",
})
vim.keymap.set("v", "<C-/>", "gc", {
	remap = true,
	desc = "Toggle comment",
})
vim.keymap.set("n", "<C-_>", "gcc", {
	remap = true,
	desc = "Toggle comment (terminal fallback)",
})
vim.keymap.set("v", "<C-_>", "gc", {
	remap = true,
	desc = "Toggle comment (terminal fallback)",
})

-- ==========================================================================
-- 6. LSP SETUP & DIAGNOSTICS
-- ==========================================================================

local has_mason, mason =
    pcall(require, "mason")

if has_mason then
	mason.setup()
end


-- Mason manages these servers.
-- vtsls is installed separately through npm.
local has_mason_lsp, mason_lsp =
    pcall(require, "mason-lspconfig")

if has_mason_lsp then
	mason_lsp.setup({
		ensure_installed = {
			"lua_ls",
			"basedpyright",
			"html",
			"cssls",
			"emmet_ls",
			"jsonls",
			"eslint",
			"tailwindcss",
		},

		automatic_enable = false,
	})
end


-- ==========================================================================
-- DIAGNOSTIC SIGNS
-- ==========================================================================

local signs = {
	Error = "󰅚 ",
	Warn = "󰀪 ",
	Hint = "󰌶 ",
	Info = "󰋽 ",
}

for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type

	vim.fn.sign_define(
		hl,
		{
			text = icon,
			texthl = hl,
			numhl = "",
		}
	)
end


vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		spacing = 4,
		source = "if_many",
	},

	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})


-- ==========================================================================
-- DIAGNOSTIC TOGGLE
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>ud",
	function()
		vim.diagnostic.enable(
			not vim.diagnostic.is_enabled()
		)
	end,
	{
		desc = "Toggle Diagnostics Virtual Text",
	}
)


-- ==========================================================================
-- QUICKFIX DIAGNOSTICS
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>q",
	function()
		local qf_exists = false

		for _, win in ipairs(
			vim.fn.getwininfo()
		) do
			if win.quickfix == 1 then
				qf_exists = true
				break
			end
		end

		if qf_exists then
			vim.cmd("cclose")
		else
			vim.diagnostic.setqflist()
		end
	end,
	{
		desc = "Toggle Quickfix Diagnostics List",
	}
)


-- ==========================================================================
-- LSP CAPABILITIES
-- ==========================================================================

local capabilities =
    vim.lsp.protocol.make_client_capabilities()

local has_cmp_lsp, cmp_lsp =
    pcall(require, "cmp_nvim_lsp")

if has_cmp_lsp then
	capabilities =
	    cmp_lsp.default_capabilities(
		    capabilities
	    )
end


-- ==========================================================================
-- LSP ATTACH
-- ==========================================================================

vim.api.nvim_create_autocmd(
	"LspAttach",
	{
		callback = function(args)
			local client =
			    vim.lsp.get_client_by_id(
				    args.data.client_id
			    )

			if not client then
				return
			end

			if has_navic
			    and client.server_capabilities.documentSymbolProvider
			then
				pcall(
					navic.attach,
					client,
					args.buf
				)
			end

			vim.keymap.set(
				"n",
				"grt",
				vim.lsp.buf.type_definition,
				{
					buffer = args.buf,
					desc = "Go to Type Definition",
				}
			)

			vim.keymap.set(
				"n",
				"gl",
				vim.diagnostic.open_float,
				{
					buffer = args.buf,
					desc = "Show error",
				}
			)

			vim.keymap.set(
				"n",
				"[d",
				function()
					vim.diagnostic.jump({
						count = -1,
					})
				end,
				{
					buffer = args.buf,
					desc = "Previous error",
				}
			)

			vim.keymap.set(
				"n",
				"]d",
				function()
					vim.diagnostic.jump({
						count = 1,
					})
				end,
				{
					buffer = args.buf,
					desc = "Next error",
				}
			)
		end,
	}
)


vim.lsp.config(
	"*",
	{
		capabilities = capabilities,
	}
)


-- ==========================================================================
-- LUA LS
-- ==========================================================================

vim.lsp.config(
	"lua_ls",
	{
		settings = {
			Lua = {
				diagnostics = {
					globals = {
						"vim",
					},
				},

				workspace = {
					library =
					    vim.api.nvim_get_runtime_file(
						    "",
						    true
					    ),

					checkThirdParty = false,
				},

				telemetry = {
					enable = false,
				},
			},
		},
	}
)


-- ==========================================================================
-- EMMET
-- ==========================================================================

vim.lsp.config(
	"emmet_ls",
	{
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
	}
)


-- ==========================================================================
-- TAILWIND CSS
-- ==========================================================================

vim.lsp.config(
	"tailwindcss",
	{
		filetypes = {
			"html",
			"css",
			"javascript",
			"typescript",
			"liquid",
		},

		init_options = {
			userLanguages = {
				liquid = "html",
			},
		},
	}
)


-- ==========================================================================
-- CSS
-- ==========================================================================

vim.lsp.config(
	"cssls",
	{
		settings = {
			css = {
				validate = true,

				lint = {
					unknownAtRules = "ignore",
				},
			},
		},
	}
)


-- ==========================================================================
-- ENABLE LSP SERVERS
-- ==========================================================================

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

for _, server in ipairs(servers) do
	vim.lsp.enable(server)
end


-- ==========================================================================
-- 7. HIGHLIGHT ON YANK
-- ==========================================================================

vim.api.nvim_create_autocmd(
	"TextYankPost",
	{
		callback = function()
			vim.hl.on_yank({
				higroup = "IncSearch",
				timeout = 150,
			})
		end,
	}
)


-- ==========================================================================
-- 8. WHICH-KEY
-- ==========================================================================

local has_wk, wk =
    pcall(require, "which-key")

if has_wk then
	wk.setup({
		preset = "modern",
		delay = 300,
	})

	wk.add({
		{
			"<leader>c",
			group = "Code / AI",
		},

		{
			"<leader>f",
			group = "Find / Telescope",
		},

		{
			"<leader>l",
			group = "Live Server / Git",
		},

		{
			"<leader>t",
			group = "Live / Terminal",
		},

		{
			"<leader>u",
			group = "UI / Diagnostics Toggle",
		},

		{
			"<leader>ud",
			desc = "Toggle Diagnostics Virtual Text",
		},

		{
			"<leader>uf",
			desc = "Toggle Auto-Format on Save",
		},

		{
			"<leader>w",
			group = "Window Navigation",
		},
	})
end


vim.keymap.set(
	"n",
	"<leader>k",
	function()
		require("which-key").show({
			global = true,
		})
	end,
	{
		desc = "Show all keymaps",
	}
)


-- LazyGit
vim.keymap.set(
	"n",
	"<leader>lg",
	"<CMD>LazyGit<CR>",
	{
		desc = "Open LazyGit",
	}
)


-- ==========================================================================
-- 9. LOCAL LLM / VECTORCODE / CODECOMPANION
-- ==========================================================================

-- Find the project root: nearest folder with .vectorcode, else .git, else cwd.
local function vectorcode_project_root()
	local start = vim.api.nvim_buf_get_name(0)

	if start == "" or vim.bo.buftype ~= "" then
		start = vim.fn.getcwd()
	end

	local found = vim.fs.root(start, { ".vectorcode" })
	    or vim.fs.root(start, { ".git" })
	    or vim.fn.getcwd()

	return (vim.fn.fnamemodify(found, ":p"):gsub("/$", ""))
end


local function vectorcode_rag_prompt(message)
	local marker = "RAG:"

	if not message:find(marker, 1, true) then
		return message
	end

	local query = vim.trim((
		message:gsub("^%s*" .. vim.pesc(marker) .. "%s*", "", 1)
	))

	if query == "" then
		return message
	end

	if vim.fn.executable("vectorcode") ~= 1 then
		vim.notify(
			"vectorcode is not on PATH.",
			vim.log.levels.ERROR,
			{ title = "CodeCompanion RAG" }
		)

		return "RAG FAILED. VectorCode is not installed.\n\nUSER QUESTION: " .. query
	end

	local project_root = vectorcode_project_root()

	local ok, result = pcall(function()
		return vim.system(
			{
				"vectorcode",
				"--project_root",
				project_root,
				"--no_stderr",
				"query",
				"-n",
				"5",
				query,
			},
			{
				cwd = project_root,
				text = true,
			}
		):wait(120000)
	end)

	if not ok or not result then
		vim.notify(
			"VectorCode could not be started:\n" .. tostring(result),
			vim.log.levels.ERROR,
			{ title = "CodeCompanion RAG" }
		)

		return "RAG FAILED. VectorCode could not query the repository.\n\nUSER QUESTION: " .. query
	end

	local retrieved = vim.trim(result.stdout or "")

	-- VectorCode can segfault on exit AFTER printing valid results,
	-- so only treat a non-zero exit as failure when nothing came back.
	if retrieved == "" then
		if result.code ~= 0 then
			local stderr = vim.trim(result.stderr or "")

			vim.notify(
				"VectorCode query failed (exit "
				.. tostring(result.code)
				.. ")\nProject: "
				.. project_root
				.. (stderr ~= "" and ("\n" .. stderr) or ""),
				vim.log.levels.ERROR,
				{ title = "CodeCompanion RAG" }
			)

			return "RAG FAILED. VectorCode could not query the repository.\n\nUSER QUESTION: " .. query
		end

		vim.notify(
			"No VectorCode results.\nProject: "
			.. project_root
			.. "\nRun llm-rag-index in that folder.",
			vim.log.levels.WARN,
			{ title = "CodeCompanion RAG" }
		)

		return "RAG returned no indexed repository context.\n\nUSER QUESTION: " .. query
	end

	vim.notify(
		"RAG retrieved " .. tostring(#retrieved) .. " characters of context",
		vim.log.levels.INFO,
		{ title = "CodeCompanion RAG" }
	)

	return table.concat({
		"RAG REPOSITORY CONTEXT",
		"======================",
		"Use the following retrieved repository context as the source of truth.",
		"Do not invent repository facts that are not present below.",
		"",
		retrieved,
		"",
		"USER QUESTION",
		"=============",
		query,
	}, "\n")
end


-- ==========================================================================
-- CODECOMPANION
-- ==========================================================================

require("codecompanion").setup({
	display = {
		action_palette = {
			provider = "telescope",
		},

		diff = {
			enabled = true,
		},

		chat = {
			show_token_count = true,
		},

		inline = {
			layout = "vertical",
		},
	},

	rules = {
		project = {
			description = "Project instructions and current project context",
			files = {
				"AGENTS.md",
				".agent_context.md",
			},
		},
		opts = {
			chat = {
				autoload = "project",
				enabled = true,
				autoload_groups_in_prompt_library = true,
			},
		},
	},

	prompt_library = {

		["Generate Unit Tests"] = {
			interaction = "chat",

			description =
			"Generate unit tests for selected code",

			opts = {
				modes = {
					"v",
				},

				alias = "tests",
				auto_submit = true,
			},

			prompts = {
				{
					role = "system",

					content =
					"You are an expert software engineer specialized in unit testing.",
				},

				{
					role = "user",

					content =
					    "Write comprehensive unit tests for the selected code block. "
					    .. "Cover edge cases and mock dependencies.",
				},
			},
		},

		["Refactor Code"] = {
			interaction = "inline",

			description =
			"Refactor selected code for performance & readability",

			opts = {
				modes = {
					"v",
				},

				alias = "refactor",
				auto_submit = true,
			},

			prompts = {
				{
					role = "user",

					content =
					    "Refactor this code to optimize performance and readability "
					    .. "while preserving exact behavior.",
				},
			},
		},
	},

	interactions = {

		chat = {
			adapter = "ollama_agent",

			system_prompt = function(_)
				return [[
You are an expert Senior Software Engineer and Code Repair Assistant.

Rules:
- State the root cause of bugs concisely before showing code.
- Output raw, executable code blocks only.
- Do not add line numbers, digits, or vertical pipe symbols (|) at the beginning of code lines.
- Make the smallest correct, production-quality change.
- Always preserve existing coding styles and return types.
- Never modify unrelated code or invent non-existent APIs.
- If missing context prevents an accurate fix, explicitly ask for the missing definitions.
- When the user message begins with "RAG:", use ONLY the retrieved repository context supplied in that message.
- Do not invent repository facts when RAG context is present.
- Treat AGENTS.md and .agent_context.md loaded as CodeCompanion rules as project-specific source material.
- If a project fact is not supported by the loaded rules, retrieved RAG context, or the actual files/tools available in the chat, say that it is not confirmed instead of inventing it.
]]
			end,

			tools = {
				opts = {
					auto_submit_errors = true,
					auto_submit_success = true,
				},
			},

			opts = {
				collapse_tools = false,

				prompt_decorator = function(
				    message
				)
					return vectorcode_rag_prompt(
						message
					)
				end,
			},
		},

		inline = {
			adapter = "ollama_inline",
		},

		shared = {
			keymaps = {
				accept_change = {
					callback = "keymaps.accept_change",
					modes = {
						n = "ga",
					},
					description = "Accept AI change",
				},

				reject_change = {
					callback = "keymaps.reject_change",
					modes = {
						n = "gr",
					},
					opts = {
						nowait = true,
					},
					description = "Reject AI change",
				},
			},
		},

		cmd = {
			adapter = "ollama_inline",
		},

		background = {
			adapter = "ollama_inline",
		},
	},

	-- VectorCode integration
	extensions = {

		vectorcode = {
			opts = {

				tool_group = {
					enabled = true,
					extras = {},
					collapse = false,
				},

				tool_opts = {

					["*"] = {
						use_lsp = false,
					},

					query = {
						max_num = {
							chunk = -1,
							document = 10,
						},

						default_num = {
							chunk = 50,
							document = 5,
						},

						include_stderr = false,
						use_lsp = false,
						no_duplicate = false,
						chunk_mode = false,

						summarise = {
							enabled = false,
							adapter = nil,
							query_augmented = true,
						},
					},

					vectorise = {
						require_approval_before = true,
					},
				},
			},
		},

		spinner = {
			enabled = true,

			opts = {
				style = "cursor-relative",
			},
		},
	},


	-- ==========================================================================
	-- CODECOMPANION ADAPTERS
	-- ==========================================================================

	adapters = {

		http = {

			ollama_agent = function()
				return require(
					"codecompanion.adapters"
				).extend(
					"ollama",
					{
						env = {
							name = "Qwen2.5 Agent",
						},

						schema = {
							model = {
								default =
								"qwen2.5-agent",
							},
						},
					}
				)
			end,


			ollama_inline = function()
				return require(
					"codecompanion.adapters"
				).extend(
					"ollama",
					{
						env = {
							name = "Qwen2.5 Inline",
						},

						schema = {
							model = {
								default =
								"qwen2.5-inline",
							},
						},
					}
				)
			end,


			minicpm = function()
				return require(
					"codecompanion.adapters"
				).extend(
					"openai",
					{
						name = "minicpm",

						env = {
							url =
							"http://127.0.0.1:8000/v1",

							api_key = "dummy",
						},

						schema = {
							model = {
								default =
								"openbmb/MiniCPM5-1B",
							},
						},
					}
				)
			end,
		},
	},
})


-- ==========================================================================
-- CODECOMPANION KEYMAPS
-- ==========================================================================

vim.keymap.set(
	{ "n", "x" },
	"<leader>cc",
	"<cmd>CodeCompanionChat Toggle<CR>",
	{
		desc = "Toggle AI Chat Agent",
	}
)

vim.keymap.set(
	"n",
	"<leader>ci",
	"<cmd>CodeCompanion<CR>",
	{
		desc = "Inline AI Fix/Transform",
	}
)

vim.keymap.set(
	"x",
	"<leader>ci",
	":CodeCompanion<CR>",
	{
		desc = "Inline AI Fix/Transform Selection",
	}
)

vim.keymap.set(
	"n",
	"<leader>ca",
	"<cmd>CodeCompanionActions<CR>",
	{
		desc = "AI Action Palette",
	}
)

vim.keymap.set(
	"x",
	"<leader>ca",
	":CodeCompanionActions<CR>",
	{
		desc = "AI Action Palette Selection",
	}
)


-- ==========================================================================
-- AI EXPLAIN CURRENT LSP ERROR
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>cd",
	function()
		local diagnostics =
		    vim.diagnostic.get(
			    0,
			    {
				    lnum =
				        vim.fn.line(".") - 1,
			    }
		    )

		if #diagnostics == 0 then
			vim.notify(
				"No LSP diagnostics on current line.",
				vim.log.levels.WARN
			)

			return
		end

		local err_msg =
		    diagnostics[1].message

		vim.cmd(
			"CodeCompanionChat Toggle"
		)

		vim.schedule(function()
			vim.cmd(
				"CodeCompanion /explain Why am I getting this LSP error: "
				.. err_msg
			)
		end)
	end,
	{
		desc = "AI Explain LSP Error on Current Line",
	}
)


-- ==========================================================================
-- 10. CODECOMPANION AUTO HOOKS
-- ==========================================================================

local inline_group =
    vim.api.nvim_create_augroup(
	    "CodeCompanionInlineHooks",
	    {
		    clear = true,
	    }
    )


vim.api.nvim_create_autocmd(
	"User",
	{
		pattern = "CodeCompanionInlineFinished",

		group = inline_group,

		callback = function(request)
			vim.schedule(function()
				vim.notify(
					"AI Inline generation complete! "
					.. "Use 'ga' to accept or 'gr' to reject changes.",
					vim.log.levels.INFO
				)
			end)
		end,
	}
)


-- ==========================================================================
-- AUTOMATIC AI BUFFER CLEANER
-- ==========================================================================

local ai_cleaner_group =
    vim.api.nvim_create_augroup(
	    "CodeCompanionCleanOutput",
	    {
		    clear = true,
	    }
    )


vim.api.nvim_create_autocmd(
	"User",
	{
		pattern = {
			"CodeCompanionChatFinished",
			"CodeCompanionInlineFinished",
		},

		group = ai_cleaner_group,

		callback = function(request)
			local buf =
			    request.buf
			    or vim.api.nvim_get_current_buf()

			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end

			local lines =
			    vim.api.nvim_buf_get_lines(
				    buf,
				    0,
				    -1,
				    false
			    )

			local cleaned_lines = {}
			local modified = false

			for _, line in ipairs(lines) do
				local cleaned, replacements =
				    line:gsub(
					    "^%s*%d+%s*|%s?",
					    ""
				    )

				if replacements > 0 then
					modified = true

					table.insert(
						cleaned_lines,
						cleaned
					)
				else
					table.insert(
						cleaned_lines,
						line
					)
				end
			end

			if modified then
				vim.api.nvim_buf_set_lines(
					buf,
					0,
					-1,
					false,
					cleaned_lines
				)
			end
		end,
	}
)


-- ==========================================================================
-- CODECOMPANION BUFFER SETTINGS
-- ==========================================================================

vim.api.nvim_create_autocmd(
	"FileType",
	{
		pattern = "codecompanion",

		callback = function(args)
			-- Disable line numbers/signs
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.signcolumn = "no"
			vim.opt_local.foldcolumn = "0"


			-- ---------------------------------------------------------------
			-- Copy code block under cursor
			-- ---------------------------------------------------------------

			vim.keymap.set(
				"n",
				"gy",
				function()
					local cursor_line =
					    vim.api.nvim_win_get_cursor(0)[1]

					local lines =
					    vim.api.nvim_buf_get_lines(
						    args.buf,
						    0,
						    -1,
						    false
					    )


					-- Find code blocks
					local blocks = {}
					local current_start = nil

					for i, line in ipairs(lines) do
						if line:match("^%s*```") then
							if not current_start then
								current_start = i
							else
								table.insert(
									blocks,
									{
										start_line = current_start,
										end_line = i,
									}
								)

								current_start = nil
							end
						end
					end


					-- Find block under cursor
					local target_block = nil

					for _, block in ipairs(blocks) do
						if cursor_line >= block.start_line
						    and cursor_line <= block.end_line
						then
							target_block = block
							break
						end
					end


					if target_block then
						local start_idx =
						    target_block.start_line + 1

						local end_idx =
						    target_block.end_line - 1


						if start_idx <= end_idx then
							local code_lines =
							    vim.api.nvim_buf_get_lines(
								    args.buf,
								    start_idx - 1,
								    end_idx,
								    false
							    )


							-- Remove line numbers
							local cleaned_lines = {}

							for _, line in ipairs(code_lines) do
								local cleaned =
								    line:gsub(
									    "^%s*%d+[%s|:]*",
									    ""
								    )

								table.insert(
									cleaned_lines,
									cleaned
								)
							end


							local code_text =
							    table.concat(
								    cleaned_lines,
								    "\n"
							    )


							-- Copy to clipboard
							vim.fn.setreg(
								"+",
								code_text
							)


							-- Flash selection
							local ns =
							    vim.api.nvim_create_namespace(
								    "gy_flash"
							    )

							vim.hl.range(
								args.buf,
								ns,
								"IncSearch",
								{
									start_idx - 1,
									0,
								},
								{
									end_idx - 1,
									#lines[end_idx],
								}
							)


							vim.defer_fn(
								function()
									if vim.api.nvim_buf_is_valid(
										    args.buf
									    ) then
										vim.api.nvim_buf_clear_namespace(
											args.buf,
											ns,
											0,
											-1
										)
									end
								end,
								150
							)


							vim.notify(
								"Copied code block under cursor (cleaned)!",
								vim.log.levels.INFO
							)
						else
							vim.notify(
								"Code block under cursor is empty.",
								vim.log.levels.WARN
							)
						end
					else
						vim.notify(
							"Cursor is not inside a code block.",
							vim.log.levels.WARN
						)
					end
				end,
				{
					buffer = args.buf,
					remap = false,
					silent = true,

					desc =
					"Yank code block under cursor without line numbers",
				}
			)


			-- Jump back to code file
			vim.keymap.set(
				"n",
				"<leader>cf",
				function()
					vim.cmd("wincmd p")
				end,
				{
					buffer = args.buf,
					silent = true,

					desc =
					"Jump back to code file",
				}
			)
		end,
	}
)


-- ==========================================================================
-- GLOBAL CODECOMPANION FOCUS
-- ==========================================================================

vim.keymap.set(
	"n",
	"<leader>cf",
	function()
		local wins =
		    vim.api.nvim_list_wins()

		for _, win in ipairs(wins) do
			local buf =
			    vim.api.nvim_win_get_buf(win)

			if vim.bo[buf].filetype
			    == "codecompanion"
			then
				vim.api.nvim_set_current_win(
					win
				)

				return
			end
		end

		vim.notify(
			"CodeCompanion chat window is not open.",
			vim.log.levels.WARN
		)
	end,
	{
		silent = true,
		desc = "Jump focus to CodeCompanion",
	}
)
