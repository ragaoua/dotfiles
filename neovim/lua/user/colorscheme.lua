-- This contains the default colorscheme config.
-- It [can be/should be/probably is] overriden by a plugin
-- that sets up a more sophisticated config
vim.cmd.colorscheme("hamabax")

-- Transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
