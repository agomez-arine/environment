-- ~/.config/nvim/lua/custom/keymaps.lua
-- Layered ON TOP of kickstart's defaults. Strategy: where kickstart and my
-- cheatsheet conflict, kickstart wins; cheatsheet bindings are added as
-- ALIASES on non-conflicting prefixes. See:
-- ~/arine-brain/Nvim keymap comparison - me vs dax vs gcav.md

local map = vim.keymap.set
local function nm(lhs, rhs, desc) map('n', lhs, rhs, { desc = desc, silent = true }) end
local function vm(lhs, rhs, desc) map('v', lhs, rhs, { desc = desc, silent = true }) end
local function im(lhs, rhs, desc) map('i', lhs, rhs, { desc = desc, silent = true }) end

-- ── basics ──────────────────────────────────────────────────────────────
-- IMPORTANT: kickstart binds <leader>q to diagnostic loclist (init.lua:206).
-- Cheatsheet says <leader>q = quit all. Pick: keep kickstart's. Quit-all
-- becomes <leader>qq.
nm('<leader>qq', '<cmd>qa<CR>',          'Quit all')
nm('<C-s>',      '<cmd>write<CR>',        'Save')
nm('<leader>w',  '<cmd>write<CR>',        'Save (cheatsheet)')
nm('<leader>kd', '<cmd>nohlsearch<CR>',   'Clear search highlight (alias of <Esc>)')
im('jk',         '<Esc>',                 'Escape (insert)')
im(';;',         '<Esc>A;<Esc>',          'Append ;')
im(',,',         '<Esc>A,<Esc>',          'Append ,')

-- ── word wrap / format toggles ──────────────────────────────────────────
nm('<leader>uw', function() vim.opt.wrap = not vim.opt.wrap:get() end, 'Toggle wrap')
-- Format-on-save is OFF by default. This toggles it ON/OFF globally; conform's
-- format_on_save (init.lua SECTION 6) reads vim.g.autoformat_enabled.
nm('<leader>uf', function()
  vim.g.autoformat_enabled = not vim.g.autoformat_enabled
  vim.notify('format-on-save: ' .. (vim.g.autoformat_enabled and 'on' or 'off'))
end, 'Toggle format-on-save')

-- ── movement ────────────────────────────────────────────────────────────
nm('<C-d>', '<C-d>zz', 'Half page down (centered)')
nm('<C-u>', '<C-u>zz', 'Half page up (centered)')
nm('n',     'nzzzv',   'Next match (centered)')
nm('N',     'Nzzzv',   'Prev match (centered)')
map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- Home-row line motions: H = first non-blank (^), L = end of line ($).
-- Replaces clumsy 0/$ (especially $ = Shift+4). Mapped in normal/visual/
-- operator-pending so dH, yL, vH, etc. all work. Raw 0 still goes to col-0.
-- NOTE: this overrides vim's default H/L (screen High/Low) — use gg/G/zt/zb
-- for screen positioning. Buffer nav (formerly <S-h>/<S-l>) now lives on
-- [b/]b only (see buffers section).
map({ 'n', 'x', 'o' }, 'H', '^', { desc = 'Start of line (first non-blank)', silent = true })
map({ 'n', 'x', 'o' }, 'L', '$', { desc = 'End of line', silent = true })

