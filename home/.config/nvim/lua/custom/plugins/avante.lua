-- avante.nvim — Cursor-style AI assistant inside Neovim. LAZY-LOADED.
--
-- Managed via Neovim's native vim.pack (same pattern as harpoon.lua), NOT the
-- environment manifest.yaml — manifest only tracks system-level CLI tools.
--
-- WHY THIS FILE IS STRUCTURED THE WAY IT IS
-- Eagerly requiring + setting up avante at startup cost ~2.6s (it pulls in a
-- Rust FFI library plus nui and re-runs render-markdown setup). vim.pack has no
-- declarative lazy-loading (no cmd/keys/ft fields like lazy.nvim), so we defer
-- by hand: avante.nvim and nui.nvim are only added to the session the first
-- time you invoke an Avante command or its keymap. Everything heavy now happens
-- on first use, not on launch.
--
-- NOTE ON DEPENDENCIES: plenary, nvim-web-devicons and render-markdown are
-- already loaded eagerly by other plugins in this config (neo-tree, harpoon,
-- rust, and render-markdown.lua), so there is nothing to gain by deferring
-- them here — we only defer the two pieces unique to avante: avante.nvim and
-- nui.nvim.
--
-- Provider: AWS Bedrock. We do NOT set BEDROCK_KEYS, so avante falls back to
-- the default AWS credential provider chain — it uses whatever AWS_PROFILE is
-- active in your shell. Requires the AWS CLI (installed via mise) and Bedrock
-- model access. Switch providers at runtime with :AvanteSwitchProvider.
--
-- Model `us.anthropic.claude-opus-4-8` is a Bedrock cross-region inference
-- profile (verified accessible in us-east-1); matches the id used in
-- ~/.config/opencode/opencode.json.

-- ===========================================================================
-- 1. Async build hook — runs ONLY on install/update, never on normal startup.
--    Replaces the old startup-time globpath/glob build scan.
--    vim.pack fires PackChanged after a plugin's on-disk state changes; the
--    event-data exposes `spec.name`, `path`, and `kind` ("install"|"update"|
--    "delete"). Must be registered BEFORE the deferred vim.pack.add runs.
-- ===========================================================================
vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Build avante.nvim native component on install/update',
  group = vim.api.nvim_create_augroup('AvanteBuildHook', { clear = true }),
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if name ~= 'avante.nvim' or (kind ~= 'install' and kind ~= 'update') then
      return
    end
    vim.notify('avante.nvim: building native component (make)…', vim.log.levels.INFO)
    vim.system({ 'make' }, { cwd = ev.data.path }, function(obj)
      vim.schedule(function()
        if obj.code == 0 then
          vim.notify('avante.nvim built successfully', vim.log.levels.INFO)
        else
          vim.notify('avante.nvim build failed:\n' .. (obj.stderr or ''), vim.log.levels.ERROR)
        end
      end)
    end)
  end,
})

-- ===========================================================================
-- 2. Modern curl resolver. avante's Bedrock provider signs requests with
--    curl's native AWS SigV4, which needs curl >= 8.10.0. macOS ships an older
--    system curl (8.7.x). We point Neovim at a modern keg-only curl from brew.
--    This used to run synchronously in global scope on EVERY startup (a `brew
--    --prefix curl` shell-out). It now runs once, lazily, inside the loader.
-- ===========================================================================
local function use_modern_curl()
  local candidates = {
    '/opt/homebrew/opt/curl/bin/curl', -- macOS Apple Silicon
    '/usr/local/opt/curl/bin/curl', -- macOS Intel
    '/home/linuxbrew/.linuxbrew/opt/curl/bin/curl', -- Linuxbrew
  }
  -- Also try `brew --prefix curl` (covers custom prefixes). Only reached on
  -- first Avante use, so its cost is off the startup hot path.
  if vim.fn.executable('brew') == 1 then
    local prefix = vim.fn.system({ 'brew', '--prefix', 'curl' }):gsub('%s+$', '')
    if vim.v.shell_error == 0 and prefix ~= '' then
      table.insert(candidates, 1, prefix .. '/bin/curl')
    end
  end
  for _, bin in ipairs(candidates) do
    if vim.fn.executable(bin) == 1 then
      vim.g.plenary_curl_bin_path = bin
      local bindir = vim.fn.fnamemodify(bin, ':h')
      vim.env.PATH = bindir .. ':' .. vim.env.PATH
      return bin
    end
  end
  return nil
