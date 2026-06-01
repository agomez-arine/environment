-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

local plugins = {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

if vim.g.have_nerd_font then
  table.insert(plugins, 'https://github.com/nvim-tree/nvim-web-devicons') -- not strictly required, but recommended
end

vim.pack.add(plugins)

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    -- Do NOT hijack the window when opening a directory (e.g. `nvim .`).
    -- 'open_current' rendered the tree *in the main window*, which then
    -- coexisted with the managed sidebar opened by `\` / `<leader>e`,
    -- producing two separate tree views. We open the sidebar explicitly
    -- on startup instead (see the VimEnter autocmd below).
    hijack_netrw_behavior = 'disabled',
    -- Keep the tree in sync with on-disk changes made OUTSIDE neo-tree
    -- (git checkout, terminal `mv`/`rm`, LSP code actions, `:e!`, etc.).
    -- neo-tree does NOT track buffer reloads like `:e!` on its own, so without
    -- a watcher the tree shows a stale snapshot. The libuv watcher uses the OS
    -- file-notification API (kqueue on macOS) — this is the standard, recommended
    -- approach and updates the tree automatically with no polling.
    use_libuv_file_watcher = true,
    -- Show dotfiles / hidden + gitignored entries by default (the "N hidden
    -- directories" placeholder otherwise hides .config, .ssh, etc.).
    -- Toggle live in the tree with `H`.
    filtered_items = {
      visible = true, -- show filtered items (don't collapse into "N hidden")
      hide_dotfiles = false, -- show .dotfiles / .dotdirs
      hide_gitignored = false, -- show gitignored files too
    },
    window = {
      position = 'right',
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
  -- Force the sidebar to the right for every source (filesystem, buffers, git).
  window = {
    position = 'right',
  },
}

-- Belt-and-suspenders for the one case the libuv watcher can miss: changes made
-- while nvim is fully backgrounded/suspended (e.g. `Ctrl-Z`, run a git checkout
-- in the shell, then `fg`). On regaining focus, nudge neo-tree to refresh so the
-- tree reflects reality. Cheap and only fires on FocusGained.
vim.api.nvim_create_autocmd('FocusGained', {
  group = vim.api.nvim_create_augroup('kickstart-neotree-focus-refresh', { clear = true }),
  callback = function()
    pcall(function()
      require('neo-tree.sources.manager').refresh 'filesystem'
    end)
  end,
})

-- When nvim is launched on a directory (e.g. `nvim .`), open neo-tree as a
-- proper sidebar and put a normal empty buffer in the main window — instead
-- of letting the directory buffer get hijacked into the main window. This
-- guarantees a single, consistent tree (the sidebar) on every launch.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('kickstart-neotree-dir-startup', { clear = true }),
  callback = function()
    local argv = vim.fn.argv()
    if #argv == 1 and vim.fn.isdirectory(argv[1]) == 1 then
      -- Replace the directory buffer in the main window with an empty buffer,
      -- then open the neo-tree sidebar AND focus it (cursor lands in the tree
      -- on `nvim .`). Use `focus` rather than `show` — `show` reveals the
      -- sidebar but leaves the cursor in the main window.
      vim.cmd 'enew'
      vim.cmd('Neotree focus dir=' .. vim.fn.fnameescape(argv[1]))
    end
  end,
})
