return {
	"nvim-telescope/telescope.nvim",
	event = "VimEnter",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			-- `build` is used to run some command when the plugin is installed/updated.
			-- This is only run then, not every time Neovim starts up.
			build = "make",
			-- `cond` is a condition used to determine whether this plugin should be
			-- installed and loaded.
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },
		{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
	},
	config = function()
		-- NOTE: I would rather have `toggle_[ff/lg]no_ignore` functions that
		-- toggle `no_ignore`/`--no-ignore` on and off but that would require
		-- having access to the current state of no_ignore which the telescope
		-- API doesn't seem to provide. But this is good enough.
		local function enable_ff_no_ignore(prompt_bufnr)
			local actions_state = require("telescope.actions.state")

			local query = actions_state.get_current_line()
			require("telescope.builtin").find_files({
				no_ignore = true,
				default_text = query,
			})
		end
		local function enable_lg_no_ignore(prompt_bufnr)
			local actions_state = require("telescope.actions.state")

			local query = actions_state.get_current_line()
			require("telescope.builtin").live_grep({
				additional_args = function()
					return { "--no-ignore", "--hidden" }
				end,
				default_text = query,
			})
		end

		local telescope = require("telescope")
		telescope.setup({
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown(),
				},
			},
			pickers = {
				find_files = {
					hidden = true,
					mappings = {
						i = {
							["<c-h>"] = enable_ff_no_ignore,
						},
					},
				},
				live_grep = {
					hidden = true,
					mappings = {
						i = {
							["<c-h>"] = enable_lg_no_ignore,
						},
					},
				},
			},
			defaults = {
				file_ignore_patterns = { "%.git/" },
				mappings = {
					i = {
						["<c-d>"] = require("telescope.actions").delete_buffer,
					},
					n = {
						["<c-d>"] = require("telescope.actions").delete_buffer,
					},
				},
			},
		})

		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "ui-select")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "[S]earch [F]iles" })
		vim.keymap.set("n", "<leader>so", builtin.oldfiles, { desc = "[S]earch [O]ld files" })
		vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
		vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
		vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[ ] Find existing buffers" })
		vim.keymap.set("n", "<leader>sG", function()
			builtin.live_grep({
				grep_open_files = true,
				prompt_title = "Live Grep in Open Files",
			})
		end, { desc = "[S]earch by [G]rep in Open Buffers" })
		vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
		vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
		vim.keymap.set("n", "<leader>/", function()
			builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				previewer = false,
				layout_config = {
					width = 0.8,
					height = 0.9,
				},
			}))
		end, { desc = "[/] Fuzzily Search Current Buffer" })

		vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
		vim.keymap.set("n", "<leader>st", builtin.builtin, { desc = "[S]earch [T]elescope pickers" })
		vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
		vim.keymap.set("n", "<leader>sn", function()
			builtin.find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "[S]earch [N]eovim files" })
	end,
}
