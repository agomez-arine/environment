-- Undotree — visualize the undo tree. Cheatsheet: <leader>U.
vim.pack.add {
  { src = 'https://github.com/mbbill/undotree', version = '6fa6b57cda8459e1e4b2ca34df702f55242f4e4d' },
}

vim.keymap.set('n', '<leader>U', '<cmd>UndotreeToggle<cr>', { desc = 'Toggle Undotree' })
