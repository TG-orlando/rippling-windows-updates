<#
.SYNOPSIS
    Windows Application and System Updater for Rippling MDM

.DESCRIPTION
    Automatically updates Windows applications via Chocolatey and installs Windows Updates.
    Designed for unattended execution via MDM systems like Rippling.

.PARAMETER AutoReboot
    If set, the PC will reboot automatically if updates require it.

.PARAMETER SkipChocolatey
    If set, skips Chocolatey package updates.

.PARAMETER SkipWindowsUpdate
    If set, skips Windows Update checks.

.EXAMPLE
    .\Update-WindowsApps.ps1
    Run with default settings (no auto-reboot)

.EXAMPLE
    .\Update-WindowsApps.ps1 -AutoReboot
    Run with automatic reboot if required

.NOTES
    Author: TG-orlando
    Version: 1.0.0
    Requires: PowerShell 5.1 or higher, Administrator privileges
#>

param(
    [switch]$AutoReboot,
    [switch]$SkipChocolatey,
    [switch]$SkipWindowsUpdate
)

# Script configuration
$Script:LogDir = "C:\ProgramData\Rippling\Logs"
$Script:LogFile = Join-Path $LogDir "WindowsAppUpdater_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Script:RebootRequired = $false

#region Logging Functions

function Initialize-Logging {
    if (-not (Test-Path $Script:LogDir)) {
        try {
            New-Item -Path $Script:LogDir -ItemType Directory -Force | Out-Null
        } catch {
            $Script:LogDir = $env:TEMP
            $Script:LogFile = Join-Path $Script:LogDir "WindowsAppUpdater_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        }
    }

    $logHeader = @"
========================================
Windows Application Updater
Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
User: $env:USERNAME
Computer: $env:COMPUTERNAME
PowerShell: $($PSVersionTable.PSVersion)
========================================
"@

    $logHeader | Out-File -FilePath $Script:LogFile -Encoding UTF8
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to log file
    $logMessage | Out-File -FilePath $Script:LogFile -Append -Encoding UTF8

    # Write to console with color
    switch ($Level) {
        'INFO'    { Write-Host $Message -ForegroundColor Cyan }
        'WARN'    { Write-Host $Message -ForegroundColor Yellow }
        'ERROR'   { Write-Host $Message -ForegroundColor Red }
        'SUCCESS' { Write-Host $Message -ForegroundColor Green }
    }
}

#endregion

#region Elevation

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Invoke-ElevateScript {
    if (Test-IsAdmin) {
        return $true
    }

    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow

    try {
        $scriptPath = $PSCommandPath
        if (-not $scriptPath) {
            $scriptPath = $MyInvocation.MyCommand.Path
        }

        if (-not $scriptPath -or -not (Test-Path $scriptPath)) {
            throw "Cannot determine script path for elevation"
        }

        # Determine PowerShell executable
        $psExe = if ($PSVersionTable.PSEdition -eq 'Core') {
            (Get-Process -Id $PID).Path
            if (-not $_) { Join-Path $PSHOME 'pwsh.exe' }
        } else {
            (Get-Process -Id $PID).Path
            if (-not $_) { Join-Path $PSHOME 'powershell.exe' }
        }

        if (-not (Test-Path $psExe)) {
            throw "Cannot find PowerShell executable"
        }

        # Build argument list
        $argList = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', "`"$scriptPath`""
        )

        if ($AutoReboot) { $argList += '-AutoReboot' }
        if ($SkipChocolatey) { $argList += '-SkipChocolatey' }
        if ($SkipWindowsUpdate) { $argList += '-SkipWindowsUpdate' }

        $proc = Start-Process -FilePath $psExe `
                             -ArgumentList $argList `
                             -Verb RunAs `
                             -PassThru `
                             -WindowStyle Normal

        exit 0
    } catch {
        Write-Error "Failed to elevate: $($_.Exception.Message)"
        exit 1
    }
}

#endregion

#region Application Management

