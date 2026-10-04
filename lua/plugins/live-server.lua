-- ==========================================================================
-- LIVE SERVER (port configured via vim.g.live_server in config/options.lua)
-- ==========================================================================

vim.keymap.set("n", "<leader>ls", "<cmd>LiveServerStart<cr>", { desc = "Start Live Server" })
vim.keymap.set("n", "<leader>lx", "<cmd>LiveServerStop<cr>", { desc = "Stop Live Server" })
