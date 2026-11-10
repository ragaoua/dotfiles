return {
	"ThePrimeagen/refactoring.nvim",
	-- Pinned: later commits use vim.iter's Iter:unique, which needs Neovim 0.12.
	commit = "b712180fd81be069e59249d3a8106157439890e3",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"lewis6991/async.nvim",
	},
	opts = {},
	config = function()
		vim.keymap.set("n", "<leader>r", function()
			return require("refactoring").select_refactor()
		end)
		-- In visual mode, go through the ex command so Visual mode is left first
		-- and the '< '> / '[ '] marks point at the selection (otherwise the
		-- extraction picks up line 1). You then type the function name after the prompt.
		vim.keymap.set("x", "<leader>r", function()
			require("refactoring").select_refactor({ prefer_ex_cmd = true })
		end)
	end,
}
