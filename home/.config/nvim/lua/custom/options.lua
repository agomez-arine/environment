-- ~/.config/nvim/lua/custom/options.lua
-- Overrides on top of kickstart's `vim.o.*` defaults. Loaded LAST in init.lua.
-- Anything kickstart already sets the way you want, don't repeat here — that
-- way you get kickstart's docs as the source of truth and only override what
-- diverges.

-- ── visual ───────────────────────────────────────────────────────────────
vim.o.relativenumber = true              -- kickstart leaves this off; you want it
vim.o.numberwidth = 4
vim.o.scrolloff = 8                      -- kickstart sets 10; you prefer 8
vim.o.sidescrolloff = 8
vim.o.termguicolors = true

-- ── indenting ────────────────────────────────────────────────────────────
-- guess-indent.nvim (already enabled by kickstart) sniffs per-buffer; these
-- are the fallbacks for new/unknown files.
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.shiftround = true

-- ── search ───────────────────────────────────────────────────────────────
vim.o.hlsearch = true                    -- keep matches highlighted after Enter;
                                         -- <Esc> is mapped to :nohlsearch (init.lua:186)
                                         -- to clear them on demand. n/N step matches.
vim.o.incsearch = true                   -- also highlight the match while typing

-- ── files / persistence ──────────────────────────────────────────────────
vim.o.swapfile = false
vim.o.backup = false
-- undodir defaults to stdpath('state')/undo already, and persistent undo only
-- takes effect with `undofile = true` (not set here). Left explicit + commented
-- as a reminder: uncomment both lines below to enable persistent undo history.
-- vim.o.undofile = true
-- vim.o.undodir = vim.fn.stdpath('state') .. '/undo'
vim.o.autoread = true
vim.o.exrc = true                        -- per-project .nvim.lua / .nvimrc
vim.o.secure = true

-- ── ui ───────────────────────────────────────────────────────────────────
vim.o.wrap = false                       -- kickstart leaves wrap on; toggle via <leader>uw
vim.o.linebreak = true
vim.o.pumheight = 12
vim.opt.fillchars = { eob = ' ' }
vim.o.updatetime = 50                    -- kickstart sets 250; you want snappier

-- ── folding ──────────────────────────────────────────────────────────────
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- ── autocmds ─────────────────────────────────────────────────────────────
-- Reload buffers when file changes on disk (matches my tmux + git workflow)
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  pattern = '*',
  command = 'checktime',
})

-- ── disable unused remote-plugin providers ────────────────────────────────
-- All our plugins are Lua; we don't use legacy python/ruby/perl/node remote
-- plugin hosts. Disabling silences the optional-provider checkhealth warnings
-- and shaves a little startup. (LSP/formatters use the tools directly, not
-- these providers.)
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Strip trailing whitespace on save (skip with `let b:noformat = 1`)
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function()
    if vim.b.noformat then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
