-- pdfreader.nvim — read & navigate PDFs inside nvim.
--
-- Renders PDF pages inline via the Kitty graphics protocol (works in Ghostty).
-- Image rendering is delegated to snacks.nvim's image module, which is already
-- set up in init.lua (SECTION 4, `require('snacks').setup{ image = {...} }`).
--
-- REQUIREMENTS (all managed in the environment repo manifest.yaml):
--   • Ghostty (Kitty graphics protocol)          — terminal
--   • ImageMagick (`magick`)                      — image conversion
--   • Ghostscript (`gs`)                          — ImageMagick's PDF delegate
--   • poppler (`pdftoppm`/`pdfinfo`)              — PDF page rasterization
--   • tmux `allow-passthrough on` (~/.tmux.conf)  — lets graphics escapes through
-- If the terminal/deps are missing, pdfreader falls back to TEXT mode only.
--
-- TELESCOPE NOTE: upstream lists nvim-telescope/telescope.nvim as a dependency,
-- but ONLY for its two picker commands (:PDFReader showBookmarks /
-- showRecentBooks). This config migrated off telescope to snacks.picker, so
-- telescope is intentionally NOT installed. Everything else — opening PDFs,
-- page nav (n/p), zoom (z/q/e), view modes, autosave, :PDFReader setPage /
-- addBookmark / showToc — works without it. The two Telescope picker commands
-- will error; use :PDFReader setPage / addBookmark directly instead.
--
-- Pinned to release v0.1.7 (commit f8c0676) to match this config's
-- version-pinning convention.
vim.pack.add {
  { src = 'https://github.com/r-pletnev/pdfreader.nvim', version = 'f8c067648b0c0d332a8d241111787a6b4d7ba061' },
}

require('pdfreader').setup()

-- ── FIT-TO-WINDOW FIX ────────────────────────────────────────────────────
-- Symptom: PDF pages render "zoomed in" / overflowing with no side margins.
--
-- Cause: pdfreader's lua/pdfreader/image.lua pins a FIXED height on the snacks
-- image placement (Image.DEFAULT_SCALE = 60 → opts.height = 60) and never sets
-- width. snacks (image/placement.lua M:state) normally fits the image inside
-- BOTH the window width and height; but when opts.height is forced, it scales
-- the page to exactly 60 rows tall regardless of window size. For a portrait
-- page that makes it far wider than the window → horizontal overflow, no
-- margins, the "zoomed in" look.
--
-- Fix: override Image:display so that, at DEFAULT zoom (scale == DEFAULT_SCALE,
-- i.e. the user hasn't pressed z/q to zoom), we pass NO height/width and let
-- snacks fit the page to the window with correct aspect ratio and margins.
-- When the user explicitly zooms (book.scale set to something other than the
-- default), we honor it by passing height = scale, preserving z/q/e behavior.
--
-- This monkey-patch lives here (not in the vendored plugin) so it survives
-- plugin updates. If a future pdfreader release fixes this upstream, delete
-- this block.
do
  local Image = require('pdfreader.image')
  local snacks_image = require('snacks.image')

  function Image:display(buffer, scale)
    local opts = { auto_resize = nil }
    -- Only force a height when the user has actively zoomed (scale present AND
    -- different from the plugin default). Otherwise leave width/height unset so
    -- snacks fits the page to the window.
    if scale and scale ~= Image.DEFAULT_SCALE then
      opts.height = scale
    end
    snacks_image.placement.new(buffer, self.src, opts)

    vim.bo[buffer].modifiable = true
    vim.bo[buffer].modified = true
    vim.api.nvim_buf_set_lines(buffer, -1, -1, false, { '' })
    vim.bo[buffer].modifiable = false
    vim.bo[buffer].modified = false
  end
end

-- ── ZOOM STEP SIZE ───────────────────────────────────────────────────────
-- pdfreader's built-in z/q zoom in ±5 image-rows, which is imperceptible on a
-- full page (fitted pages are ~40-50 rows tall, so +5 barely changes size and
-- can look like "nothing happened"). Bump DEFAULT_SCALE's step by making the
-- zoom functions move in bigger increments. We patch Book:zoom_in/out to step
-- by a larger amount so each z/q press is clearly visible.
--
-- NOTE ON THE KEYS: they are PLAIN normal-mode presses — `z`, `q`, `e` — NOT
-- `:z` / `:q` / `:e` commands. (`:q` would quit the window!) They only work
-- while the cursor is IN the PDF buffer, and only after pdfreader's BufEnter
-- autocmd has attached them. If pressing them does nothing, run
-- `:verbose nmap z` on the PDF buffer to confirm the buffer-local map exists.
do
  local Book = require('pdfreader.book')
  local Image = require('pdfreader.image')
  local STEP = 20 -- rows per zoom press (was 5); makes zoom clearly visible

  function Book:zoom_in()
    local scale = self.scale or Image.DEFAULT_SCALE
    self.scale = scale + STEP
  end

  function Book:zoom_out()
    local scale = self.scale or Image.DEFAULT_SCALE
    self.scale = math.max(10, scale - STEP)
  end
end
