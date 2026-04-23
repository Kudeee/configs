-- ─── Code runner (VSCode-style F5 / <leader>r) ─────────────────────────────
-- Runs the current file in a Snacks terminal split.
-- Supports: Python, JavaScript/TypeScript (Node), Lua, Shell, Ruby, Go, Rust.
-- For compiled languages (Go, Rust) it builds first in a temp dir.
-- Bind F5 for quick access and <leader>rr as an alternative.

local function run_file()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")
  local fname = vim.fn.shellescape(file)

  local runners = {
    python = "python3 " .. fname,
    javascript = "node " .. fname,
    typescript = "npx ts-node " .. fname,
    lua = "lua " .. fname,
    sh = "bash " .. fname,
    bash = "bash " .. fname,
    zsh = "zsh " .. fname,
    ruby = "ruby " .. fname,
    go = "cd " .. vim.fn.shellescape(vim.fn.expand("%:p:h")) .. " && go run " .. fname,
    rust = "cd " .. vim.fn.shellescape(vim.fn.expand("%:p:h")) .. " && cargo script " .. fname,
    -- C# via dotnet-script (install: dotnet tool install -g dotnet-script)
    cs = "dotnet script " .. fname,
  }

  local cmd = runners[ft]
  if not cmd then
    vim.notify("No runner configured for filetype: " .. (ft == "" and "(none)" or ft), vim.log.levels.WARN)
    return
  end

  -- Save before running
  vim.cmd("silent! write")

  Snacks.terminal.open(cmd, {
    win = {
      position = "bottom",
      height = 0.3,
    },
  })
end

map("n", "<F5>", run_file, { desc = "Run current file" })
map("n", "<leader>rr", run_file, { desc = "Run current file" })

-- Keep the dedicated Python keymap for explicit use; remove if you prefer only F5/<leader>rr
map("n", "<leader>rp", function()
  local file = vim.fn.expand("%:p")
  Snacks.terminal.open("python3 " .. vim.fn.shellescape(file))
end, { desc = "Run Python file" })
