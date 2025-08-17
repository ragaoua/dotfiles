return {
	"chomosuke/typst-preview.nvim",
	ft = "typst",
	version = "1.*",
	config = function()
		vim.keymap.set("n", "<leader>p", ":TypstPreview<CR>")
	end,
}
