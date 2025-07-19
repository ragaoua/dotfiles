return {
	"shaunsingh/nord.nvim",
	priority = 1000,
	config = function()
		vim.g.nord_bold = false
		vim.g.nord_italic = false
		require("nord").set()

		-- Change variables highlighting
		vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
			group = vim.api.nvim_create_augroup("nord-lsp-highlight", {}),
			pattern = "*",
			callback = function()
				vim.api.nvim_set_hl(0, "LspReferenceRead", { fg = "#FFFFFF", bg = "#357973" })
				vim.api.nvim_set_hl(0, "LspReferenceWrite", { fg = "#FFFFFF", bg = "#357973" })
				vim.api.nvim_set_hl(0, "LspReferenceText", { fg = "#FFFFFF", bg = "#357973" })
			end,
		})
	end,
}
