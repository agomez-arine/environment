-- Render markdown nicely in normal-mode buffers (collapses to source on insert).
vim.pack.add {
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
    version = '5adf0895310c1904e5abfaad40a2baad7fe44a07' },
}

-- latex = disabled: avoids checkhealth warnings about the missing latex
-- tree-sitter parser + utftex/latex2text (we don't render LaTeX in markdown).
require('render-markdown').setup({
  latex = { enabled = false },
})
