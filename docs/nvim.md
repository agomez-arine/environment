# neovim tips

Config at `home/.config/nvim/` — **kickstart.nvim** (upstream) + your overrides under `lua/custom/`. Migrated from LazyVim 2026-05-30.

For keymap reference see [`cheatsheet.md`](cheatsheet.md). For the full keymap audit + comparison vs dax/gcav see `~/arine-brain/engineering/tooling/Nvim keymap comparison - me vs dax vs gcav.md`.

## Quick start

```sh
nvim                 # opens empty buffer
nvim file.py         # opens file
nvim .               # opens neo-tree
```

First launch: `vim.pack` (built into Neovim 0.12+) auto-installs plugins. Press Enter through any "These plugins will be installed" prompts.

## Layout

```
home/.config/nvim/
├── init.lua                    # kickstart upstream + tail-end requires for custom/
├── lua/kickstart/              # kickstart's bundled plugins, untouched
│   ├── health.lua
│   └── plugins/
│       ├── autopairs.lua
│       ├── debug.lua           # nvim-dap (enabled)
│       ├── gitsigns.lua        # gitsigns recommended keymaps (enabled)
│       ├── indent_line.lua     # (enabled)
│       ├── lint.lua            # nvim-lint (enabled)
│       └── neo-tree.lua        # file explorer (enabled)
└── lua/custom/                 # MY overrides — edit here
    ├── options.lua             # vim.o overrides on top of kickstart's defaults
    ├── keymaps.lua             # cheatsheet bindings (aliases, not overrides)
    └── plugins/
        ├── init.lua            # auto-loads every *.lua in this dir (patched for symlinks)
        ├── harpoon.lua
        ├── dap-keys.lua        # <leader>d* aliases on top of kickstart's debug.lua
        ├── git.lua             # lazygit + diffview
        ├── tmux-navigator.lua  # extends <C-h/j/k/l> to span nvim+tmux
        ├── undotree.lua
        ├── trouble.lua
        ├── statusline.lua      # lualine + bufferline
        ├── render-markdown.lua
        ├── mason-tools.lua     # bulk-install LSPs/formatters/linters
        ├── vim-be-good.lua     # :VimBeGood
        └── themes.lua          # managed by another agent — DO NOT EDIT HERE
```

## Package manager: vim.pack (NOT lazy.nvim)

Kickstart-current uses Neovim 0.12+'s built-in `vim.pack` API. There's no `lazy-lock.json`, no `:Lazy` UI. Plugins are added with:

```lua
vim.pack.add { 'https://github.com/owner/repo' }
-- or with a pinned commit / tag / version range:
vim.pack.add { { src = 'https://github.com/owner/repo', version = 'COMMIT_SHA' } }
```

To update plugins:

```vim
:lua vim.pack.update()
```

To add a plugin: drop a new file in `lua/custom/plugins/<name>.lua` calling `vim.pack.add { ... }` and any `require('<plugin>').setup{...}`. The auto-loader in `lua/custom/plugins/init.lua` picks it up at next launch.

## Keymap layering strategy

`lua/custom/keymaps.lua` runs **after** kickstart's setup. The strategy is **alias, don't override**:

- Kickstart's defaults stay canonical.
- Cheatsheet bindings are added as duplicate handlers on non-conflicting prefixes.
- Where my cheatsheet would have collided with kickstart (e.g. `<leader>q`, `<leader><leader>`, `<leader>/`, `<leader>tb`, `<C-h/j/k/l>`), the cheatsheet binding moved.

See `cheatsheet.md` for what changed.

## Custom keymaps

Edit `lua/custom/keymaps.lua` for global maps. For LSP/buffer-local maps use the `LspAttach` autocmd already in that file.

```lua
-- example: add a command at the bottom of custom/keymaps.lua
vim.keymap.set('n', '<leader>X', '<cmd>echo "hi"<CR>', { desc = 'Greet' })
```

## tmux integration

`<C-h/j/k/l>` navigates between nvim splits AND tmux panes seamlessly. Plugin: `christoomey/vim-tmux-navigator` (nvim side, in `lua/custom/plugins/tmux-navigator.lua`). The tmux side lives in `~/environment/home/.tmux.conf` (see `docs/tmux.md`).

## Common workflows

### Open project + find file

```sh
cd ~/arine-code/arine-server
nvim
# then: <leader>sf or <leader>fa, type filename, Enter
```

### Search across project

`<leader>sg` (or `<leader>fi`) opens telescope live_grep. Type pattern. Live preview. Enter to open.

### View diffs

```vim
:DiffviewOpen          " visual git diff for whole repo
:DiffviewFileHistory % " history of current file
```

Or with bindings: `<leader>gd` / `<leader>gh`.

### Jump between buffers

- `<leader><leader>` — kickstart's buffer picker.
- harpoon: `<leader>a` to add, `<leader>m` (or `<C-e>`) to open menu, `<leader>1..4` to jump.

### Switch theme

`<leader>ut` opens telescope colorscheme picker. Choice persists across restarts. Managed by `lua/custom/plugins/themes.lua`.

## Troubleshooting

### Plugins acting up

```vim
:lua vim.pack.update()         " update everything
:lua vim.pack.update({}, { offline = true })  " just refresh state, no fetch
```

### LSP not working

```vim
:checkhealth lsp
:Mason                         " install/update language servers
:MasonToolsInstall             " install all tools listed in mason-tools.lua
```

### Reset nvim state (nuke installed plugins)

```sh
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
nvim                           # next launch reinstalls everything
```

This nukes plugin installs but NOT your config.

## Where things live

| File | Purpose | In repo? |
|---|---|---|
| `~/.config/nvim/` | Config (symlinked to `home/.config/nvim/`) | ✅ tracked |
| `~/.local/share/nvim/` | Plugin installs (vim.pack site/pack) | ❌ generated |
| `~/.local/state/nvim/` | Sessions, undo history, swap | ❌ generated |
| `~/.cache/nvim/` | LSP / treesitter caches | ❌ generated |

## Migration history

- 2026-05-30: LazyVim → kickstart.nvim. See `~/arine-brain/engineering/tooling/2026-05-30 - Nvim migration to kickstart.md` for the full migration log + rationale.
- Pre-2026-05-30: LazyVim distribution at `~/dotfiles/nvim/` (now archived to `~/dotfiles-archive-2026-05-30/`).
