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
					position = "right",
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
					position = "right",
					source = "filesystem",
				})
			end,
			desc = "NeoTree toggle filesystem",
		},
		{
			"<leader>ne",
			function()
				require("neo-tree.command").execute({
					toggle = true,
					position = "right",
					source = "filesystem",
					dir = vim.fn.stdpath("config"),
				})
			end,
			desc = "NeoTree toggle buffers",
		},
		{
			"<leader>be",
			function()
				require("neo-tree.command").execute({
					toggle = true,
					position = "right",
					source = "buffers",
				})
			end,
			desc = "NeoTree toggle buffers",
		},
	},
	opts = {
		filesystem = {
			window = {
				mappings = {
					["\\"] = "close_window",
					["<Tab>"] = "open",
				},
			},
		},
	},
}
