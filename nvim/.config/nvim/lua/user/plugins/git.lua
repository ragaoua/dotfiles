return {
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},
	{
		"tpope/vim-fugitive",
		config = function()
			local function fugitive_toggle()
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
					if ft == "fugitive" then
						vim.api.nvim_win_close(win, true)
						return
					end
				end
				vim.cmd("G")
			end

			vim.keymap.set("n", "<leader>g", fugitive_toggle, { desc = "Toggle Git Fugitive" })
		end,
	},
}
