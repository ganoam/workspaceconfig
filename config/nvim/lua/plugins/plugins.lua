-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {

  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects", version = 'main',
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  -- },


  -- GitCommands
  {
    'tpope/vim-fugitive',
    config = function()
      vim.keymap.set('n', 'y<C-G>',
        ':<C-U>call setreg(v:register, fugitive#Object(@%))<CR>',
        { desc = "Yank object path" })
    end,
  },

  -- git tools:show change symbols
  {
    'airblade/vim-gitgutter',
  },

  -- git hunk staging engine; signs stay with gitgutter
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPre',
    opts = { signcolumn = false },
    keys = {
      { '<leader>hl',
        function()
          local l1, l2 = vim.fn.line('.'), vim.fn.line('v')
          require('gitsigns').stage_hunk({ math.min(l1, l2), math.max(l1, l2) })
        end,
        mode = 'x',
        desc = "Stage selected lines" },
    },
  },

  -- quick grep to quicklist
  {"jremmen/vim-ripgrep"},

  -- Netrw bindings
  {
    "tpope/vim-vinegar",
    config = function()
      vim.keymap.set('n', '-', '<Plug>VinegarUp',
        { desc = "Open netrw at file's dir / go up", remap = true })
      -- vinegar's remaining binds are netrw-buffer-local and use <SID>
      -- functions; patch descs onto them instead of re-declaring
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "netrw",
        callback = function()
          for lhs, desc in pairs({
            ["-"] = "Go up a directory",
            ["~"] = "Go to home directory",
            ["."] = "Prepend filename to command line",
            ["gh"] = "Toggle hidden files",
            ["y."] = "Yank absolute path",
          }) do
            local m = vim.fn.maparg(lhs, "n", false, true)
            if m.lhs ~= "" then
              m.desc = desc
              pcall(vim.fn.mapset, "n", 0, m)
            end
          end
        end,
      })
    end,
  },


  {'simnalamburt/vim-mundo',
    lazy = false
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ':TSUpdate',
    lazy = false,
    opts = {
      ensure_installed = {
        "c++",
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
        "verilog",
      },
    }
  },

  -- surrounmd
  {
    "kylechui/nvim-surround",
    version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },

  -- nerdfonts
  {
    '2kabhishek/nerdy.nvim',
    dependencies = {
      'folke/snacks.nvim',
    },
    cmd = 'Nerdy',
    keys = {
      { '<leader>in', '<cmd>Nerdy list<CR>', desc = "Browse nerd icons" },
      { '<leader>iN', '<cmd>Nerdy recents<CR>', desc = "Recent nerd icons" },
    },
    opts = {
      max_recents = 30, -- Configure recent icons limit
      copy_to_clipboard = false, -- Copy glyph to clipboard instead of inserting
      copy_register = '+', -- Register to use for copying (if `copy_to_clipboard` is true)
    }
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },

}
