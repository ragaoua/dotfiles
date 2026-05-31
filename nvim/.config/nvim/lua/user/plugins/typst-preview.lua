return {
	"chomosuke/typst-preview.nvim",
	ft = "typst",
	version = "1.*",
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "typst",
			callback = function(args)
				vim.keymap.set("n", "<leader>p", ":TypstPreview<CR>", { buffer = args.buf })
			end,
		})
	end,
}
