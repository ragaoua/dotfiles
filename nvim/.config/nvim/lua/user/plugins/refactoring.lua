return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {},
	config = function()
		vim.keymap.set({ "n", "x" }, "<leader>r", function()
			require("refactoring").select_refactor()
		end)
	end,
}
