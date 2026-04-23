-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Compatible with LazyVim v15+ / Neovim 0.11+

local map = vim.keymap.set

-- ─── Insert mode escape ────────────────────────────────────────────────────
map("i", "jj", "<Esc>", { desc = "Escape insert mode" })

-- ─── Code runner (VSCode-style F5 / <leader>rr) ───────────────────────────
-- Runs the current file in a Snacks terminal split (bottom, 30% height).
-- Supports: Python, JS/TS (Node/ts-node), Lua, Shell, Ruby, Go, Rust, C#.
-- For compiled languages (Go, Rust, C#) it uses their standard run commands.
local function run_file()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")
  local fname = vim.fn.shellescape(file)
  local dir = vim.fn.shellescape(vim.fn.expand("%:p:h"))

  local runners = {
    python = "python3 " .. fname,
    javascript = "node " .. fname,
    typescript = "npx ts-node " .. fname,
    lua = "lua " .. fname,
    sh = "bash " .. fname,
    bash = "bash " .. fname,
    zsh = "zsh " .. fname,
    ruby = "ruby " .. fname,
    go = "cd " .. dir .. " && go run " .. fname,
    rust = "cd " .. dir .. " && cargo script " .. fname,
    -- C# via dotnet-script: `dotnet tool install -g dotnet-script`
    cs = "dotnet script " .. fname,
  }

  local cmd = runners[ft]
  if not cmd then
    vim.notify("No runner configured for filetype: " .. (ft == "" and "(none)" or ft), vim.log.levels.WARN)
    return
  end

  vim.cmd("silent! write") -- save before running

  -- Wrap in a shell that prints a separator + exit code, then waits for a
  -- keypress so the output stays visible (like VSCode's integrated terminal).
  local wrapped = string.format(
    'bash -c \'%s; echo; echo "──── Process exited with code $? ────"; read -n1 -p "Press any key to close..."\'',
    cmd:gsub("'", "'\\''") -- escape any single-quotes in the command
  )

  Snacks.terminal.open(wrapped, {
    win = {
      position = "bottom",
      height = 0.3,
    },
  })
end

map("n", "<F5>", run_file, { desc = "Run current file" })
map("n", "<leader>rr", run_file, { desc = "Run current file" })

-- ─── Formatting ────────────────────────────────────────────────────────────
map({ "n", "v" }, "<leader>rf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file/selection" })

-- ─── Python: explicit runner (kept for backwards compat; F5 also works) ────
map("n", "<leader>rp", run_file, { desc = "Run Python file" })

-- ─── Diagnostic navigation ─────────────────────────────────────────────────
map("n", "<leader>dj", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

map("n", "<leader>dk", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })
