-- Lualine + bufferline. Replaces kickstart's mini.statusline (we don't disable
-- mini.statusline; lualine just takes over the statusline slot).
vim.pack.add {
  { src = 'https://github.com/nvim-lualine/lualine.nvim',   version = '131a558e13f9f28b15cd235557150ccb23f89286' },
  { src = 'https://github.com/akinsho/bufferline.nvim',     version = '655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3' },
}

require('lualine').setup({
  options = {
    -- 'auto' derives the statusline palette from the active colorscheme, so the
    -- bar follows whatever theme you pick in themes.lua (oasis, kanagawa, nord,
    -- onedark, tokyonight, ...) and updates live when you switch.
    theme = 'auto',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    globalstatus = true,
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { { 'filename', path = 1 } },
    lualine_x = { 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})

require('bufferline').setup({
  options = {
    diagnostics = 'nvim_lsp',
    always_show_bufferline = false,
    offsets = { { filetype = 'neo-tree', text = 'Explorer', separator = true } },
  },
})
