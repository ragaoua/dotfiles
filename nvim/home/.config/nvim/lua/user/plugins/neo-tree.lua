return {
	"nvim-neo-tree/neo-tree.nvim",
	version = "*",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	lazy = false,
	init = function()
		-- When started on a directory (e.g. "nvim ."), show only the tree, without
		-- the empty window next to it. Opening a file splits the tree back into a
		-- sidebar.
		vim.api.nvim_create_autocmd("VimEnter", {
			once = true,
			callback = function()
				if vim.fn.argc() ~= 1 or vim.fn.isdirectory(vim.fn.argv(0)) == 0 then
					return
				end
				vim.cmd("Neotree")
				vim.cmd("only")
			end,
		})
	end,
	keys = {
		{
			"<leader>e",
			function()
				require("neo-tree.command").execute({
					toggle = true,
					source = "last",
				})
			end,
			desc = "NeoTree toggle",
		},
		{
			"<leader>fe",
			":Neotree reveal<CR>",
			desc = "NeoTree reveal and focus current buffer",
		},
		{
			"<leader>ne",
			function()
				require("neo-tree.command").execute({
					toggle = true,
					source = "filesystem",
					dir = vim.fn.stdpath("config"),
				})
			end,
			desc = "NeoTree toggle neovim filesystem",
		},
	},
	opts = {
		filesystem = {
			-- hijack_netrw_behavior = "open_current",
			filtered_items = {
				visible = true,
				hide_dotfiles = false,
			},
			window = {
				mappings = {
					["<Tab>"] = "open",
					["z"] = "close_all_subnodes",
					["Z"] = "expand_all_subnodes",
				},
			},
		},
	},
}
