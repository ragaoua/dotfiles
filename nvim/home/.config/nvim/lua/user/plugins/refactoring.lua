return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"lewis6991/async.nvim",
	},
	opts = {},
	config = function()
		vim.keymap.set({ "n", "x" }, "<leader>r", function()
			return require("refactoring").select_refactor()
		end)
	end,
}
