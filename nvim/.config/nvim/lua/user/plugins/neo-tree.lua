return {
	"nvim-neo-tree/neo-tree.nvim",
	version = "*",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	lazy = false,
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
			function()
				require("neo-tree.command").execute({
					toggle = true,
					source = "filesystem",
					dir = vim.fn.expand("%:p:h"),
				})
			end,
			desc = "NeoTree toggle current buffer's filesystem",
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
		-- close_if_last_window = true,
		window = {
			position = "float",
		},
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
