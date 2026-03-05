return {
	"luckasRanarison/tailwind-tools.nvim",
	name = "tailwind-tools",
	build = ":UpdateRemotePlugins",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-telescope/telescope.nvim",
	},
	ft = { "html", "svelte", "astro", "vue", "typescriptreact" },
	opts = {
		conceal = {
			enabled = true,
		},
	},
}
