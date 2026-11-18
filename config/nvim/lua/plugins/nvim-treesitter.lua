return{
  {
    "nvim-treesitter/nvim-treesitter",
    build = ':TSUpdate',
    lazy = false,
    config = function()
      require('nvim-treesitter').setup {
        install_dir = vim.fn.stdpath('data') .. '/site'
      }
      require('nvim-treesitter').install {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "systemverilog",
      }

      ---------------------------------------------------------------
      -- Embedded-language block styling                            --
      ---------------------------------------------------------------
      -- Goal: wherever treesitter injects one language inside another
      -- (lua/python inside sh heredocs, fenced blocks in markdown,
      -- tagged templates in JS, `lua << EOF` in vimscript, ...) tint
      -- the embedded region so it reads as a visual block. Injected
      -- syntax colors come from the stock injection queries for free;
      -- this just adds the background.
      --
      -- Mechanism: after parse(true), each injected language exists
      -- as a child language tree whose included_regions() describe
      -- exactly the embedded code. We paint line_hl extmarks (group
      -- EmbeddedCode, defined in config/autocmds.lua) over those
      -- rows; line_hl fills the full line width, plain captures only
      -- paint text cells.
      local ns = vim.api.nvim_create_namespace("embedded_bg")

      -- Injected languages to skip: markdown is rendered by it's own plugin
      local skip_lang = { markdown_inline = true }

      -- Filetypes to skip entirely: their blocks are rendered by plugins
      -- (render-markdown), so our tint would double-render.
      local skip_ft = { markdown = true }

      local function paint_injections(buf)
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)       -- repaint from scratch each time
        if skip_ft[vim.bo[buf].filetype] then return end
        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        if not ok or not parser then return end           -- no parser for this filetype
        local lines = vim.api.nvim_buf_line_count(buf)
        parser:parse(true)                                   -- full parse incl. injection regions
        for lang, child in pairs(parser:children()) do
          if not skip_lang[lang] then
            -- A child's regions are Range6: {start_row, start_col, _,
            -- end_row, end_col, _}. end_col == 0 means the range stops
            -- at the start of end_row, so that line is not included.
            for _, region in ipairs(child:included_regions()) do
              for _, r in ipairs(region) do
                local last = (r[5] == 0) and r[4] - 1 or r[4]
                for l = r[1], math.min(last, lines - 1) do
                  vim.api.nvim_buf_set_extmark(buf, ns, l, 0, { line_hl_group = "EmbeddedCode" })
                end
              end
            end
          end
        end
      end

      -- FileType paints on open; TextChanged repaints so the tint
      -- tracks lines inserted/deleted inside a block while editing.
      vim.api.nvim_create_autocmd({ "FileType", "TextChanged", "TextChangedI" }, {
        callback = function(ev) paint_injections(ev.buf) end,
      })
    end,
  },
}
