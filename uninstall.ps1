#Requires -Version 5.1
<#
.SYNOPSIS
    Uninstall quartile-dev-toolkit: removes the qtk CLI, env var, and optionally global components.

.DESCRIPTION
    Steps:
      0. (Optional) Remove globally installed components (skills, agents, hooks, settings, MCPs)
      1. Uninstalls qtk CLI via uv tool uninstall
      2. Removes UV_EXTRA_INDEX_URL from User environment variables

.EXAMPLE
    .\uninstall.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Quartile Dev Toolkit - Uninstall ===" -ForegroundColor Cyan
Write-Host ""

# ── Confirmation ─────────────────────────────────────────────────────
$confirm = Read-Host "This will uninstall quartile-dev-toolkit. Continue? (y/N)"
if ($confirm -notin @("y", "Y", "yes", "Yes")) {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

# ── Optional: Clean up global components ─────────────────────────────
Write-Host ""
$cleanup = Read-Host "Remove globally installed components (~/.claude/skills, agents, hooks, settings, MCPs)? (y/N)"
if ($cleanup -in @("y", "Y", "yes", "Yes")) {
    Write-Host ""
    Write-Host "Removing global components..." -ForegroundColor Yellow

    # Try via qtk CLI first
    $qtkAvailable = Get-Command qtk -ErrorAction SilentlyContinue
    if ($qtkAvailable) {
        try {
            $prevPref = $ErrorActionPreference
            $ErrorActionPreference = "SilentlyContinue"
            $output = qtk remove projects --level global --yes 2>&1
            $ErrorActionPreference = $prevPref
            $output | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        } catch {
            Write-Host "    WARN: qtk remove failed, falling back to manual cleanup" -ForegroundColor DarkYellow
        }
    }

    # Direct filesystem cleanup for anything remaining
    $claudeDir = Join-Path $env:USERPROFILE ".claude"
    foreach ($sub in @("skills", "agents", "hooks")) {
        $path = Join-Path $claudeDir $sub
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force
            Write-Host "    Removed $path" -ForegroundColor Green
        } else {
            Write-Host "    $sub`: not found (clean)" -ForegroundColor DarkGray
        }
    }

    # settings.json
    $settingsFile = Join-Path $claudeDir "settings.json"
    if (Test-Path $settingsFile) {
        Remove-Item $settingsFile -Force
        Write-Host "    Removed settings.json" -ForegroundColor Green
    } else {
        Write-Host "    settings.json: not found (clean)" -ForegroundColor DarkGray
    }

    # MCP configs: remove mcpServers key only, preserve other config
    foreach ($mcpFile in @(
        (Join-Path $env:USERPROFILE ".claude.json"),
        (Join-Path $env:USERPROFILE ".cursor\mcp.json")
    )) {
        if (Test-Path $mcpFile) {
            try {
                $content = Get-Content $mcpFile -Raw | ConvertFrom-Json
                if ($content.PSObject.Properties.Name -contains "mcpServers") {
                    $content.PSObject.Properties.Remove("mcpServers")
                    $content | ConvertTo-Json -Depth 10 | Set-Content $mcpFile -Encoding UTF8
                    Write-Host "    Removed mcpServers from $mcpFile" -ForegroundColor Green
                } else {
                    Write-Host "    $mcpFile`: no mcpServers (clean)" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "    WARN: Could not clean $mcpFile" -ForegroundColor DarkYellow
            }
        } else {
            Write-Host "    $mcpFile`: not found (clean)" -ForegroundColor DarkGray
        }
    }
}

# ── Step 1: Uninstall CLI ────────────────────────────────────────────
Write-Host ""
Write-Host "[1/2] Uninstalling qtk CLI..." -ForegroundColor Yellow

if (Get-Command uv -ErrorAction SilentlyContinue) {
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $output = uv tool uninstall quartile-dev-toolkit 2>&1
    $uvExitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevPref
    $output | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    if ($uvExitCode -eq 0) {
        Write-Host "    OK: qtk CLI removed" -ForegroundColor Green
    } else {
        Write-Host "    Not installed or already removed" -ForegroundColor DarkGray
    }
} else {
    Write-Host "    WARN: uv not found. Cannot uninstall via uv tool." -ForegroundColor DarkYellow
    Write-Host "    If qtk was installed, it may need manual removal." -ForegroundColor DarkGray
}

# ── Step 2: Remove UV_EXTRA_INDEX_URL ────────────────────────────────
Write-Host ""
Write-Host "[2/2] Removing UV_EXTRA_INDEX_URL..." -ForegroundColor Yellow

$current = [System.Environment]::GetEnvironmentVariable("UV_EXTRA_INDEX_URL", "User")
if ($current) {
    [System.Environment]::SetEnvironmentVariable("UV_EXTRA_INDEX_URL", $null, "User")
    $env:UV_EXTRA_INDEX_URL = $null
    Write-Host "    Removed from User environment variables" -ForegroundColor Green
} else {
    Write-Host "    Not found (already clean)" -ForegroundColor DarkGray
}

# ── Done ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Uninstall complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "    Restart your terminal for environment changes to take effect." -ForegroundColor Cyan
Write-Host ""
