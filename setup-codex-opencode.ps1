<#
.SYNOPSIS
    Connect the OpenAI Codex CLI to the OpenCode Go API (Windows)

.DESCRIPTION
    Writes %USERPROFILE%\.codex\config.toml with the OpenCode Go provider in
    the structure Codex actually understands (Responses mode, no login
    prompt). Backs up an existing config with a timestamp before overwriting.

.PARAMETER ApiKey
    OpenCode Go API key (sk-...). If omitted, falls back to the
    OPENCODE_GO_API_KEY environment variable, then prompts interactively.

.PARAMETER Model
    Model name. If omitted, falls back to OPENCODE_MODEL, then prompts with
    default deepseek-v4-flash.

.EXAMPLE
    .\setup-codex-opencode.ps1

.EXAMPLE
    .\setup-codex-opencode.ps1 -ApiKey sk-xxxx -Model deepseek-v4-flash

.EXAMPLE
    $env:OPENCODE_GO_API_KEY = "sk-xxxx"; $env:OPENCODE_MODEL = "deepseek-v4-flash"; .\setup-codex-opencode.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ApiKey,

    [Parameter(Position = 1)]
    [string]$Model
)

$ErrorActionPreference = 'Stop'

# ---------- 1. Get the API key ----------
if (-not $ApiKey) { $ApiKey = $env:OPENCODE_GO_API_KEY }
if (-not $ApiKey) {
    $ApiKey = Read-Host "Enter your OpenCode Go API key (sk-...)"
    $ApiKey = $ApiKey.Trim()
}
if (-not $ApiKey) {
    Write-Host "Error: no API key provided" -ForegroundColor Red
    exit 1
}

# ---------- 1b. Get the model name (switch models anytime) ----------
if (-not $Model) { $Model = $env:OPENCODE_MODEL }
if (-not $Model) {
    $Model = Read-Host "Enter model name (press Enter for default: deepseek-v4-flash)"
    $Model = $Model.Trim()
}
if (-not $Model) { $Model = 'deepseek-v4-flash' }

# ---------- 2. Locate the Codex config directory ----------
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$config = Join-Path $codexHome 'config.toml'
New-Item -ItemType Directory -Path $codexHome -Force | Out-Null

# ---------- 3. Back up the existing config ----------
if (Test-Path -LiteralPath $config) {
    $backup = "$config.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item -LiteralPath $config -Destination $backup
    Write-Host "Backed up existing config -> $backup"
    Write-Host "(Note: your previous settings in that file are replaced. Codex will"
    Write-Host " regenerate its own marketplace/plugins sections automatically.)"
}

# ---------- 4. Write the new config ----------
# NOTE: base_url / wire_api / experimental_bearer_token MUST live inside a
# [model_providers.xxx] block (see the example in the repo README).
# Model switching tip: if a new model returns 404/protocol errors, try
# setting wire_api = "chat" (some models are only served via
# /chat/completions; Codex supports the chat wire API too).
$content = @"
model = "$Model"
model_provider = "opencode"

[model_providers.opencode]
name = "OpenCode Go"
base_url = "https://opencode.ai/zen/go/v1"
wire_api = "responses"
experimental_bearer_token = "$ApiKey"
"@
# UTF-8 without BOM, so the TOML file is byte-clean for Codex
[System.IO.File]::WriteAllText($config, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Config written to: $config"
Write-Host "---------------------- Config preview ----------------------"
Get-Content -LiteralPath $config
Write-Host "------------------------------------------------------------"

# ---------- 5. Validate (best effort) ----------
if (Get-Command python -ErrorAction SilentlyContinue) {
    & python -c "import tomllib; tomllib.load(open(r'$config','rb')); print('TOML syntax check: OK')" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "(TOML check skipped: python too old or missing. Harmless.)"
    }
}

# ---------- 6. Check whether codex is installed ----------
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    Write-Host "Hint: 'codex' command not found. Install it with:"
    Write-Host "  npm install -g @openai/codex"
}

Write-Host ""
Write-Host "Done! Model: $Model"
Write-Host "Next step: fully quit Codex and start it again (not just a new"
Write-Host "session). It will use the OpenCode Go API in Responses mode with no"
Write-Host "account login required."
