-- Harpoon — quick file marks.
--
-- IMPORTANT: kickstart's gitsigns owns the entire <leader>h* namespace
-- (~12 bindings under "[H]unk"). Cheatsheet originally said <leader>ha /
-- <leader>hh; moved to dax's <leader>a (add) and <leader>m (mark menu) to
-- avoid the collision. <leader>1..4 unchanged.
-- NOTE: this config uses the harpoon v2 API (harpoon:setup{}, harpoon:list(),
-- harpoon.ui:toggle_quick_menu). That API only exists on the `harpoon2` branch.
-- The old pin tracked v1 (master), which crashed with
--   E474: attempt to dump function reference (refresh_projects_b4update)
-- whenever a buffer left (e.g. opening neo-tree). Track harpoon2 instead.
vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
}

local harpoon = require('harpoon')
harpoon:setup({})

local map = vim.keymap.set
  map('n', '<leader>a',  function() harpoon:list():add() end,                       { desc = 'Harpoon add' })
map('n', '<leader>m',  function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
map('n', '<C-e>',      function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu (C-e)' })
map('n', '<leader>1',  function() harpoon:list():select(1) end, { desc = 'Harpoon 1' })
map('n', '<leader>2',  function() harpoon:list():select(2) end, { desc = 'Harpoon 2' })
map('n', '<leader>3',  function() harpoon:list():select(3) end, { desc = 'Harpoon 3' })
map('n', '<leader>4',  function() harpoon:list():select(4) end, { desc = 'Harpoon 4' })
