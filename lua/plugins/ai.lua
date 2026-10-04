-- ==========================================================================
-- AI: CODECOMPANION + VECTORCODE RAG (local Ollama, optional Claude)
-- ==========================================================================
-- Two separate switches, matching the shell:
--   Local : `ai-on` / `ai-off` in the terminal (starts/stops the ollama service)
--   Claude: `:ClaudeOn` / `:ClaudeOff` inside Neovim
--
-- Chat (<leader>cc, RAG:, <leader>cd) uses Claude while :ClaudeOn is active,
-- otherwise the local Qwen model on the RTX 4060.
-- Inline (<leader>ci) and the action palette always use the local model:
-- Claude Code runs as an agent over ACP and only works in the chat buffer.

local ok, codecompanion = pcall(require, "codecompanion")
if not ok then
	return
end

local CLAUDE_ADAPTER = "claude_code"
local LOCAL_CHAT_ADAPTER = "ollama_agent"
local CLAUDE_TOKEN_FILE = vim.fn.expand("~/.config/codecompanion/claude_token")

vim.g.ai_backend = vim.g.ai_backend or "local"

local map = vim.keymap.set

local function notify(msg, level, title)
	vim.notify(msg, level or vim.log.levels.INFO, { title = title or "AI" })
end

-- --------------------------------------------------------------------------
-- VectorCode RAG ("RAG: <question>" in the chat)
-- --------------------------------------------------------------------------

-- Nearest folder with .vectorcode, else .git, else cwd.
local function vectorcode_project_root()
	local start = vim.api.nvim_buf_get_name(0)
	if start == "" or vim.bo.buftype ~= "" then
		start = vim.fn.getcwd()
	end

	local found = vim.fs.root(start, { ".vectorcode" }) or vim.fs.root(start, { ".git" }) or vim.fn.getcwd()
	return (vim.fn.fnamemodify(found, ":p"):gsub("/$", ""))
end

