-- mason-tool-installer — bulk-install LSPs/formatters/linters that mason
-- wouldn't auto-install on its own. Kickstart configures mason itself
-- (init.lua mason setup) but doesn't bulk-install.
vim.pack.add {
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
    version = '443f1ef8b5e6bf47045cb2217b6f748a223cf7dc' },
}

require('mason-tool-installer').setup({
  ensure_installed = {
    -- LSPs
    'lua-language-server',
    'rust-analyzer',
    'pyright',
    'ruff',
    'vtsls',
    'json-lsp',
    'yaml-language-server',
    'taplo',
    'terraform-ls',
    'dockerfile-language-server',
    'marksman',
    -- Formatters
    'stylua',
    'prettier',
    'shfmt',
    'black',
    -- Linters
    'shellcheck',
    'eslint_d',
    -- Debug adapters
    'codelldb', -- Rust/C/C++ DAP adapter (used by rustaceanvim debuggables)
  },
  auto_update = false,
  run_on_start = true,
})
