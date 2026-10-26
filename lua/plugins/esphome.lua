-- ==========================================================================
-- ESPHOME (ESP32 firmware: validate, build, flash, logs)
-- ==========================================================================
-- Runs the esphome CLI (uv tool) on the current device YAML in a terminal
-- split. Flashing over USB needs serial access: be in the `uucp` group.
-- If `esphome run` asks which port to use, answer in the terminal.

if vim.fn.executable("esphome") == 0 then
	return
end

local function current_config()
	local file = vim.api.nvim_buf_get_name(0)
	if not file:match("%.ya?ml$") then
		vim.notify("ESPHome: open a device .yaml file first", vim.log.levels.WARN)
		return nil
	end
	if vim.bo.modified then
		vim.cmd.write()
	end
	return file
end

-- Each run gets a fresh bottom split; close it with :q once it's done.
local function in_terminal(cmd, cwd)
	vim.cmd("botright 15new")
	vim.fn.jobstart(cmd, { term = true, cwd = cwd })
	vim.cmd.startinsert()
end

local function esphome(subcmd)
	local file = current_config()
	if file then
		in_terminal({ "esphome", subcmd, file }, vim.fs.dirname(file))
	end
end

-- Web dashboard (http://localhost:6052) for the folder of the current file
local function dashboard()
	local file = vim.api.nvim_buf_get_name(0)
	local dir = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
	in_terminal({ "esphome", "dashboard", dir }, dir)
end

local subcommands = { "config", "compile", "run", "upload", "logs", "clean" }

vim.api.nvim_create_user_command("ESPHome", function(opts)
	if opts.args == "dashboard" then
		dashboard()
	else
		esphome(opts.args)
	end
end, {
	nargs = 1,
	complete = function()
		return vim.list_extend(vim.deepcopy(subcommands), { "dashboard" })
	end,
	desc = "Run esphome <subcommand> on the current YAML file",
})

local map = function(lhs, subcmd, desc)
	vim.keymap.set("n", lhs, function()
		esphome(subcmd)
	end, { desc = desc })
end

map("<leader>iv", "config", "ESPHome: validate config")
map("<leader>ib", "compile", "ESPHome: build firmware")
map("<leader>if", "run", "ESPHome: build + flash + logs")
map("<leader>iu", "upload", "ESPHome: flash last build")
map("<leader>il", "logs", "ESPHome: show device logs")
map("<leader>ic", "clean", "ESPHome: clean build files")
vim.keymap.set("n", "<leader>id", dashboard, { desc = "ESPHome: web dashboard (:6052)" })
