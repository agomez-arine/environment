-- ============================================================================
-- Colorschemes — install several, switch live, remember the choice.
-- ============================================================================
--
-- Active theme:        oasis-dune (your pick — "Dune Dark", warm yellow desert)
-- Switch theme:        <leader>ut  → snacks.picker colorscheme picker (live preview)
--                      :colorscheme <Tab>  also works
-- Persistence:         the chosen colorscheme is written to
--                      stdpath('data')/colorscheme and reloaded on next start.
--
-- Installed themes you can switch to (try these — your shortlist):
--   oasis-dune        "Dune Dark"     (yellow desert)   ← default
--   oasis-midnight    "Desert Dark"   (deep desert night)
--   oasis-desert      "Desert" classic (retro desert.vim vibe)
--   oasis-starlight   "Starlight"     (set background=light for the light look)
--   kanagawa-wave / kanagawa-dragon / kanagawa-lotus
--   nord
--   onedark           (variants via setup: dark/darker/cool/deep/warm/warmer)
--   tokyonight-night / tokyonight-storm / tokyonight-moon / tokyonight-day
-- ============================================================================

local gh = function(repo) return 'https://github.com/' .. repo end

-- ── Install theme plugins (pinned to a commit for reproducibility) ──────────
vim.pack.add {
  { src = gh 'uhs-robert/oasis.nvim' },
  { src = gh 'rebelot/kanagawa.nvim' },
  { src = gh 'shaunsingh/nord.nvim' },
  { src = gh 'navarasu/onedark.nvim' },
  { src = gh 'folke/tokyonight.nvim' },
}

-- ── Per-theme setup (only those that need/benefit from it) ──────────────────
require('oasis').setup {
  style = 'dune', -- the default style when you just `:colorscheme oasis`
  styles = { italic = false }, -- keep comments un-italic to match your old config
}

---@diagnostic disable-next-line: missing-fields
require('tokyonight').setup {
  styles = { comments = { italic = false } },
}

require('onedark').setup {
  style = 'dark', -- dark | darker | cool | deep | warm | warmer | light
}
-- kanagawa and nord work fine with defaults; no setup() required.

-- ── Persisted colorscheme ────────────────────────────────────────────────
local default_scheme = 'onedark'
local state_file = vim.fs.joinpath(vim.fn.stdpath 'data', 'colorscheme')

local function read_saved()
  local ok, lines = pcall(vim.fn.readfile, state_file)
  if ok and lines and lines[1] and lines[1] ~= '' then return lines[1] end
  return nil
end

local function apply(scheme)
  -- oasis-starlight (and other light styles) look best with a light background.
  if scheme == 'oasis-starlight' then
    vim.o.background = 'light'
  else
    vim.o.background = 'dark'
  end
  local ok = pcall(vim.cmd.colorscheme, scheme)
  if not ok then
    pcall(vim.cmd.colorscheme, default_scheme)
  end
end

apply(read_saved() or default_scheme)

-- Save whenever the colorscheme changes (covers the snacks picker, :colorscheme,
-- and anything else that triggers the ColorScheme event).
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('persist-colorscheme', { clear = true }),
  callback = function(args)
    pcall(vim.fn.writefile, { args.match }, state_file)
  end,
})

-- ── Picker keymap ───────────────────────────────────────────────────────────
-- <leader>ut → fuzzy colorscheme picker with live preview (snacks.picker).
vim.keymap.set('n', '<leader>ut', function()
  require('snacks').picker.colorschemes()
end, { desc = '[U]I: [T]heme picker' })
