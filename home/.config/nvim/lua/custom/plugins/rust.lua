-- ============================================================================
-- Rust — "perfect stack": rustaceanvim (rust-analyzer bridge) + neotest + dap.
-- ============================================================================
--
-- Layers (most are shared with the rest of the config, not Rust-specific):
--   LSP/runnables/debuggables : mrcjkb/rustaceanvim  (this file)
--   Completion                : saghen/blink.cmp     (init.lua SECTION 7)
--   Debugger engine           : mfussenegger/nvim-dap (kickstart debug.lua)
--   DAP adapter               : codelldb              (installed via mason-tools.lua)
--   Syntax/folding            : nvim-treesitter       (init.lua SECTION 8)
--   Test UI                   : nvim-neotest/neotest  (this file, w/ rustaceanvim adapter)
--
-- IMPORTANT: rustaceanvim configures rust-analyzer ITSELF. Do NOT add
-- `rust_analyzer` to the `servers` table in init.lua or call vim.lsp.enable on
-- it — that would start a second, conflicting client. (It's commented out there.)
--
-- Keymaps (Rust buffers):
--   <leader>rr  :RustLsp runnables     (pick & run bins/tests/examples)
--   <leader>rd  :RustLsp debuggables   (pick & debug via codelldb)
--   <leader>ra  :RustLsp codeAction    (grouped rust-analyzer actions)
--   <leader>rm  :RustLsp expandMacro   (recursively expand macro under cursor)
--   <leader>rh  :RustLsp hover actions (rich hover; press again to enter)
--   <leader>rR  :RustLsp openCargo     (jump to Cargo.toml)
-- Test (neotest, any language with an adapter; here Rust via rustaceanvim):
--   <leader>nn nearest test   <leader>nf file   <leader>ns summary
--   <leader>no output         <leader>nw watch nearest
-- (neotest lives under <leader>n to avoid the <leader>t "toggle" namespace,
--  which kickstart/gitsigns already own: <leader>tb blame, <leader>tw word-diff,
--  <leader>th inlay hints, etc.)

-- ── rustaceanvim ────────────────────────────────────────────────────────────
-- Configure BEFORE the plugin loads: rustaceanvim reads vim.g.rustaceanvim.
-- We attach Rust keymaps on LspAttach for filetype rust.
vim.g.rustaceanvim = {
  -- Plugin-wide tools options can go here (e.g. float_win_config).
  tools = {},
  -- rust-analyzer server settings.
  server = {
    default_settings = {
      ['rust-analyzer'] = {
        cargo = { allFeatures = true },
        check = { command = 'clippy' }, -- use clippy for diagnostics
        procMacro = { enable = true },
      },
    },
  },
  -- DAP: rustaceanvim auto-detects codelldb installed by mason. No config needed
  -- here as long as codelldb is on disk (see mason-tools.lua ensure_installed).
  dap = {},
}

vim.pack.add {
  -- Pin to the stable 5.x range; rustaceanvim follows neovim's lsp API closely.
  { src = 'https://github.com/mrcjkb/rustaceanvim', version = vim.version.range '5.*' },
}
-- rustaceanvim is a "plugin, not a plugin": no require().setup{}. It activates
-- itself for Rust filetypes once installed and vim.g.rustaceanvim is set above.

-- Rust keymaps via a FileType autocmd (not server.on_attach), so they exist in
-- every Rust buffer even if rust-analyzer is still starting or unhealthy. The
-- :RustLsp commands are provided by rustaceanvim regardless of LSP state.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  group = vim.api.nvim_create_augroup('rust-keymaps', { clear = true }),
  callback = function(ev)
    local function m(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = 'Rust: ' .. desc })
    end
    m('<leader>rr', '<cmd>RustLsp runnables<cr>', '[R]unnables')
    m('<leader>rd', '<cmd>RustLsp debuggables<cr>', '[D]ebuggables')
    m('<leader>ra', '<cmd>RustLsp codeAction<cr>', 'Code [A]ction (grouped)')
    m('<leader>rm', '<cmd>RustLsp expandMacro<cr>', 'Expand [M]acro')
    m('<leader>rh', '<cmd>RustLsp hover actions<cr>', '[H]over actions')
    m('<leader>rR', '<cmd>RustLsp openCargo<cr>', 'Open Ca[R]go.toml')
  end,
})

-- ── neotest (test runner UI) + rustaceanvim's neotest adapter ────────────────
vim.pack.add {
  { src = 'https://github.com/nvim-neotest/neotest' },
  { src = 'https://github.com/nvim-neotest/nvim-nio' }, -- (also pulled by dap-ui)
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
}

-- Set up neotest. Guarded + retried because on a FRESH install vim.pack may
-- still be downloading neotest/rustaceanvim when this file first runs, so the
-- require would error and abort the rest of the file. We try now, and if it
-- fails, retry once everything is loaded (VimEnter).
local function setup_neotest()
  local ok_n, neotest = pcall(require, 'neotest')
  if not ok_n then return false end
  local adapters = {}
  local ok_a, rust_adapter = pcall(require, 'rustaceanvim.neotest')
  if ok_a then
    -- rustaceanvim ships a neotest adapter: wires `cargo test`/`cargo nextest`
    -- trees into the neotest UI. Add more adapters here later (e.g.
    -- neotest-python) — neotest is language-agnostic.
    table.insert(adapters, rust_adapter)
  end
  neotest.setup { adapters = adapters }
  return true
end

if not setup_neotest() then
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function() vim.schedule(setup_neotest) end,
  })
end

-- Keymaps require neotest lazily, so they're safe to bind even before setup.
local neotest = function() return require 'neotest' end
local map = vim.keymap.set
map('n', '<leader>nn', function() neotest().run.run() end, { desc = '[N]eotest: [N]earest' })
map('n', '<leader>nf', function() neotest().run.run(vim.fn.expand '%') end, { desc = '[N]eotest: [F]ile' })
map('n', '<leader>ns', function() neotest().summary.toggle() end, { desc = '[N]eotest: [S]ummary' })
map('n', '<leader>no', function() neotest().output.open { enter = true } end, { desc = '[N]eotest: [O]utput' })
map('n', '<leader>nw', function() neotest().watch.toggle(vim.fn.expand '%') end, { desc = '[N]eotest: [W]atch file' })