-- ── visual / editing ────────────────────────────────────────────────────
vm('<A-j>', ":m '>+1<CR>gv=gv", 'Move selection down')
vm('<A-k>', ":m '<-2<CR>gv=gv", 'Move selection up')
nm('<A-j>', '<cmd>m .+1<CR>==', 'Move line down')
nm('<A-k>', '<cmd>m .-2<CR>==', 'Move line up')
vm('<', '<gv', 'Indent left, keep selection')
vm('>', '>gv', 'Indent right, keep selection')
map({ 'n', 'x' }, '<leader>p', [["0p]], { desc = 'Paste from yank register' })
map('x', '<leader>P', [["_dP]], { desc = 'Paste over selection (no yank)' })

-- ── window / split nav: KICKSTART DEFAULT (init.lua:226-229) ────────────
-- <C-h/j/k/l> are kickstart's plain window navigation.
-- vim-tmux-navigator extends them to also jump tmux panes (see
-- custom/plugins/tmux-navigator.lua). DO NOT rebind here.

-- ── quickfix navigation: cheatsheet wants <C-j>/<C-k> but those are taken
--    by kickstart for window nav. Use <leader>cn / <leader>cp instead.
nm('<leader>cn', '<cmd>cnext<CR>',     'Next quickfix')
nm('<leader>cp', '<cmd>cprevious<CR>', 'Prev quickfix')

-- ── buffers ─────────────────────────────────────────────────────────────
-- kickstart leaves buffer nav unbound. <leader><leader> IS kickstart's
-- buffer picker (init.lua:518) — DO NOT override.
-- NOTE: <S-h>/<S-l> are NO LONGER buffer nav — they're now line start/end
-- (see movement section). Buffer prev/next lives on [b/]b only.
nm('[b',         '<cmd>bprevious<CR>', 'Prev buffer')
nm(']b',         '<cmd>bnext<CR>',     'Next buffer')
nm('<leader>bd', '<cmd>bdelete<CR>',   'Delete buffer')
nm('<leader>bb', '<cmd>e #<CR>',       'Switch to last buffer')

-- ── diagnostics ─────────────────────────────────────────────────────────
-- kickstart already binds ]d/[d via vim.diagnostic defaults (they auto-open
-- the float on jump, see init.lua jump.on_jump).
-- Show the diagnostic float for the CURRENT line without jumping. <leader>d
-- is taken (Debug group, init.lua:375), so this lives on <leader>cd to match
-- the <leader>c* "code" family (cr/ca/cf above).
nm('<leader>cd', vim.diagnostic.open_float, 'Show line diagnostic float')

-- ── LSP ALIASES: cheatsheet uses old g* style; kickstart uses new gr* ───
-- BOTH coexist. kickstart's bindings remain functional. These alias the
-- cheatsheet style on top.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local opts = function(desc) return { buffer = ev.buf, desc = desc, silent = true } end
    map('n', 'gd', vim.lsp.buf.definition,      opts('Go to definition (alias of grd)'))
    map('n', 'gD', vim.lsp.buf.declaration,     opts('Go to declaration (alias of grD)'))
    map('n', 'gr', vim.lsp.buf.references,      opts('Go to references (alias of grr)'))
    map('n', 'gI', vim.lsp.buf.implementation,  opts('Go to implementation (alias of gri)'))
    map('n', 'gy', vim.lsp.buf.type_definition, opts('Go to type definition (alias of grt)'))
    map('n', '<leader>cr', vim.lsp.buf.rename,      opts('Rename (alias of grn)'))
    map('n', '<leader>ca', vim.lsp.buf.code_action, opts('Code action (alias of gra)'))
    map('n', '<leader>cf', function() require('conform').format { async = true } end, opts('Format (alias of <leader>f)'))
  end,
})

-- ── picker ALIASES (snacks.picker) ───────────────────────────────────────
-- kickstart's <leader>s* namespace (init.lua) stays canonical.
-- Cheatsheet's <leader>f* aliases live alongside.
-- DO NOT touch <leader><leader> (kickstart buffer picker) or <leader>/
-- (kickstart current-buffer fuzzy find).
-- Pickers are provided by snacks.picker (migrated from telescope.builtin).
local function pick(sym)
  return function() require('snacks').picker[sym]() end
end
nm('<leader>fa', pick('files'),       'Find all files (alias of <leader>sf)')
nm('<leader>fi', pick('grep'),        'Find in files (alias of <leader>sg)')
nm('<leader>fr', pick('recent'),      'Recent files (alias of <leader>s.)')
nm('<leader>fh', pick('help'),        'Help tags (alias of <leader>sh)')
nm('<leader>fk', pick('keymaps'),     'Keymaps (alias of <leader>sk)')
nm('<leader>fc', pick('commands'),    'Commands (alias of <leader>sc)')
nm('<leader>fd', pick('diagnostics'), 'Diagnostics (alias of <leader>sd)')
nm('<leader>fg', pick('git_status'),  'Git status')
-- dax-style: C-p for git_files
nm('<C-p>',      pick('git_files'),   'Git files')

-- ── git hunk navigation aliases (kickstart uses ]c/[c, cheatsheet uses ]h/[h)
-- ]c/[c are still functional; these aliases honor the cheatsheet.
nm(']h', "<cmd>lua require('gitsigns').nav_hunk('next')<CR>", 'Next hunk (alias of ]c)')
nm('[h', "<cmd>lua require('gitsigns').nav_hunk('prev')<CR>", 'Prev hunk (alias of [c)')

-- ── file explorer alias (cheatsheet says <leader>e, kickstart uses \) ────
nm('<leader>e', '<cmd>Neotree toggle<CR>', 'File explorer (alias of \\)')

-- ── dax cherry-pick: run shell cmd in current file's dir ────────────────
local function run_in_dir()
  vim.ui.input({ prompt = 'Command: ' }, function(cmd)
    if not cmd or cmd == '' then return end
    local dir = vim.fn.expand '%:p:h'
    vim.system({ 'sh', '-c', cmd }, { cwd = dir, text = true }, function(result)
      vim.schedule(function()
        local out = (result.stdout or '') .. (result.stderr or '')
        local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
        vim.notify(('[%s] $ %s\n%s'):format(vim.fn.fnamemodify(dir, ':~'), cmd, out), level)
      end)
    end)
  end)
end
nm('<leader>R', run_in_dir, "Run cmd in file's dir")
vm('<leader>R', run_in_dir, "Run cmd in file's dir")