local function vectorcode_rag_prompt(message)
	local marker = "RAG:"
	if not message:find(marker, 1, true) then
		return message
	end

	local query = vim.trim((message:gsub("^%s*" .. vim.pesc(marker) .. "%s*", "", 1)))
	if query == "" then
		return message
	end

	local failed = "RAG FAILED. VectorCode could not query the repository.\n\nUSER QUESTION: " .. query

	if vim.fn.executable("vectorcode") ~= 1 then
		notify("vectorcode is not on PATH.", vim.log.levels.ERROR, "CodeCompanion RAG")
		return "RAG FAILED. VectorCode is not installed.\n\nUSER QUESTION: " .. query
	end

	local project_root = vectorcode_project_root()

	local ran, result = pcall(function()
		return vim.system(
			{ "vectorcode", "--project_root", project_root, "--no_stderr", "query", "-n", "5", query },
			{ cwd = project_root, text = true }
		):wait(120000)
	end)

	if not ran or not result then
		notify("VectorCode could not be started:\n" .. tostring(result), vim.log.levels.ERROR, "CodeCompanion RAG")
		return failed
	end

	local retrieved = vim.trim(result.stdout or "")

	-- VectorCode can segfault on exit AFTER printing valid results,
	-- so only treat a non-zero exit as failure when nothing came back.
	if retrieved == "" then
		if result.code ~= 0 then
			local stderr = vim.trim(result.stderr or "")
			-- Queries need both the Chroma server (port 8100) and Ollama,
			-- which embeds the question even when chat runs on Claude.
			notify(
				("VectorCode query failed (exit %d)\nProject: %s%s\n\nCheck: ai-status (Ollama) and rag-db-status (ChromaDB)"):format(
					result.code,
					project_root,
					stderr ~= "" and ("\n" .. stderr) or ""
				),
				vim.log.levels.ERROR,
				"CodeCompanion RAG"
			)
			return failed
		end

		notify(
			"No VectorCode results.\nProject: "
				.. project_root
				.. "\nIn that folder run: llm-rag-config (first time only), then llm-rag-index.",
			vim.log.levels.WARN,
			"CodeCompanion RAG"
		)
		return "RAG returned no indexed repository context.\n\nUSER QUESTION: " .. query
	end

	notify("RAG retrieved " .. #retrieved .. " characters of context", vim.log.levels.INFO, "CodeCompanion RAG")

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

-- --------------------------------------------------------------------------
-- Backend switch (local Ollama vs Claude)
-- --------------------------------------------------------------------------

local function ollama_running()
	local ran, result = pcall(function()
		return vim.system({ "systemctl", "is-active", "--quiet", "ollama" }, { text = true }):wait(2000)
	end)
	return ran and result and result.code == 0
end

-- Load the Claude Pro OAuth token (from `claude setup-token`) without
-- hard-coding it in this file. An exported CLAUDE_CODE_OAUTH_TOKEN wins.
local function load_claude_token()
	if vim.env.CLAUDE_CODE_OAUTH_TOKEN and vim.env.CLAUDE_CODE_OAUTH_TOKEN ~= "" then
		return true
	end

	if vim.uv.fs_stat(CLAUDE_TOKEN_FILE) then
		local token = vim.trim(table.concat(vim.fn.readfile(CLAUDE_TOKEN_FILE), ""))
		if token ~= "" then
			vim.env.CLAUDE_CODE_OAUTH_TOKEN = token
			return true
		end
	end

	return false
end

local function set_chat_adapter(name)
	local ok_config, cc_config = pcall(require, "codecompanion.config")
	if ok_config and cc_config.interactions and cc_config.interactions.chat then
		cc_config.interactions.chat.adapter = name
	end
end

local function find_chat_window()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "codecompanion" then
			return win
		end
	end
end

-- Returns true when the backend needed for this action is switched on.
-- kind = "chat" or "inline"
local function ai_ready(kind)
	if kind == "chat" and vim.g.ai_backend == "claude" then
		return true
	end

	if ollama_running() then
		return true
	end

	if kind == "inline" and vim.g.ai_backend == "claude" then
		notify(
			"Inline edits use the local model. Run ai-on, or ask Claude in chat (<leader>cc).",
			vim.log.levels.WARN
		)
	else
		notify("🔒 AI is OFF — run ai-on (local) or :ClaudeOn (Claude).", vim.log.levels.WARN)
	end

	return false
end

vim.api.nvim_create_user_command("ClaudeOn", function()
	if vim.fn.executable("claude-agent-acp") ~= 1 then
		notify(
			"claude-agent-acp not found.\nInstall: npm install -g @zed-industries/claude-agent-acp",
			vim.log.levels.ERROR,
			"Claude"
		)
		return
	end

	if not load_claude_token() then
		notify(
			"No Claude token.\nRun `claude setup-token` and save it to:\n" .. CLAUDE_TOKEN_FILE,
			vim.log.levels.ERROR,
			"Claude"
		)
		return
	end

	vim.g.ai_backend = "claude"
	set_chat_adapter(CLAUDE_ADAPTER)

	notify(
		"Claude ON — new chats use Claude Code (Pro).\n"
			.. "An already-open chat keeps its model: <leader>cn starts a new one."
	)
end, { desc = "Use Claude Code for AI chat" })

vim.api.nvim_create_user_command("ClaudeOff", function()
	vim.g.ai_backend = "local"
	set_chat_adapter(LOCAL_CHAT_ADAPTER)

	notify("Claude OFF — new chats use the local model" .. (ollama_running() and "." or " (Ollama is off: run ai-on)."))
end, { desc = "Use the local Ollama model for AI chat" })

vim.api.nvim_create_user_command("AiStatus", function()
	notify(
		"Chat backend : "
			.. (vim.g.ai_backend == "claude" and "Claude Code" or "Local (Qwen)")
			.. "\nOllama       : "
			.. (ollama_running() and "running" or "off")
			.. "\nInline       : Local (Qwen)"
	)
end, { desc = "Show which AI backend is active" })

-- --------------------------------------------------------------------------
-- CodeCompanion
-- --------------------------------------------------------------------------

-- Chat and inline share one model so only one copy of the weights (6 GB) is
-- ever loaded; switching between two tags of the same model makes Ollama
-- unload and reload it. Temperature is a per-request option, so it doesn't
-- force a reload.
local function ollama_adapter(name, temperature)
	return function()
		return require("codecompanion.adapters").extend("ollama", {
			env = { name = name },
			schema = {
				model = { default = "qwen3.5-agent" },
				temperature = { default = temperature },
				-- Qwen3.5 thinks by default: slower and scored worse on stack questions
				think = { default = false },
			},
		})
	end
end

-- Stack cheat sheets (ai/rules/*.md): the local model's training predates
-- Next 16, Prisma 7, Zod 4 and the React Router Shopify template, so the
-- matching sheet is loaded into every chat in that kind of project.
local STACK_RULES = vim.fn.stdpath("config") .. "/ai/rules/"

local function project_has(markers)
	return vim.fs.root(vectorcode_project_root(), markers) ~= nil
end

local function is_nextjs_project()
	local pkg = vim.fs.find("package.json", { upward = true, path = vectorcode_project_root() })[1]
	if not pkg then
		return false
	end
	local okj, json = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), "\n"))
	local deps = okj and type(json) == "table" and vim.tbl_extend("force", json.dependencies or {}, json.devDependencies or {}) or {}
	return deps.next ~= nil
end

codecompanion.setup({
	display = {
		action_palette = { provider = "telescope" },
		diff = { enabled = true },
		chat = { show_token_count = true },
		inline = { layout = "vertical" },
	},

	rules = {
		project = {
			description = "Project instructions and current project context",
			files = { "AGENTS.md", ".agent_context.md" },
		},
		nextjs = {
			description = "Next.js 16 / Prisma 7 / Tailwind 4 / Zod 4 / Auth.js v5 facts",
			files = { STACK_RULES .. "nextjs.md" },
		},
		shopify = {
			description = "Shopify React Router app template facts",
			files = { STACK_RULES .. "shopify.md" },
		},
		opts = {
			chat = {
				autoload = function()
					local groups = { "project" }
					if project_has({ "shopify.app.toml" }) then
						table.insert(groups, "shopify")
					elseif is_nextjs_project() then
						table.insert(groups, "nextjs")
					end
					return groups
				end,
				enabled = true,
				autoload_groups_in_prompt_library = true,
			},
		},
	},

	prompt_library = {
		["Generate Unit Tests"] = {
			interaction = "chat",
			description = "Generate unit tests for selected code",
			opts = { modes = { "v" }, alias = "tests", auto_submit = true },
			prompts = {
				{
					role = "system",
					content = "You are an expert software engineer specialized in unit testing.",
				},
				{
					role = "user",
					content = "Write comprehensive unit tests for the selected code block. "
						.. "Cover edge cases and mock dependencies.",
				},
			},
		},

		["Refactor Code"] = {
			interaction = "inline",
			description = "Refactor selected code for performance & readability",
			opts = { modes = { "v" }, alias = "refactor", auto_submit = true },
			prompts = {
				{
					role = "user",
					content = "Refactor this code to optimize performance and readability "
						.. "while preserving exact behavior.",
				},
			},
		},
	},

	interactions = {
		chat = {
			adapter = LOCAL_CHAT_ADAPTER,

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
- "Stack facts" rules describe the exact library versions in this project. They override your training data: never fall back to older APIs they mark as wrong.
- If a project fact is not supported by the loaded rules, retrieved RAG context, or the actual files/tools available in the chat, say that it is not confirmed instead of inventing it.
]]
			end,

			tools = {
				opts = {
					auto_submit_errors = true,
					auto_submit_success = true,
				},
			},

			keymaps = {
				-- Default is "ga", which clashes with "ga" = accept change.
				change_adapter = { modes = { n = "gA" } },
			},

			opts = {
				collapse_tools = false,
				prompt_decorator = vectorcode_rag_prompt,
			},
		},

		inline = { adapter = "ollama_inline" },
		cmd = { adapter = "ollama_inline" },
		background = { adapter = "ollama_inline" },

		shared = {
			keymaps = {
				accept_change = {
					callback = "keymaps.accept_change",
					modes = { n = "ga" },
					description = "Accept AI change",
				},
				reject_change = {
					callback = "keymaps.reject_change",
					modes = { n = "gr" },
					opts = { nowait = true },
					description = "Reject AI change",
				},
			},
		},
	},

	extensions = {
		vectorcode = {
			opts = {
				tool_group = {
					enabled = true,
					extras = {},
					collapse = false,
				},
				tool_opts = {
					["*"] = { use_lsp = false },
					query = {
						max_num = { chunk = -1, document = 10 },
						default_num = { chunk = 50, document = 5 },
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
					vectorise = { require_approval_before = true },
				},
			},
		},

		spinner = {
			enabled = true,
			opts = { style = "cursor-relative" },
		},
	},

	adapters = {
		-- Claude Code over ACP (uses your Claude Pro login, no API key).
		-- Needs: npm install -g @zed-industries/claude-agent-acp
		-- Token: `claude setup-token` -> ~/.config/codecompanion/claude_token
		acp = {
			claude_code = function()
				return require("codecompanion.adapters").extend("claude_code", {
					defaults = { timeout = 60000 },
				})
			end,
		},

		http = {
			ollama_agent = ollama_adapter("Qwen3.5 Agent", 0.2),
			ollama_inline = ollama_adapter("Qwen3.5 Inline", 0.1),
		},
	},
})

-- --------------------------------------------------------------------------
-- Keymaps
-- --------------------------------------------------------------------------

-- Closing an open chat always works; opening needs a backend on.
map({ "n", "x" }, "<leader>cc", function()
	if find_chat_window() or ai_ready("chat") then
		vim.cmd("CodeCompanionChat Toggle")
	end
end, { desc = "Toggle AI chat" })

-- Fresh chat with the current backend (use after :ClaudeOn / :ClaudeOff).
map("n", "<leader>cn", function()
	if ai_ready("chat") then
		vim.cmd("CodeCompanionChat")
	end
end, { desc = "New AI chat (current backend)" })

map("n", "<leader>cs", "<cmd>AiStatus<cr>", { desc = "AI backend status" })

map("n", "<leader>ct", function()
	vim.cmd(vim.g.ai_backend == "claude" and "ClaudeOff" or "ClaudeOn")
end, { silent = true, desc = "Toggle Claude / local AI backend" })

map("n", "<leader>ci", function()
	if ai_ready("inline") then
		vim.cmd("CodeCompanion")
	end
end, { desc = "Inline AI fix/transform" })

map("x", "<leader>ci", function()
	if ai_ready("inline") then
		vim.api.nvim_feedkeys(":CodeCompanion\r", "n", false)
	end
end, { desc = "Inline AI fix/transform selection" })

map("n", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "AI action palette" })
map("x", "<leader>ca", ":CodeCompanionActions<cr>", { desc = "AI action palette (selection)" })

-- One new chat with the question already sent.
map("n", "<leader>cd", function()
	local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
	if #diagnostics == 0 then
		notify("No LSP diagnostics on current line.", vim.log.levels.WARN)
		return
	end

	if not ai_ready("chat") then
		return
	end

	codecompanion.chat({
		user_prompt = ("Why am I getting this LSP error in %s line %d?\n\nCode: %s\nError: %s"):format(
			vim.fn.expand("%:."),
			vim.fn.line("."),
			vim.trim(vim.api.nvim_get_current_line()),
			(diagnostics[1].message:gsub("\n", " "))
		),
	})
end, { desc = "AI explain LSP error on current line" })

map("n", "<leader>cf", function()
	local win = find_chat_window()
	if win then
		vim.api.nvim_set_current_win(win)
	else
		notify("CodeCompanion chat window is not open.", vim.log.levels.WARN)
	end
end, { silent = true, desc = "Focus AI chat" })

-- --------------------------------------------------------------------------
-- Autocommands
-- --------------------------------------------------------------------------

local group = vim.api.nvim_create_augroup("user_codecompanion", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "CodeCompanionInlineFinished",
	callback = function()
		vim.schedule(function()
			notify("AI inline generation complete! Use 'ga' to accept or 'gr' to reject changes.")
		end)
	end,
})

-- Strip "12 | " line-number prefixes the local model sometimes adds.
vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = { "CodeCompanionChatDone", "CodeCompanionInlineFinished" },
	callback = function(request)
		-- Use the buffer CodeCompanion reports, not whatever window has focus.
		local buf = (request.data and request.data.bufnr) or request.buf or vim.api.nvim_get_current_buf()
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local modified = false

		for i, line in ipairs(lines) do
			local cleaned, count = line:gsub("^%s*%d+%s*|%s?", "")
			if count > 0 then
				lines[i] = cleaned
				modified = true
			end
		end

		if modified then
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		end
	end,
})

-- Copy the code block under the cursor, without line numbers.
local function yank_code_block(buf)
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local block_start
	for i, line in ipairs(lines) do
		if line:match("^%s*```") then
			if not block_start then
				block_start = i
			elseif cursor_line >= block_start and cursor_line <= i then
				local first, last = block_start + 1, i - 1
				if first > last then
					notify("Code block under cursor is empty.", vim.log.levels.WARN)
					return
				end

				local code = {}
				for n = first, last do
					code[#code + 1] = (lines[n]:gsub("^%s*%d+[%s|:]*", ""))
				end
				vim.fn.setreg("+", table.concat(code, "\n"))

				local ns = vim.api.nvim_create_namespace("gy_flash")
				vim.hl.range(buf, ns, "IncSearch", { first - 1, 0 }, { last - 1, #lines[last] })
				vim.defer_fn(function()
					if vim.api.nvim_buf_is_valid(buf) then
						vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
					end
				end, 150)

				notify("Copied code block under cursor (cleaned)!")
				return
			else
				block_start = nil
			end
		end
	end

	notify("Cursor is not inside a code block.", vim.log.levels.WARN)
end

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = "codecompanion",
	callback = function(args)
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.foldcolumn = "0"

		map("n", "gy", function()
			yank_code_block(args.buf)
		end, { buffer = args.buf, silent = true, desc = "Yank code block without line numbers" })

		-- Inside the chat, <leader>cf jumps back to the code file.
		map("n", "<leader>cf", "<cmd>wincmd p<cr>", {
			buffer = args.buf,
			silent = true,
			desc = "Jump back to code file",
		})
	end,
})
