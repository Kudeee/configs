-- Python language support
-- Compatible with LazyVim v15+ / Neovim 0.11+ / Mason v2
return {

  -- ─── Treesitter ───────────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "python",
        "toml",
        "ninja",
      })
    end,
  },

  -- ─── LSP: replace pyright with basedpyright ───────────────────────────────
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable the default pyright that lang.python extra enables
        pyright = { enabled = false },

        -- basedpyright: strict, modern drop-in pyright replacement
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
              },
            },
          },
        },

        -- ruff LSP: linting + import sorting; disable hover (basedpyright owns it)
        ruff = {
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },

  -- ─── Mason v2: correct org name + package names ───────────────────────────
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "basedpyright",
        "ruff",
        "black",
        "debugpy",
        "mypy",
      })
    end,
  },

  -- ─── Formatting ───────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "black", stop_after_first = true },
      },
      formatters = {
        ruff_format = {
          command = "ruff",
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
          stdin = true,
        },
      },
    },
  },

  -- ─── Linting ──────────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff" },
      },
    },
  },

  -- ─── DAP: Python debugger ─────────────────────────────────────────────────
  {
    "mfussenegger/nvim-dap",
    dependencies = { "mfussenegger/nvim-dap-python" },
    config = function()
      local debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(debugpy)
    end,
    keys = {
      {
        "<leader>dPt",
        function()
          require("dap-python").test_method()
        end,
        desc = "Debug method",
      },
      {
        "<leader>dPc",
        function()
          require("dap-python").test_class()
        end,
        desc = "Debug class",
      },
      {
        "<leader>dPs",
        function()
          require("dap-python").debug_selection()
        end,
        desc = "Debug selection",
        mode = "v",
      },
    },
  },

  -- ─── Virtual-env switcher ─────────────────────────────────────────────────
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "VenvSelect",
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
      { "<leader>cV", "<cmd>VenvSelectCached<cr>", desc = "Use cached VirtualEnv" },
    },
    opts = {
      settings = {
        options = { notify_user_on_venv_activation = true },
      },
    },
  },
}
