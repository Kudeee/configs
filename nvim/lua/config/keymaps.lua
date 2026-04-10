-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Compatible with LazyVim v15+ / Neovim 0.11+

local map = vim.keymap.set

-- ─── Insert mode escape ────────────────────────────────────────────────────
map("i", "jj", "<Esc>", { desc = "Escape insert mode" })

-- ─── Compiler plugin keymaps ───────────────────────────────────────────────
-- Requires 'compiler.nvim'. Add it to your plugins list first, then
-- uncomment these. Leaving them active without the plugin causes errors.
--
-- map("n", "<F6>",   "<cmd>CompilerOpen<cr>",                    { silent = true, desc = "Compiler: open" })
-- map("n", "<S-F6>", "<cmd>CompilerStop<cr><cmd>CompilerRedo<cr>", { silent = true, desc = "Compiler: redo" })
-- map("n", "<S-F7>", "<cmd>CompilerToggleResults<cr>",           { silent = true, desc = "Compiler: toggle results" })

-- ─── Formatting ────────────────────────────────────────────────────────────
-- Explicit format keymap (conform + LSP fallback).
-- LazyVim already maps <leader>cf but this adds a quick alternative.
map({ "n", "v" }, "<leader>rf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file/selection" })

-- ─── Python: run current file in terminal ──────────────────────────────────
map("n", "<leader>rp", function()
  local file = vim.fn.expand("%:p")
  -- Uses snacks terminal (available in LazyVim v12+)
  Snacks.terminal.open("python3 " .. vim.fn.shellescape(file))
end, { desc = "Run Python file" })

-- ─── Diagnostic navigation ─────────────────────────────────────────────────
-- Neovim 0.11 changed vim.diagnostic.goto_next/prev → vim.diagnostic.jump
-- LazyVim already sets ]d / [d but these add float-showing variants.
map("n", "<leader>dj", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

map("n", "<leader>dk", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })
