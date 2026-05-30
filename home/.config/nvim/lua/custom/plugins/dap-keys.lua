-- DAP cheatsheet aliases.
--
-- kickstart.plugins.debug already binds:
--   F5 = continue, F1 = step into, F2 = step over, F3 = step out,
--   F7 = toggle dapui, <leader>b = toggle breakpoint, <leader>B = conditional bp
--
-- The original cheatsheet used <leader>tb (toggle breakpoint), <leader>tr
-- (continue), <leader>du (UI), <leader>de (eval). <leader>tb collides with
-- kickstart's gitsigns ("toggle blame line"), so DAP moves to a clean
-- <leader>d* namespace. Update the README cheatsheet accordingly.

local function dap()  return require('dap') end
local function dapui() return require('dapui') end
local map = vim.keymap.set

map('n', '<leader>db', function() dap().toggle_breakpoint() end,                { desc = 'Debug: toggle breakpoint' })
map('n', '<leader>dB', function()
  vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(c)
    if c then dap().set_breakpoint(c) end
  end)
end, { desc = 'Debug: conditional breakpoint' })
map('n', '<leader>dc', function() dap().continue() end,                          { desc = 'Debug: continue' })
map('n', '<leader>dr', function() dap().continue() end,                          { desc = 'Debug: run/continue (alias)' })
map('n', '<leader>dn', function() dap().step_over() end,                         { desc = 'Debug: step over (next)' })
map('n', '<leader>di', function() dap().step_into() end,                         { desc = 'Debug: step into' })
map('n', '<leader>do', function() dap().step_out() end,                          { desc = 'Debug: step out' })
map('n', '<leader>dt', function() dap().terminate() end,                         { desc = 'Debug: terminate' })
map('n', '<leader>du', function() dapui().toggle() end,                          { desc = 'Debug: UI toggle' })
map({ 'n', 'v' }, '<leader>de', function() dapui().eval() end,                   { desc = 'Debug: eval' })