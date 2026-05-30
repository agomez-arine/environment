# Cheatsheet

Quick reference for tmux + neovim + zsh + git as configured in this repo.
Last updated: 2026-05-30 (post LazyVim → kickstart.nvim migration).

For the full keymap comparison and conflict-resolution rationale, see
`~/arine-brain/engineering/tooling/Nvim keymap comparison - me vs dax vs gcav.md`.

---

## Tmux

Prefix: `Ctrl+Space`

| Action | Binding |
|---|---|
| Reload config | `Ctrl+Space r` |
| New window | `Ctrl+Space c` |
| Split vertical (side by side) | `Ctrl+Space \|` |
| Split horizontal (top/bottom) | `Ctrl+Space -` |
| Close pane | `Ctrl+Space x` |
| Cycle pane layouts | `Ctrl+Space Space` |
| Swap pane position | `Ctrl+Space {` / `Ctrl+Space }` |
| Rename session | `Ctrl+Space $` |
| Rename window | `Ctrl+Space ,` |
| Detach | `Ctrl+Space d` |
| Next window | `Ctrl+Space n` |
| Previous window | `Ctrl+Space p` |
| Jump to window # | `Ctrl+Space [0-9]` |
| Interactive session list | `Ctrl+Space s` |

**Pane navigation (no prefix; works in tmux AND nvim via vim-tmux-navigator):**

| Action | Binding |
|---|---|
| Move left | `Ctrl+h` |
| Move down | `Ctrl+j` |
| Move up | `Ctrl+k` |
| Move right | `Ctrl+l` |

**Copy mode:**

| Action | Binding |
|---|---|
| Enter copy mode | `Ctrl+Space [` |
| Start selection | `v` (in copy mode) |
| Copy to clipboard | `y` (in copy mode) |

**Session management (shell):**

```bash
tmux new -s name              # New named session
tmux ls                       # List sessions
tmux a -t name                # Attach to session
tmux kill-session -t name     # Kill specific session
tmux kill-session -a          # Kill all EXCEPT current
tmux kill-server              # Kill ALL (nuclear)
tmux rename-session new-name  # Rename current
```

---

## Neovim (kickstart.nvim)

Leader: `Space`

> 🗒 **Migrated from LazyVim 2026-05-30.** Several bindings moved to avoid
> conflicts with kickstart's defaults. Old → new mappings called out below
> with ⚠️.

### Basics

| Action | Binding |
|---|---|
| Save | `Ctrl+s`, `:w`, or `<leader>w` |
| Close window/quit | `:q` |
| Close buffer | `<leader>bd` or `:bd` |
| Force quit | `:q!` |
| ⚠️ Quit all (was `<leader>q`) | `<leader>qq` |
| Save and quit | `:wq` |
| Reload file (discard) | `:e!` |
| Undo | `u` |
| Redo | `Ctrl+r` |
| Toggle wrap | `<leader>uw` |
| Toggle format-on-save | `<leader>uf` |
| Diagnostic loclist | `<leader>q` (kickstart owns this) |

### Insert-mode shortcuts

| Action | Binding |
|---|---|
| Escape | `Esc` or `jk` |
| Append `;` | `;;` |
| Append `,` | `,,` |

### Movement

| Action | Binding |
|---|---|
| End of line | `$` |
| Beginning of line | `0` |
| Top of file | `gg` |
| Bottom of file | `G` |
| Half page down (centered) | `Ctrl+d` |
| Half page up (centered) | `Ctrl+u` |
| Center on next/prev match | `n` / `N` (auto-centered) |
| Move line up (normal) | `Alt+k` |
| Move line down (normal) | `Alt+j` |

### Selection & copy

| Action | Binding |
|---|---|
| Visual mode (char) | `v` |
| Visual mode (line) | `V` |
| Visual mode (block) | `Ctrl+v` |
| Yank (copy) | `y` |
| Yank line | `yy` |
| Cut line | `dd` |
| Delete word | `diw` (inner) / `daw` (with space) |
| Paste | `p` |
| Paste from yank reg (no clobber) | `<leader>p` |
| Paste over selection (no yank) | `<leader>P` (visual) |
| Move sel down | `Alt+j` (visual) |
| Move sel up | `Alt+k` (visual) |
| Indent + reselect | `>gv` / `<gv` (visual) |
| Toggle comment | `gcc` (line) / `gc` (visual) |
| Indent / dedent | `>>` / `<<` |

### Files / search (telescope)

Kickstart uses `<leader>s*` for search. My `<leader>f*` cheatsheet aliases work alongside.

