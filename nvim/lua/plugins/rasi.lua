-- RASI (Rofi theme) language support
-- Compatible with LazyVim v15+ / Neovim 0.11+ / Mason v2
return {

  -- ─── Treesitter: RASI parser ───────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "rasi",
      })
    end,
  },

  -- ─── Filetype detection ────────────────────────────────────────────────────
  -- Neovim doesn't detect .rasi out of the box in all versions.
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      vim.filetype.add({
        extension = { rasi = "rasi" },
      })
    end,
  },

  -- ─── Formatting ───────────────────────────────────────────────────────────
  -- There's no dedicated RASI formatter, so we fall back to prettierd if
  -- it ever gains support; otherwise format is a no-op (remove if unwanted).
  -- {
  --   "stevearc/conform.nvim",
  --   opts = {
  --     formatters_by_ft = {
  --       rasi = { "prettierd", stop_after_first = true },
  --     },
  --   },
  -- },
}
