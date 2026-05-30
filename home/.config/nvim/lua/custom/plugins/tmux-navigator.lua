-- vim-tmux-navigator — seamless C-h/j/k/l between nvim splits and tmux panes.
-- Required by the cheatsheet ("Move between splits/tmux panes: Ctrl+h/j/k/l").
--
-- IMPORTANT: kickstart binds <C-h/j/k/l> to plain window navigation
-- (init.lua:226-229). Once this plugin is loaded its commands take precedence
-- because we re-map below.
vim.pack.add {
  { src = 'https://github.com/christoomey/vim-tmux-navigator', version = 'e41c431a0c7b7388ae7ba341f01a0d217eb3a432' },
}

local map = vim.keymap.set
map('n', '<C-h>', '<cmd>TmuxNavigateLeft<cr>',  { desc = 'Pane left (tmux-aware)' })
map('n', '<C-j>', '<cmd>TmuxNavigateDown<cr>',  { desc = 'Pane down (tmux-aware)' })
map('n', '<C-k>', '<cmd>TmuxNavigateUp<cr>',    { desc = 'Pane up (tmux-aware)' })
map('n', '<C-l>', '<cmd>TmuxNavigateRight<cr>', { desc = 'Pane right (tmux-aware)' })