function Get-RunningApplications {
    Write-Log "Detecting running applications..."

    $processNames = @(
        'chrome', 'msedge', 'firefox', 'brave',
        'EXCEL', 'ONENOTE', 'OUTLOOK', 'POWERPNT', 'WINWORD',
        'Zoom', 'slack', '1Password', 'Teams'
    )

    $runningApps = @{}

    foreach ($name in $processNames) {
        try {
            $procs = @(Get-Process -Name $name -ErrorAction SilentlyContinue)
            if ($procs.Count -gt 0) {
                $exePath = $null

                # Try to get path from process
                foreach ($proc in $procs) {
                    try {
                        if ($proc.Path -and (Test-Path $proc.Path)) {
                            $exePath = $proc.Path
                            break
                        }
                    } catch {
                        try {
                            if ($proc.MainModule.FileName -and (Test-Path $proc.MainModule.FileName)) {
                                $exePath = $proc.MainModule.FileName
                                break
                            }
                        } catch {}
                    }
                }

                # Fallback: search common locations
                if (-not $exePath) {
                    $searchPaths = Get-ApplicationSearchPaths -AppName $name
                    foreach ($path in $searchPaths) {
                        if (Test-Path $path) {
                            $exePath = $path
                            break
                        }
                    }
                }

                if ($exePath) {
                    $runningApps[$name] = $exePath
                    Write-Log "  Found running: $name at $exePath" -Level INFO
                }
            }
        } catch {
            Write-Log "Error checking process '$name': $($_.Exception.Message)" -Level WARN
        }
    }

    Write-Log "Detected $($runningApps.Count) running applications" -Level SUCCESS
    return $runningApps
}

