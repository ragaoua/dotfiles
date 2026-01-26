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
			current_line_blame = true,
		},
		config = function(_, opts)
			local function gitsigns_visual_op(op)
				return function()
					return require("gitsigns")[op]({ vim.fn.line("."), vim.fn.line("v") })
				end
			end

			local gs = require("gitsigns")
			gs.setup(opts)

			-- Stage
			vim.keymap.set("n", "<leader>gs", gs.stage_hunk, { desc = "Gitsigns: Stage/unstage hunk" })
			vim.keymap.set(
				"v",
				"<leader>gs",
				gitsigns_visual_op("stage_hunk"),
				{ desc = "Gitsigns: Stage/unstage selected hunk" }
			)
			vim.keymap.set("n", "<leader>gS", gs.stage_buffer, { desc = "Gitsigns: Stage buffer" })
			vim.keymap.set("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Gitsigns: Undo stage hunk" })

			-- Reset
			vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { desc = "Gitsigns: Reset hunk" })
			vim.keymap.set(
				"v",
				"<leader>gr",
				gitsigns_visual_op("reset_hunk"),
				{ desc = "Gitsigns: Reset selected hunk" }
			)
			vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { desc = "Gitsigns: Preview hunk" })

			-- Blame
			vim.keymap.set("n", "<leader>gb", function()
				gs.blame_line({ full = true })
			end, { desc = "Gitsigns: Blame hunk" })
			vim.keymap.set(
				"n",
				"<leader>gtb",
				gs.toggle_current_line_blame,
				{ desc = "Gitsigns: Toggle current line blame" }
			)

			-- Diff
			vim.keymap.set("n", "<leader>gd", gs.diffthis, { desc = "Gitsigns: Diff this" })
			vim.keymap.set("n", "<leader>gD", function()
				gs.diffthis("~")
			end, { desc = "Gitsigns: Diff this against last commit" })
			vim.keymap.set("n", "<leader>gtd", gs.toggle_deleted, { desc = "Gitsigns: Toggle deleted" })
		end,
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
				vim.cmd("vert Git")
			end

			vim.keymap.set("n", "<leader>G", fugitive_toggle, { desc = "Toggle Git Fugitive" })
		end,
	},
}
