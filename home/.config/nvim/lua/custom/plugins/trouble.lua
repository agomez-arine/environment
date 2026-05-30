-- Cheatsheet: <leader>xx Trouble (project diagnostics).
vim.pack.add {
  { src = 'https://github.com/folke/trouble.nvim', version = 'bd67efe408d4816e25e8491cc5ad4088e708a69a' },
}

require('trouble').setup({})

local map = vim.keymap.set
map('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>',                { desc = 'Diagnostics (Trouble)' })
map('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',   { desc = 'Buffer diagnostics' })
map('n', '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>',        { desc = 'Symbols (Trouble)' })
map('n', '<leader>xL', '<cmd>Trouble loclist toggle<cr>',                    { desc = 'Location list' })
map('n', '<leader>xQ', '<cmd>Trouble qflist toggle<cr>',                     { desc = 'Quickfix list' })