function Get-ApplicationSearchPaths {
    param([string]$AppName)

    $paths = @()

    switch ($AppName.ToLower()) {
        'slack' {
            $paths += "$env:LOCALAPPDATA\slack\slack.exe"
            $paths += "C:\Program Files\Slack\slack.exe"
            Get-ChildItem "C:\Users\*\AppData\Local\slack\slack.exe" -ErrorAction SilentlyContinue |
                ForEach-Object { $paths += $_.FullName }
        }
        '1password' {
            $paths += "C:\Program Files\1Password\1Password.exe"
            $paths += "C:\Program Files (x86)\1Password\1Password.exe"
            Get-ChildItem "C:\Users\*\AppData\Local\1Password\app\*\1Password.exe" -ErrorAction SilentlyContinue |
                ForEach-Object { $paths += $_.FullName }
        }
        'teams' {
            $paths += "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
            $paths += "C:\Program Files\Microsoft Teams\Teams.exe"
            $paths += "C:\Program Files (x86)\Microsoft Teams\Teams.exe"
        }
        'chrome' {
            $paths += "C:\Program Files\Google\Chrome\Application\chrome.exe"
            $paths += "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        }
        'firefox' {
            $paths += "C:\Program Files\Mozilla Firefox\firefox.exe"
            $paths += "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        }
    }

    return $paths
}

function Restart-Applications {
    param([hashtable]$Applications)

    if ($Applications.Count -eq 0) {
        return
    }

    Write-Log "Restarting previously running applications..."

    foreach ($app in $Applications.GetEnumerator()) {
        try {
            $stillRunning = Get-Process -Name $app.Key -ErrorAction SilentlyContinue
            if (-not $stillRunning) {
                Write-Log "  Restarting $($app.Key)..." -Level INFO
                Start-Process -FilePath $app.Value -ErrorAction Stop
                Start-Sleep -Seconds 1
            } else {
                Write-Log "  $($app.Key) is still running, skipping" -Level INFO
            }
        } catch {
            Write-Log "Failed to restart $($app.Key): $($_.Exception.Message)" -Level WARN
        }
    }
}

#endregion

#region Chocolatey Management

function Install-Chocolatey {
    Write-Log "Chocolatey not found. Installing..."

    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

        $installScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
        Invoke-Expression $installScript

        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                    [System.Environment]::GetEnvironmentVariable('Path','User')

        $chocoPath = Get-ChocolateyPath
        if ($chocoPath) {
            Write-Log "Chocolatey installed successfully at: $chocoPath" -Level SUCCESS
            return $chocoPath
        } else {
            throw "Chocolatey installation completed but executable not found"
        }
    } catch {
        Write-Log "Failed to install Chocolatey: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-ChocolateyPath {
    $searchPaths = @(
        "$env:ProgramData\chocolatey\bin\choco.exe",
        "$env:ProgramData\chocolatey\choco.exe",
        "$env:ChocolateyInstall\bin\choco.exe"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # Try command
    $chocoCmd = Get-Command choco.exe -ErrorAction SilentlyContinue
    if ($chocoCmd) {
        return $chocoCmd.Source
    }

    return $null
}

function Update-ChocolateyPackages {
    if ($SkipChocolatey) {
        Write-Log "Skipping Chocolatey updates (SkipChocolatey flag set)" -Level INFO
        return
    }

    Write-Log "Checking Chocolatey installation..." -Level INFO

    $chocoExe = Get-ChocolateyPath
    if (-not $chocoExe) {
        $chocoExe = Install-Chocolatey
    } else {
        Write-Log "Chocolatey found at: $chocoExe" -Level SUCCESS
    }

    if (-not $chocoExe) {
        Write-Log "Skipping Chocolatey package updates" -Level WARN
        return
    }

    Write-Log "Upgrading Chocolatey packages..." -Level INFO

    try {
        $chocoArgs = @('upgrade', 'all', '-y', '--no-progress', '--limit-output')

        $process = Start-Process -FilePath $chocoExe `
                                 -ArgumentList $chocoArgs `
                                 -NoNewWindow `
                                 -Wait `
                                 -PassThru `
                                 -RedirectStandardOutput "$env:TEMP\choco_output.txt" `
                                 -RedirectStandardError "$env:TEMP\choco_error.txt"

        $output = Get-Content "$env:TEMP\choco_output.txt" -Raw -ErrorAction SilentlyContinue
        $errors = Get-Content "$env:TEMP\choco_error.txt" -Raw -ErrorAction SilentlyContinue

        if ($output) { $output | Out-File -FilePath $Script:LogFile -Append }
        if ($errors) { $errors | Out-File -FilePath $Script:LogFile -Append }

        Remove-Item "$env:TEMP\choco_output.txt" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\choco_error.txt" -ErrorAction SilentlyContinue

        if ($process.ExitCode -eq 0) {
            Write-Log "Chocolatey packages upgraded successfully!" -Level SUCCESS
        } else {
            Write-Log "Chocolatey upgrade completed with exit code: $($process.ExitCode)" -Level WARN
        }
    } catch {
        Write-Log "Failed to upgrade Chocolatey packages: $($_.Exception.Message)" -Level ERROR
    }
}

#endregion

#region Windows Update

function Install-PSWindowsUpdateModule {
    try {
        if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
            return $true
        }

        Write-Log "Installing PSWindowsUpdate module..." -Level INFO
        Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck -Scope AllUsers -ErrorAction Stop
        Import-Module PSWindowsUpdate -ErrorAction Stop
        Write-Log "PSWindowsUpdate module installed successfully" -Level SUCCESS
        return $true
    } catch {
        Write-Log "Failed to install PSWindowsUpdate: $($_.Exception.Message)" -Level WARN
        return $false
    }
}

function Install-WindowsUpdatesViaPSWU {
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop

        Write-Log "Checking for Windows updates..." -Level INFO
        $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop

        if ($updates.Count -eq 0) {
            Write-Log "No Windows updates available" -Level SUCCESS
            return $false
        }

        Write-Log "Found $($updates.Count) update(s). Installing..." -Level INFO

        if ($AutoReboot) {
            Install-WindowsUpdate -AcceptAll -AutoReboot -ErrorAction Stop
            # If we reach here, no reboot was needed
            return $false
        } else {
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop

            try {
                $rebootStatus = Get-WURebootStatus -Silent
                if ($rebootStatus) {
                    Write-Log "Reboot required to complete updates" -Level WARN
                    return $true
                }
            } catch {
                # Can't determine reboot status
            }
            return $false
        }
    } catch {
        Write-Log "Windows Update failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

function Install-WindowsUpdatesViaCOM {
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()

        Write-Log "Searching for Windows updates..." -Level INFO
        $searchResult = $updateSearcher.Search("IsInstalled=0 and IsHidden=0")

        if ($searchResult.Updates.Count -eq 0) {
            Write-Log "No Windows updates available" -Level SUCCESS
            return $false
        }

        Write-Log "Found $($searchResult.Updates.Count) update(s)" -Level INFO

        # Accept EULAs and prepare download collection
        $toDownload = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $searchResult.Updates) {
            try {
                if (-not $update.EulaAccepted) {
                    $update.AcceptEula()
                }
                if (-not $update.IsDownloaded) {
                    [void]$toDownload.Add($update)
                }
            } catch {
                Write-Log "Error processing update: $($_.Exception.Message)" -Level WARN
            }
        }

        # Download updates
        if ($toDownload.Count -gt 0) {
            Write-Log "Downloading $($toDownload.Count) update(s)..." -Level INFO
            $downloader = $updateSession.CreateUpdateDownloader()
            $downloader.Updates = $toDownload
            $downloadResult = $downloader.Download()
            Write-Log "Download completed with result code: $($downloadResult.ResultCode)" -Level INFO
        }

        # Install updates
        $toInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $searchResult.Updates) {
            if ($update.IsDownloaded) {
                [void]$toInstall.Add($update)
            }
        }

        $needsReboot = $false

        if ($toInstall.Count -gt 0) {
            Write-Log "Installing $($toInstall.Count) update(s)..." -Level INFO
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $toInstall
            $installResult = $installer.Install()

            Write-Log "Installation completed with result code: $($installResult.ResultCode)" -Level INFO

            if ($installResult.RebootRequired) {
                $needsReboot = $true
                Write-Log "Reboot required to complete updates" -Level WARN

                if ($AutoReboot) {
                    Write-Log "Auto-reboot enabled. System will restart in 60 seconds..." -Level WARN
                    Start-Sleep -Seconds 60
                    Restart-Computer -Force
                }
            } else {
                Write-Log "Updates installed successfully!" -Level SUCCESS
            }
        }

        # Cleanup COM objects
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($updateSession) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($updateSearcher) | Out-Null
        if ($toDownload) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($toDownload) | Out-Null }
        if ($toInstall) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($toInstall) | Out-Null }

        return $needsReboot
    } catch {
        Write-Log "Windows Update (COM) failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Update-Windows {
    if ($SkipWindowsUpdate) {
        Write-Log "Skipping Windows updates (SkipWindowsUpdate flag set)" -Level INFO
        return $false
    }

    Write-Log "Starting Windows Update process..." -Level INFO

    # Try PSWindowsUpdate first
    $usePSWU = Install-PSWindowsUpdateModule

    if ($usePSWU) {
        try {
            return Install-WindowsUpdatesViaPSWU
        } catch {
            Write-Log "PSWindowsUpdate failed, falling back to COM method" -Level WARN
            return Install-WindowsUpdatesViaCOM
        }
    } else {
        return Install-WindowsUpdatesViaCOM
    }
}

