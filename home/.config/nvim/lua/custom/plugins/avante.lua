-- avante.nvim — Cursor-style AI assistant inside Neovim.
--
-- Managed via Neovim's native vim.pack (same pattern as harpoon.lua), NOT the
-- environment manifest.yaml — manifest only tracks system-level CLI tools.
--
-- Requirements (verified at install): Neovim 0.11+ (we run 0.12.x) and a build
-- toolchain. avante ships a Rust component; `make` fetches a prebuilt binary via
-- curl/tar by default, or builds from source if you set BUILD_FROM_SOURCE=true
-- (cargo is available on this machine).
--
-- Provider: AWS Bedrock. We do NOT set BEDROCK_KEYS, so avante falls back to
-- the default AWS credential provider chain — it uses whatever AWS_PROFILE is
-- active in your shell (env vars, ~/.aws/config + SSO, etc.). No secrets live in
-- this file. Requires the AWS CLI (installed via mise) and Bedrock model access
-- for the model below. Switch providers at runtime with :AvanteSwitchProvider.
--
-- Model `us.anthropic.claude-opus-4-8` is a Bedrock cross-region inference
-- profile (verified accessible in us-east-1); matches the id used in
-- ~/.config/opencode/opencode.json.

-- Required + recommended dependencies. plenary and nui are hard requirements;
-- render-markdown gives readable output in the Avante sidebar; web-devicons is
-- used for the file selector UI.
vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/yetone/avante.nvim' },
}

-- avante.nvim has a native build step. vim.pack does not run build hooks, so
-- run `make` in the plugin dir on install/update if the compiled artifact is
-- missing. This is idempotent: it no-ops once the build output exists.
local function ensure_avante_built()
  local pack_path = vim.fn.stdpath('data') .. '/site/pack/core/opt/avante.nvim'
  if vim.fn.isdirectory(pack_path) == 0 then
    -- Fall back to scanning the pack tree for the plugin location.
    local found = vim.fn.globpath(vim.fn.stdpath('data') .. '/site/pack', '*/*/avante.nvim', false, true)
    if #found > 0 then pack_path = found[1] end
  end
  if vim.fn.isdirectory(pack_path) == 0 then return end

  -- A successful build leaves a compiled library under build/.
  if vim.fn.glob(pack_path .. '/build/*.so') ~= ''
    or vim.fn.glob(pack_path .. '/build/*.dylib') ~= '' then
    return
  end

  vim.notify('avante.nvim: building native component (make)…', vim.log.levels.INFO)
  local out = vim.fn.system({ 'make', '-C', pack_path })
  if vim.v.shell_error ~= 0 then
    vim.notify('avante.nvim build failed:\n' .. out, vim.log.levels.ERROR)
  end
end
ensure_avante_built()

-- avante's Bedrock provider signs requests with curl's native AWS SigV4, which
-- needs curl >= 8.10.0. macOS ships an older system curl (8.7.x). We install a
-- modern keg-only curl via brew (tracked in manifest.yaml). Point Neovim at it:
--   1. plenary (avante's HTTP layer) honors vim.g.plenary_curl_bin_path.
--   2. avante's own version GATE shells out to bare `curl`, so the modern curl
--      must also be first on PATH inside this process.
-- We resolve the path dynamically so this works on any machine without
-- hardcoding a brew prefix. Falls back silently to system curl if not found.
local function use_modern_curl()
  local candidates = {
    '/opt/homebrew/opt/curl/bin/curl',          -- macOS Apple Silicon
    '/usr/local/opt/curl/bin/curl',             -- macOS Intel
    '/home/linuxbrew/.linuxbrew/opt/curl/bin/curl', -- Linuxbrew
  }
  -- Also try `brew --prefix curl` if brew is on PATH (covers custom prefixes).
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
      -- Prepend to PATH for this nvim process so avante's bare `curl` check
      -- resolves to the modern binary. Does not affect the system shell.
      vim.env.PATH = bindir .. ':' .. vim.env.PATH
      return bin
    end
  end
  return nil
end
use_modern_curl()

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
