<#
.SYNOPSIS
    One-line installer for Windows Application Updater

.DESCRIPTION
    Downloads and executes the Windows Application Updater from GitHub.
    Designed for deployment via Rippling MDM.

.PARAMETER AutoReboot
    Pass through to main script - enables automatic reboot if updates require it.

.EXAMPLE
    irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex

.NOTES
    One-line command for Rippling MDM:
    powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"
#>

param(
    [switch]$AutoReboot
)

$ErrorActionPreference = 'Stop'

# Configuration
$RepoUrl = "https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main"
$ScriptName = "Update-WindowsApps.ps1"
$TempDir = Join-Path $env:TEMP "WindowsAppUpdater_$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows Application Updater - Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Cleanup function
function Remove-TempFiles {
    try {
        if (Test-Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # Ignore cleanup errors
    }
}

# Register cleanup
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Remove-TempFiles }

try {
    Write-Host "Downloading update script..." -ForegroundColor Cyan

    # Create temp directory
    New-Item -Path $TempDir -ItemType Directory -Force | Out-Null

    # Download script
    $scriptPath = Join-Path $TempDir $ScriptName
    $downloadUrl = "$RepoUrl/$ScriptName"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $scriptPath)
        $webClient.Dispose()
    } catch {
        Write-Error "Failed to download script from $downloadUrl : $($_.Exception.Message)"
        exit 1
    }

    if (-not (Test-Path $scriptPath)) {
        Write-Error "Script download failed - file not found at $scriptPath"
        exit 1
    }

    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Running update script..." -ForegroundColor Cyan
    Write-Host ""

    # Build arguments
    $arguments = @()
    if ($AutoReboot) {
        $arguments += '-AutoReboot'
    }

    # Execute script
    & $scriptPath @arguments

    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) { $exitCode = 0 }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan

    exit $exitCode

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup
    Remove-TempFiles
}
