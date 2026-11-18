return { 'voldikss/vim-floaterm',
  keys={
    {"<leader>ftn", ":FloatermNew<cr>", desc = "New terminal"},
    {"<leader>ftk", ":FloatermKill<cr>", desc = "Kill terminal"},
    {"<leader>ftt", ":FloatermToggle<cr>", desc = "Toggle terminal"},
    {"<leader>fh", ":FloatermPrev<cr>", desc = "Prev terminal"},
    {"<leader>fl", ":FloatermNext<cr>", desc = "Next terminal"},
    {"<leader>fts", ":FloatermSend<cr>", desc = "Send line"},
    {"<leader>ftv", ":'<.'>FloatermSend<cr>", desc = "Send selection"},
  },
}
