-- ==========================================================================
-- GIT (gitsigns + lazygit)
-- ==========================================================================

local ok, gitsigns = pcall(require, "gitsigns")
if ok then
	gitsigns.setup({
		current_line_blame = true,
	})

	-- In diff mode keep Vim's native ]c / [c.
	local function hunk_nav(native, direction)
		return function()
			if vim.wo.diff then
				vim.cmd.normal({ native, bang = true })
			else
				gitsigns.nav_hunk(direction)
			end
		end
	end

	vim.keymap.set("n", "]c", hunk_nav("]c", "next"), { desc = "Next git change" })
	vim.keymap.set("n", "[c", hunk_nav("[c", "prev"), { desc = "Previous git change" })
end

vim.keymap.set("n", "<leader>lg", "<cmd>LazyGit<cr>", { desc = "Open LazyGit" })
