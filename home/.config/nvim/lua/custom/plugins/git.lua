-- Git: lazygit (cheatsheet <leader>gg) + diffview (<leader>gd / <leader>gh).
-- gitsigns is already installed by kickstart's bundled plugin.
vim.pack.add {
  { src = 'https://github.com/kdheepak/lazygit.nvim',  version = 'a04ad0dbc725134edbee3a5eea29290976695357' },
  { src = 'https://github.com/sindrets/diffview.nvim', version = '4516612fe98ff56ae0415a259ff6361a89419b0a' },
}

require('diffview').setup({})

local map = vim.keymap.set
map('n', '<leader>gg', '<cmd>LazyGit<cr>',                  { desc = 'LazyGit' })
map('n', '<leader>gd', '<cmd>DiffviewOpen<cr>',             { desc = 'Diffview (all changes)' })
map('n', '<leader>gh', '<cmd>DiffviewFileHistory %<cr>',    { desc = 'Diffview file history' })
map('n', '<leader>gH', '<cmd>DiffviewFileHistory<cr>',      { desc = 'Diffview history (repo)' })
