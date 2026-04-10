-- C# / .NET LSP configuration
-- Compatible with LazyVim v15+ / Neovim 0.11+ / Mason v2
--
-- The lang.dotnet extra (lazyvim.json) already handles:
--   - Installing omnisharp, csharpier, netcoredbg via Mason
--   - Setting up omnisharp-extended-lsp.nvim for go-to-definition
--   - roslyn analyzers + import completion defaults
--
-- This file only adds semantic token fix + project-specific overrides.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("*.sln", "*.csproj", "omnisharp.json", ".git")(fname)
          end,

          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,

          -- OmniSharp uses spaces in semantic token names, violating LSP spec.
          -- This patch normalizes them to underscores on attach.
          on_attach = function(client)
            if client.name == "omnisharp" then
              local tok = client.server_capabilities.semanticTokensProvider
              if tok and tok.legend then
                for _, list in ipairs({ tok.legend.tokenModifiers, tok.legend.tokenTypes }) do
                  for i, v in ipairs(list) do
                    list[i] = v:gsub("%s+", "_")
                  end
                end
              end
            end
          end,
        },

        -- Disable fsautocomplete (F# server from lang.dotnet extra).
        -- Remove this block if you do F# development.
        fsautocomplete = { enabled = false },
      },
    },
  },

  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    lazy = true,
  },
}
