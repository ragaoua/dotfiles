return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	commit = "cf12346a3414fa1b06af75c79faebe7f76df080a",
	build = ":TSUpdate",
	main = "nvim-treesitter.configs",
	opts = {
		highlight = { enable = true },
		auto_install = true,
		indent = { enable = true },
	},
}
