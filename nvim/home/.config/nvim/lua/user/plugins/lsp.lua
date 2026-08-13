return {
	{
		-- Lua LSP for Neovim
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "b0o/SchemaStore.nvim", lazy = true },
			"nvim-telescope/telescope.nvim",

			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP.
			{ "j-hui/fidget.nvim", opts = {} },

			-- Allows extra capabilities provided by blink.cmp
			"saghen/blink.cmp",
		},
		config = function()
			-- Make sure that small pop up windows have a border
			local hover = vim.lsp.buf.hover
			---@diagnostic disable-next-line: duplicate-set-field
			vim.lsp.buf.hover = function()
				return hover({
					border = "rounded",
				})
			end
			local signature_help = vim.lsp.buf.signature_help
			---@diagnostic disable-next-line: duplicate-set-field
			vim.lsp.buf.signature_help = function()
				return signature_help({
					border = "rounded",
				})
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(mode, keys, func, desc)
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end
					local source_action = function(kind)
						return function()
							vim.lsp.buf.code_action({
								apply = true,
								context = {
									only = { kind },
									diagnostics = {},
								},
							})
						end
					end
					local telescope = require("telescope.builtin")

					-- Add "goto" keymaps to default ones
					map("n", "grd", vim.lsp.buf.definition, "[G]oto [R]eference [D]efinition")
					map("n", "grD", vim.lsp.buf.declaration, "[G]oto [R]eference [D]eclaration")
					map({ "n", "x" }, "gra", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("n", "grf", source_action("source.fixAll"), "[C]ode [F]ix All")
					map("n", "gro", source_action("source.organizeImports"), "[C]ode [O]rganize Imports")

					-- Hijack existing "goto" keymaps by telescope
					-- Telescope is great for there because it provides previews
					map("n", "grr", telescope.lsp_references, "[G]oto [R]eference [R]eferences")
					map("n", "grt", telescope.lsp_type_definitions, "[G]oto [R]eference [T]ype Definition")

					-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
					---@param client vim.lsp.Client
					---@param method vim.lsp.protocol.Method
					---@param bufnr? integer some lsp support methods only in specific files
					---@return boolean
					local function client_supports_method(client, method, bufnr)
						if vim.fn.has("nvim-0.11") == 1 then
							return client:supports_method(method, bufnr)
						else
							return client.supports_method(method, { bufnr = bufnr })
						end
					end

					-- Highlight references of the word under the cursor when it rests there for a little while.
					-- When the cursor moves, the highlights will be cleared (the second autocommand).
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if
						client
						and client_supports_method(
							client,
							vim.lsp.protocol.Methods.textDocument_documentHighlight,
							event.buf
						)
					then
						local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- Create a keymap to toggle inlay hints in the code, if the language server supports them
					if
						client
						and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("n", "<leader>h", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "Toggle Inlay [H]ints")
					end
				end,
			})

			-- Diagnostic Config
			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				},
				virtual_text = {
					source = "if_many",
					spacing = 2,
					format = function(diagnostic)
						local diagnostic_message = {
							[vim.diagnostic.severity.ERROR] = diagnostic.message,
							[vim.diagnostic.severity.WARN] = diagnostic.message,
							[vim.diagnostic.severity.INFO] = diagnostic.message,
							[vim.diagnostic.severity.HINT] = diagnostic.message,
						}
						return diagnostic_message[diagnostic.severity]
					end,
				},
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()

			local servers = {
				-- Lua
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- Toggle below to ignore Lua_LS's noisy `missing-fields` warnings
							-- diagnostics = { disable = { 'missing-fields' } },
						},
					},
				},

				-- Typescript/Javascript
				vtsls = {},
				eslint = {},
				svelte = {},

				-- Python
				basedpyright = {},
				ruff = {}, -- diagnostics and code actions

				-- Java
				jdtls = {},

				-- HTML/CSS
				html = {},
				emmet_ls = {}, -- HTML/CSS/Tailwind/react/svelte/etc expansion and snippets
				cssls = {},
				stylelint_lsp = {}, -- CSS linter
				tailwindcss = {},

				-- Shell
				bashls = {},

				-- Containers
				docker_compose_language_service = {},
				dockerls = {},

				-- Typst
				tinymist = {},

				-- Yaml
				yamlls = {
					settings = {
						yaml = {
							schemaStore = {
								enable = false,
								url = "",
							},
							schemas = require("schemastore").yaml.schemas(),
						},
					},
				},

				-- JSON
				jsonls = {
					settings = {
						json = {
							schemas = require("schemastore").json.schemas(),
							validate = { enable = true },
						},
					},
				},

				-- Markdown
				markdown_oxide = {
					capabilities = {
						workspace = {
							didChangeWatchedFiles = {
								dynamicRegistration = true,
							},
						},
					},
				},

				-- spell-checking
				cspell_ls = {}, -- Linter LSP
			}

			local tools = {
				-- Formatters
				"google-java-format",
				"prettierd",
				"shfmt",
				"stylua",
				"typstyle",

				-- CLI linters wired through nvim-lint
				"hadolint",
				"htmlhint",
				"markdownlint",
				"shellcheck",

				-- Java debugging
				"java-debug-adapter",
			}

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, tools)
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				ensure_installed = {}, -- explicitly set to an empty table (we'll populate installs via mason-tool-installer)
				automatic_installation = false,
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP on a per-server basis.
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				bash = { "shellcheck" },
				dockerfile = { "hadolint" },
				html = { "htmlhint" },
				markdown = { "markdownlint" },
				sh = { "shellcheck" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