| Action | Binding |
|---|---|
| ⚠️ Find files (was `<leader><leader>`) | `<leader>sf` or `<leader>fa` |
| ⚠️ Live grep (was `<leader>/`) | `<leader>sg` or `<leader>fi` |
| ⚠️ Buffer picker (was `<leader>,`) | `<leader><leader>` |
| Git files | `Ctrl+p` |
| Recent files | `<leader>fr` (alias of `<leader>s.`) |
| Help tags | `<leader>fh` (alias of `<leader>sh`) |
| Keymaps picker | `<leader>fk` (alias of `<leader>sk`) |
| Commands picker | `<leader>fc` (alias of `<leader>sc`) |
| Search current word | `<leader>sw` |
| Resume last search | `<leader>sr` |
| Diagnostics | `<leader>fd` (alias of `<leader>sd`) |
| Git status | `<leader>fg` |
| Search nvim config | `<leader>sn` |
| Fuzzy find current buffer | `<leader>/` (kickstart's binding) |
| Search in open files | `<leader>s/` |

### Buffers

| Action | Binding |
|---|---|
| Next buffer | `]b` or `Shift+l` |
| Prev buffer | `[b` or `Shift+h` |
| Delete buffer | `<leader>bd` |
| Last buffer | `<leader>bb` |

### Harpoon (quick file marks)

⚠️ **Moved out of `<leader>h*` namespace** to avoid gitsigns collision.

| Action | Binding |
|---|---|
| ⚠️ Add file (was `<leader>ha`) | `<leader>a` |
| ⚠️ Toggle menu (was `<leader>hh`) | `<leader>m` or `Ctrl+e` |
| Jump to harpoon 1..4 | `<leader>1` through `<leader>4` |

### File explorer (neo-tree)

| Action | Binding |
|---|---|
| Reveal current file | `\` |
| Toggle explorer | `<leader>e` |
| Add file/folder (in tree) | `a` (trailing `/` for folder) |
| Rename | `r` |
| Delete | `d` |

### LSP

Both kickstart's `gr*` namespace AND my single-letter aliases work:

| Action | Binding |
|---|---|
| Go to definition | `gd` (or `grd`) |
| Go to declaration | `gD` (or `grD`) |
| Go to references | `gr` (or `grr`) |
| Go to implementation | `gI` (or `gri`) |
| Go to type definition | `gy` (or `grt`) |
| Hover documentation | `K` |
| Document symbols | `gO` |
| Workspace symbols | `gW` |
| Rename symbol | `<leader>cr` (or `grn`) |
| Code action | `<leader>ca` (or `gra`) |
| Format buffer | `<leader>cf` (or `<leader>f`) |

### Git (gitsigns + lazygit + diffview)

#### Hunks

`<leader>h*` is gitsigns' namespace.

| Action | Binding |
|---|---|
| Next hunk | `]c` or `]h` |
| Prev hunk | `[c` or `[h` |
| Stage hunk | `<leader>hs` |
| Reset hunk | `<leader>hr` |
| Stage buffer | `<leader>hS` |
| Reset buffer | `<leader>hR` |
| Preview hunk | `<leader>hp` |
| Blame line | `<leader>hb` |
| Diff against index | `<leader>hd` |
| Diff against HEAD | `<leader>hD` |
| Toggle blame line | `<leader>tb` |
| Toggle word diff | `<leader>tw` |

#### High-level

| Action | Binding |
|---|---|
| LazyGit | `<leader>gg` |
| Diffview (changes) | `<leader>gd` |
| Diffview file history | `<leader>gh` |
| Diffview repo history | `<leader>gH` |

### Diagnostics & Trouble

| Action | Binding |
|---|---|
| Next diagnostic | `]d` |
| Prev diagnostic | `[d` |
| Trouble (project) | `<leader>xx` |
| Trouble (buffer) | `<leader>xX` |
| Trouble symbols | `<leader>xs` |
| Trouble loclist | `<leader>xL` |
| Trouble qflist | `<leader>xQ` |

### Quickfix

⚠️ **Moved to `<leader>c*`** because kickstart owns `<C-j>`/`<C-k>` for window nav.

| Action | Binding |
|---|---|
| ⚠️ Next quickfix (was `<C-j>`) | `<leader>cn` |
| ⚠️ Prev quickfix (was `<C-k>`) | `<leader>cp` |

### DAP (debugging)

⚠️ **Moved to `<leader>d*` namespace** because kickstart owns `<leader>tb` for gitsigns blame.

| Action | Binding |
|---|---|
| ⚠️ Toggle breakpoint (was `<leader>tb`) | `<leader>db` (or `<leader>b`) |
| Conditional breakpoint | `<leader>dB` (or `<leader>B`) |
| ⚠️ Continue (was `<leader>tr`) | `<leader>dc` or `<leader>dr` (or `F5`) |
| Step over | `<leader>dn` (or `F2`) |
| Step into | `<leader>di` (or `F1`) |
| Step out | `<leader>do` (or `F3`) |
| Terminate | `<leader>dt` |
| Toggle DAP UI | `<leader>du` (or `F7`) |
| DAP eval | `<leader>de` |

### Tools

| Action | Binding |
|---|---|
| Undotree toggle | `<leader>U` |
| VimBeGood | `:VimBeGood` |
| Run cmd in file's dir | `<leader>R` |
| Mason (LSP installer) | `:Mason` |

### Surround / autopairs / textobjects (mini.nvim)

| Action | Binding |
|---|---|
| Add surround | `sa` |
| Delete surround | `sd` |
| Replace surround | `sr` |
| Find surround | `sf` |
| Highlight surround | `sh` |
| Inside text-object | `i*` (e.g. `vif`, `da)`) |
| Around text-object | `a*` |

### Tmux navigation

`Ctrl+h/j/k/l` move between nvim splits AND tmux panes. No prefix needed.

---

## Diff mode (vimdiff / `nvim -d`)

| Action | Binding |
|---|---|
| Open file diff | `nvim -d file1 file2` |
| Open diff split | `:vert diffsplit file2` |
| Next change | `]c` |
| Prev change | `[c` |
| Pull change from other file | `do` |
| Push change to other file | `dp` |
| Refresh diff after edits | `:diffupdate` |
| Exit diff mode | `:diffoff!` |

---

## Tips

- **Remap Caps Lock → Escape** in macOS: System Settings → Keyboard → Modifier Keys. Makes hitting Escape much easier.
- **`jk` in insert mode** also escapes — alternate to Caps Lock remap.
- **`<C-Space>`** triggers treesitter incremental selection. Press repeatedly to grow the selection.
- **Theme switching**: `<leader>ut` (telescope colorscheme picker, persisted across restarts).
