return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	build = ":call mkdp#util#install()",
	config = function()
		vim.keymap.set("n", "<leader>p", ":MarkdownPreview<CR>")
	end,
}
