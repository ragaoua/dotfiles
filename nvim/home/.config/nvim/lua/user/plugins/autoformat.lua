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
					-- typst = true,
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
			formatters = {
				prettierd = {
					-- Wrap markdown at 80 chars, used only when the project has no prettier config
					-- (prettierd ignores "overrides" in its default config, hence the per-filetype env)
					env = function(_, ctx)
						local ft = vim.bo[ctx.buf].filetype
						if ft == "markdown" or ft == "mdx" then
							return { PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath("config") .. "/prettierrc-markdown.json" }
						end
						return {}
					end,
				},
			},
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_fix", "ruff_format" },
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				svelte = { "prettierd" },
				html = { "prettierd" },
				css = { "prettierd" },
				scss = { "prettierd" },
				less = { "prettierd" },
				yaml = { "prettierd" },
				json = { "prettierd" },
				jsonc = { "prettierd" },
				java = { "google-java-format" },
				markdown = { "prettierd" },
				mdx = { "prettierd" },
				typst = { "typstyle" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				["_"] = { "trim_whitespace" },
			},
		},
	},
}