#endregion

#region Main Execution

function Start-UpdateProcess {
    # Initialize logging
    Initialize-Logging

    Write-Log "========================================" -Level INFO
    Write-Log "Windows Application Updater Starting" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "" -Level INFO

    # Check admin privileges
    if (-not (Test-IsAdmin)) {
        Write-Log "Not running as administrator. Elevating..." -Level WARN
        Invoke-ElevateScript
        return
    }

    Write-Log "Running with Administrator privileges" -Level SUCCESS
    Write-Log "" -Level INFO

    # Record running applications
    $runningApps = Get-RunningApplications
    Write-Log "" -Level INFO

    # Update Chocolatey packages
    Update-ChocolateyPackages
    Write-Log "" -Level INFO

    # Install Windows updates
    $Script:RebootRequired = Update-Windows
    Write-Log "" -Level INFO

    # Restart applications if no reboot required
    if (-not $Script:RebootRequired -and $runningApps.Count -gt 0) {
        Restart-Applications -Applications $runningApps
        Write-Log "" -Level INFO
    }

    # Summary
    Write-Log "========================================" -Level INFO
    Write-Log "Update Process Completed!" -Level SUCCESS
    Write-Log "========================================" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "Summary:" -Level INFO
    Write-Log "  - Chocolatey packages: $(if ($SkipChocolatey) { 'Skipped' } else { 'Updated' })" -Level INFO
    Write-Log "  - Windows updates: $(if ($SkipWindowsUpdate) { 'Skipped' } else { 'Checked and installed' })" -Level INFO
    if ($runningApps.Count -gt 0) {
        Write-Log "  - Applications detected: $($runningApps.Count)" -Level INFO
    }
    if ($Script:RebootRequired) {
        Write-Log "  - Reboot required: Yes" -Level WARN
    } else {
        Write-Log "  - Reboot required: No" -Level SUCCESS
    }
    Write-Log "" -Level INFO
    Write-Log "Log file: $Script:LogFile" -Level INFO
}

#endregion

# Run the update process
try {
    Start-UpdateProcess
} catch {
    if ($Script:LogFile) {
        Write-Log "Critical error: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    } else {
        Write-Error "Critical error: $($_.Exception.Message)"
    }
    exit 1
}
