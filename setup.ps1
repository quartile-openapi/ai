#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap quartile-dev-toolkit: validates env var, installs UV, and installs the qtk CLI.

.DESCRIPTION
    Prerequisites (must be installed before running this script):
      - Node.js (npx)
      - uv
      See docs/prerequisites.md for installation instructions.

    Steps:
      1. Validates UV_EXTRA_INDEX_URL is set
      2. Checks that Node.js (npx) is installed
      3. Checks that uv is installed
      4. Installs qtk CLI from Azure Artifacts feed

    After this, use the CLI to install components:
      qtk install --level global
      qtk install --level project -p di-gathering
      qtk doctor

.PARAMETER FeedUrl
    Optional override for the feed URL.
    If omitted, uses the UV_EXTRA_INDEX_URL environment variable.

.EXAMPLE
    # Recommended: set UV_EXTRA_INDEX_URL first (see README.md), then run:
    .\setup.ps1

    # Or pass the URL directly:
    .\setup.ps1 -FeedUrl "https://quartiledigital:<PAT>@pkgs.dev.azure.com/quartiledigital/QD_AI/_packaging/ai-prod/pypi/simple/"
#>

param(
    [string]$FeedUrl
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Quartile Dev Toolkit - Setup ===" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: UV_EXTRA_INDEX_URL ───────────────────────────────────────────
Write-Host "[1/4] Checking UV_EXTRA_INDEX_URL..." -ForegroundColor Yellow

if ($FeedUrl) {
    # Persist the provided URL
    [System.Environment]::SetEnvironmentVariable("UV_EXTRA_INDEX_URL", $FeedUrl, "User")
    $env:UV_EXTRA_INDEX_URL = $FeedUrl
    Write-Host "    Set from -FeedUrl parameter (persisted to User scope)" -ForegroundColor Green
} elseif ($env:UV_EXTRA_INDEX_URL) {
    Write-Host "    Found in current session" -ForegroundColor Green
} else {
    # Check persistent User var (may not be loaded in current session)
    $persistedValue = [System.Environment]::GetEnvironmentVariable("UV_EXTRA_INDEX_URL", "User")
    if ($persistedValue) {
        $env:UV_EXTRA_INDEX_URL = $persistedValue
        Write-Host "    Found in User environment variables" -ForegroundColor Green
    } else {
        Write-Host "    ERROR: UV_EXTRA_INDEX_URL is not set." -ForegroundColor Red
        Write-Host ""
        Write-Host "    Set it before running this script (see README.md for PAT instructions):" -ForegroundColor DarkGray
        Write-Host '    [System.Environment]::SetEnvironmentVariable("UV_EXTRA_INDEX_URL", "<FEED_URL>", "User")' -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "    Or pass it directly:" -ForegroundColor DarkGray
        Write-Host '    .\setup.ps1 -FeedUrl "<FEED_URL>"' -ForegroundColor DarkGray
        exit 1
    }
}

# ── Step 2: Node.js (npx) ─────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/4] Checking Node.js (npx)..." -ForegroundColor Yellow

if (Get-Command npx -ErrorAction SilentlyContinue) {
    $npxVersion = (npx --version 2>$null)
    Write-Host "    Found: npx $npxVersion" -ForegroundColor Green
} else {
    Write-Host "    ERROR: Node.js (npx) is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "    Install with: choco install nodejs-lts" -ForegroundColor DarkGray
    Write-Host "    or download from https://nodejs.org/ (LTS)" -ForegroundColor DarkGray
    exit 1
}

# ── Step 3: UV ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/4] Checking UV..." -ForegroundColor Yellow

if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "    Found: $(uv --version)" -ForegroundColor Green
} else {
    Write-Host "    ERROR: uv is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "    Install with:" -ForegroundColor DarkGray
    Write-Host '    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"' -ForegroundColor DarkGray
    exit 1
}

# ── Step 4: CLI ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/4] Installing qtk CLI..." -ForegroundColor Yellow

$prevPref = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$output = uv tool install quartile-dev-toolkit --force 2>&1
$ErrorActionPreference = $prevPref
$output | ForEach-Object {
    $line = $_.ToString()
    if ($line -match "error|Error") { Write-Host "    $line" -ForegroundColor Red }
}

# Discover uv tool bin dir and ensure it's in session PATH
$uvBinDir = $null
try { $uvBinDir = (uv tool dir --bin 2>$null); if ($uvBinDir) { $uvBinDir = $uvBinDir.Trim() } } catch {}
if (-not $uvBinDir) { $uvBinDir = "$env:USERPROFILE\.local\bin" }

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($env:Path -notlike "*$uvBinDir*") { $env:Path = "$uvBinDir;$env:Path" }

if (Get-Command qtk -ErrorAction SilentlyContinue) {
    Write-Host "    OK: $(qtk --version)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "    WARN: qtk was installed but is not yet available in this session." -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "    The binary was placed in: $uvBinDir" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    To fix, do ONE of the following:" -ForegroundColor DarkGray
    Write-Host "      1. Close and reopen your terminal" -ForegroundColor DarkGray
    Write-Host "      2. Run manually:  uv tool run --from quartile-dev-toolkit qtk --version" -ForegroundColor DarkGray
}

# ── Done ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Setup complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "    Next steps:" -ForegroundColor Cyan
Write-Host "      qtk install --level global              Install skills/agents/hooks globally"
Write-Host "      qtk install --level project -p NAME     Install for a specific project"
Write-Host "      qtk doctor                              Verify configuration"
Write-Host ""
Write-Host "    Other commands:" -ForegroundColor Cyan
Write-Host "      qtk sync       Upgrade to latest version"
Write-Host "      qtk list       Show installed components"
Write-Host "      qtk remove     Remove installed components"
Write-Host ""
