local augroup = vim.api.nvim_create_augroup("UserConfig", {})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Open image files in the system default viewer instead of loading them as a buffer
vim.api.nvim_create_autocmd("BufReadCmd", {
	group = augroup,
	pattern = {
		"*.png",
		"*.jpg",
		"*.jpeg",
		"*.gif",
		"*.webp",
		"*.avif",
		"*.bmp",
		"*.tiff",
		"*.tif",
		"*.svg",
		"*.ico",
		"*.heic",
	},
	callback = function(args)
		vim.ui.open(args.file)
		vim.schedule(function()
			pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
		end)
	end,
})
