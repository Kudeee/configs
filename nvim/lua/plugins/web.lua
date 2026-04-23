-- Web language support: JavaScript, TypeScript, React (JSX/TSX), HTML, CSS
-- Compatible with LazyVim v15+ / Neovim 0.11+ / Mason v2
return {

  -- ─── Treesitter: parsers not already pulled in by lang.typescript ─────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "html",
        "css",
        "scss",
        "graphql",
      })
    end,
  },

  -- ─── Auto-close/rename HTML & JSX tags ───────────────────────────────────
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- ─── LSP server settings ──────────────────────────────────────────────────
  -- NOTE: The lang.typescript extra already enables vtsls + jsonls.
  -- We only override/extend settings here.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript / JavaScript / React
        vtsls = {
          settings = {
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = { enableServerSideFuzzyMatch = true },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = { completeFunctionCalls = true },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
            javascript = {
              updateImportsOnFileMove = { enabled = "always" },
              inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
        },

        -- HTML
        html = {
          filetypes = { "html", "htmldjango", "jinja.html" },
        },

        -- CSS / SCSS
        cssls = {
          -- filetypes = { "scss", "less" },
          -- settings = {
          --   css = {
          --     validate = true,
          --     lint = {
          --       unknownAtRules = "ignore",
          --     },
          --   },
          --   scss = { validate = true },
          --   less = { validate = true },
          -- },
        },

        -- Tailwind CSS
        tailwindcss = {
          filetypes = {
            "html",
            "css",
            "scss",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
          },
        },

        -- ESLint — fix-all wired via autocmd in setup below
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
          },
        },
      },

      setup = {
        eslint = function()
          -- Use LspAttach so the autocmd only fires on buffers where eslint
          -- is actually attached. The `callback` form (not `command`) lets us
          -- guard against the command not existing yet (e.g. during install).
          vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
              local client = vim.lsp.get_client_by_id(args.data.client_id)
              if client and client.name == "eslint" then
                vim.api.nvim_create_autocmd("BufWritePre", {
                  buffer = args.buf,
                  callback = function()
                    vim.lsp.buf.format({
                      bufnr = args.buf,
                      filter = function(c)
                        return c.name == "eslint"
                      end,
                    })
                  end,
                })
              end
            end,
          })
        end,
      },
    },
  },

  -- ─── Mason v2: use new org name, correct package names ───────────────────
  -- LazyVim already declares mason-org/mason.nvim internally.
  -- We extend its ensure_installed via the opts function — do NOT redeclare
  -- the plugin with the old williamboman/ prefix or you'll get duplicate warnings.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- Mason v2 package names (verify at https://mason-registry.dev/registry/list)
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        "eslint-lsp",
        "prettierd",
        "prettier",
      })
    end,
  },

  -- ─── Formatting ───────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },
        graphql = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },

  -- ─── Package.json version hints ───────────────────────────────────────────
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = "BufRead package.json",
    opts = {},
    keys = {
      {
        "<leader>cpi",
        function()
          require("package-info").install()
        end,
        desc = "Install package",
      },
      {
        "<leader>cpu",
        function()
          require("package-info").update()
        end,
        desc = "Update package",
      },
      {
        "<leader>cpd",
        function()
          require("package-info").delete()
        end,
        desc = "Delete package",
      },
      {
        "<leader>cpc",
        function()
          require("package-info").change_version()
        end,
        desc = "Change version",
      },
    },
  },
}
