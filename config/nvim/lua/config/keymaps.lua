vim.g.mapleader = " "

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines, keep cursor" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down, centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up, centered" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Search match next, centered + unfold" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Search match prev, centered + unfold" })

-- greatest remap ever TODO (ng): Whut?
vim.keymap.set("x", "<leader>p", [["_dP]],
  { desc = "Paste over selection without yanking" })

-- next greatest remap ever : asbjornHaland TODO (ng): Whut?
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]],
  { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]],
  { desc = "Yank-line to system clipboard" })

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]],
  { desc = "Delete to black-hole register" })

-- Use lsp to format
vim.keymap.set("n", "<leader>fmt", vim.lsp.buf.format, { desc = "LSP format" })

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Quickfix next" })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Quickfix prev" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Loclist next" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Loclist prev" })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float,
  { desc = "Diagnostic float" })
vim.keymap.set("n", "<leader>l", function()
  local winid = vim.fn.getloclist(0, { winid = 0 }).winid
  if winid ~= 0 then
    vim.cmd("lclose")
  else
    vim.diagnostic.setloclist()
  end
end, { desc = "Toggle Location List (diagnostics)" })

vim.keymap.set('n', "<leader>q", function()
    for _, win in ipairs(vim.fn.getwininfo()) do
      if win.quickfix == 1 then vim.cmd("cclose") return end
    end
    vim.cmd("copen")
  end, {desc = "Toggle Quickfix List" })

-- Change directory
vim.keymap.set('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>',
  { desc = "cd to file's directory" })

-- Buffer close
vim.keymap.set('n', '<leader>bc', ':bdelete<cr>', { desc = "Close buffer" })
vim.keymap.set('n', '<leader>bd', ':bdelete!<cr>',
  { desc = "Force-close buffer" })

-- insert a new line without leaving normal moede (almost)
vim.keymap.set('n', '<leader>o', 'o<ESC>k', { desc = "Blank line below" })
vim.keymap.set('n', '<leader>O', 'O<ESC>j', { desc = "Blank line above" })

-- Split resizing
vim.keymap.set('n',  '<C-l>', '<C-W>>', { desc = "Widen split" })
vim.keymap.set('n',  '<C-h>', '<C-W><', { desc = "Narrow split" })
vim.keymap.set('n',  '<C-n>', '<C-W>+', { desc = "Grow split vertically" })
vim.keymap.set('n',  '<C-p>', '<C-W>-', { desc = "Shrink split vertically" })

-- Don't lose selection when shifting sideways
vim.keymap.set("x", "<", "<gv", { desc = "Outdent, keep selection" })
vim.keymap.set("x", ">", ">gv", { desc = "Indent, keep selection" })

-- netrw Open Entry
vim.api.nvim_create_autocmd('filetype', {
  pattern = 'netrw',
  desc = 'Better mappings for netrw',
  callback = function()
    local bind = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, {remap = true, buffer = true, desc = desc})
    end

    -- edit new file
    bind('o', '<cr>', 'Open entry')

  end
})