end

-- ===========================================================================
-- 3. Deferred loader. Runs the first time you use Avante. Idempotent.
--    Note: we use our own guard flag (`_avante_lazy_init`) — NOT
--    `vim.g.avante_loaded`, which is avante's own internal sentinel set by its
--    plugin/avante.lua. vim.pack.add also auto-runs :packadd, which sources
--    plugin/avante.lua and registers the real Avante* commands for us.
-- ===========================================================================
local function init_avante()
  if vim.g._avante_lazy_init then
    return
  end
  vim.g._avante_lazy_init = true

  use_modern_curl()

  -- Add the pieces unique to avante. After init.lua finishes sourcing,
  -- vim.pack.add defaults to load=true, so these are loaded immediately.
  -- (Re-adding an already-present plugin is a no-op, so this is safe.)
  vim.pack.add {
    { src = 'https://github.com/MunifTanjim/nui.nvim' },
    { src = 'https://github.com/yetone/avante.nvim' },
  }

  -- render-markdown is already set up by render-markdown.lua at startup; extend
  -- its config so the Avante sidebar renders, without clobbering the existing
  -- (latex-disabled, pinned) setup. setup() merges over the prior call.
  require('render-markdown').setup {
    file_types = { 'markdown', 'Avante' },
  }

  require('avante').setup {
    instructions_file = 'avante.md',
    provider = 'bedrock',
    providers = {
      bedrock = {
        model = 'us.anthropic.claude-opus-4-8',
        aws_region = 'us-east-1',
        -- aws_profile intentionally omitted: avante uses the default AWS
        -- credential chain, which honors the active AWS_PROFILE in your shell.
        timeout = 30000,
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 20480,
        },
      },
    },
    behaviour = {
      auto_suggestions = false,
    },
  }
end

-- ===========================================================================
-- 4. Command stubs (tripwires). The full set of Avante* commands defined by
--    avante's plugin/avante.lua. Each stub deletes ALL stubs, loads the plugin
--    (which registers the real commands), then replays the original call with
--    its arguments / range preserved.
-- ===========================================================================
local avante_cmds = {
  'AvanteAsk',
  'AvanteChat',
  'AvanteChatNew',
  'AvanteToggle',
  'AvanteBuild',
  'AvanteEdit',
  'AvanteRefresh',
  'AvanteFocus',
  'AvanteSwitchProvider',
  'AvanteSwitchSelectorProvider',
  'AvanteSwitchInputProvider',
  'AvanteClear',
  'AvanteShowRepoMap',
  'AvanteModels',
  'AvanteACPModels',
  'AvanteACPModes',
  'AvanteHistory',
  'AvanteStop',
}

for _, name in ipairs(avante_cmds) do
  vim.api.nvim_create_user_command(name, function(opts)
    -- Remove every stub so the real commands (registered by packadd) win.
    for _, c in ipairs(avante_cmds) do
      pcall(vim.api.nvim_del_user_command, c)
    end

    init_avante()

    -- Replay the original invocation, preserving range and bang.
    vim.cmd {
      cmd = opts.name,
      args = opts.fargs,
      bang = opts.bang,
      range = (opts.range > 0) and { opts.line1, opts.line2 } or nil,
    }
  end, { nargs = '*', bang = true, range = true, desc = 'Avante (lazy loader)' })
end

-- ===========================================================================
-- 5. Keymap tripwire. Mirrors avante's default <leader>aa = toggle. Deletes
--    itself, loads the plugin, then performs the toggle.
-- ===========================================================================
vim.keymap.set({ 'n', 'v' }, '<leader>aa', function()
  pcall(vim.keymap.del, { 'n', 'v' }, '<leader>aa')
  init_avante()
  vim.cmd('AvanteToggle')
end, { desc = 'Toggle Avante (lazy loader)' })
