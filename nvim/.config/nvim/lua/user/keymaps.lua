-- Leader key
vim.g.mapleader = " " -- Set leader key to space
vim.g.maplocalleader = " " -- Set local leader key (NEW)

-- Escaping
vim.keymap.set("i", "jk", "<ESC>", { desc = "jk to escape insert mode" })
vim.keymap.set("i", "kj", "<ESC>", { desc = "kj to escape insert mode" })

-- Searching
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Center screen when jumping
-- vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
-- vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Delete without yanking
-- vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "n", "v" }, "x", '"_x', { desc = "Delete char without yanking" })
vim.keymap.set({ "n", "v" }, "X", '"_X', { desc = "Delete previous char without yanking" })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Previous buffer" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Splitting & Resizing
vim.keymap.set("n", "<C-s>v", ":vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<C-s>h", ":split<CR>", { desc = "Split window horizontally" })
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Move lines up/down
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Identing
vim.keymap.set("n", "<Tab>", ">>", { desc = "Indent right" })
vim.keymap.set("n", "<S-Tab>", "<<", { desc = "Indent left" })
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent right and reselect" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Indent left and reselect" })

-- Quick file navigation
vim.keymap.set("n", "<leader>e", ":Explore<CR>", { desc = "Open file explorer" })
vim.keymap.set("n", "<leader><leader>", ":find ", { desc = "Find file" })

-- Commenting
vim.keymap.set("n", "cc", "gcc", { desc = "Toggle Comment Line", remap = true })
vim.keymap.set("v", "c", "gc", { desc = "Toggle Comment Selection", remap = true })

-- Others
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostics under the cursor" })
