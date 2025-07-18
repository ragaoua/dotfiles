return {
	"Wansmer/treesj",
	keys = { "<leader>m" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		local plugin = require("treesj")
		plugin.setup({
			use_default_keymaps = false,
		})
		vim.keymap.set("n", "<leader>m", plugin.toggle)
	end,
}
