return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
    keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = true,
			format_on_save = function(bufnr)
				-- Cases where format_on_save should be disabled
				local disable_filetypes = {
					typst = true,
				}
				local is_fugitive_bfr = vim.api.nvim_buf_get_name(bufnr):match("^fugitive://")

				if disable_filetypes[vim.bo[bufnr].filetype] or is_fugitive_bfr then
					return nil
				end

				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "black" },
				go = { "goimports", "gofumpt" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				["*"] = { "codespell" },
				["_"] = { "trim_whitespace" },
			},
		},
	},
}
