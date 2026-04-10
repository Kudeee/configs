-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Compatible with LazyVim v15+ / Neovim 0.11+

-- ─── Diagnostics ───────────────────────────────────────────────────────────
-- NOTE: vim.fn.sign_define() is deprecated in Neovim 0.10+.
-- Use the `signs.text` table inside vim.diagnostic.config() instead.
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,

  virtual_text = {
    spacing = 4,
    source = "if_many", -- show source only when multiple providers active
    prefix = "●",
  },

  -- Neovim 0.10+ sign API: map severity → icon text
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = "󰠠 ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },

  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- ─── Editor UX ─────────────────────────────────────────────────────────────
vim.opt.relativenumber = true -- relative line numbers alongside absolute
vim.opt.scrolloff = 8 -- keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8
vim.opt.wrap = false -- no soft line wrap
vim.opt.conceallevel = 1 -- allow concealment (e.g. markdown, Neorg)

-- ─── Python provider ───────────────────────────────────────────────────────
-- Point Neovim to a stable python3 so it doesn't search PATH on every startup.
-- Adjust if you use pyenv, asdf, or a fixed virtualenv.
local py = vim.fn.exepath("python3")
if py ~= "" then
  vim.g.python3_host_prog = py
end

-- Disable unused providers to speed up startup health checks
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
-- NOTE: do NOT disable node_provider if you use any node-based Neovim plugins.
-- Mason itself doesn't use the node provider, but setting this to 0 can
-- interfere with other things. Leave it unset.

local function prepend_node_path()
  -- Best case: node is already on PATH (Termux, system install, etc.)
  local node = vim.fn.exepath("node")
  if node ~= "" then
    vim.g.node_host_prog = node
    return
  end

  -- Fallback: nvm.fish default location (Linux desktop)
  local nvm_dir = vim.fn.expand("~/.local/share/nvm")
  if vim.fn.isdirectory(nvm_dir) == 1 then
    local versions = vim.fn.glob(nvm_dir .. "/v*/bin/node", false, true)
    if #versions > 0 then
      -- pick the last (highest) version
      local bin = vim.fn.fnamemodify(versions[#versions], ":h")
      vim.env.PATH = bin .. ":" .. vim.env.PATH
      vim.g.node_host_prog = bin .. "/node"
    end
  end
end
prepend_node_path()
