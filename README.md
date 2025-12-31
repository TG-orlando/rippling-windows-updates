# Windows Application Updater for Rippling MDM

Automatically updates Windows applications via Chocolatey and installs Windows Updates. Designed for unattended deployment via Rippling MDM.

## Features

- ✅ Automatic Chocolatey installation and package updates
- ✅ Windows Update installation
- ✅ Application state preservation (closes and reopens apps)
- ✅ Unattended execution (no user prompts)
- ✅ Comprehensive logging to `C:\ProgramData\Rippling\Logs\`
- ✅ Error handling and recovery
- ✅ Optional automatic reboot

## Deployment Options

### Option 1: One-Line PowerShell Command (Recommended for Rippling MDM)

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"
```

### Option 2: With Auto-Reboot

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex -AutoReboot"
```

### Option 3: Direct Script Execution

```powershell
Invoke-RestMethod -Uri https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Update-WindowsApps.ps1 -OutFile $env:TEMP\Update-WindowsApps.ps1
powershell.exe -ExecutionPolicy Bypass -File $env:TEMP\Update-WindowsApps.ps1
```

## Rippling MDM Configuration

### Script Configuration

1. Log into Rippling Admin Console
2. Navigate to **IT Management** → **Device Management** → **Scripts**
3. Click **Create Script**
4. Configure:
   - **Name**: Windows Application Updater
   - **Description**: Updates Windows applications and system via Chocolatey and Windows Update
   - **Platform**: Windows
   - **Script Type**: PowerShell
   - **Script Content**:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"
   ```

5. Set schedule (recommended: weekly)
6. Deploy to target devices or groups

## What Gets Updated

### Via Chocolatey
- All installed Chocolatey packages
- Common applications like:
  - Browsers (Chrome, Firefox, Edge)
  - Productivity tools (Office apps, Zoom, Slack, Teams)
  - Development tools
  - Any other Chocolatey-managed packages

### Via Windows Update
- Security updates
- Feature updates
- Driver updates
- Definition updates

## Application Management

The script automatically detects and manages these applications:
- **Browsers**: Chrome, Edge, Firefox, Brave
- **Microsoft Office**: Excel, OneNote, Outlook, PowerPoint, Word
- **Communication**: Zoom, Slack, Teams
- **Security**: 1Password

Applications are closed before updates and reopened afterward (unless reboot is required).

## Parameters

### -AutoReboot
Enables automatic reboot if updates require it.

```powershell
.\Update-WindowsApps.ps1 -AutoReboot
```

### -SkipChocolatey
Skips Chocolatey package updates.

```powershell
.\Update-WindowsApps.ps1 -SkipChocolatey
```

### -SkipWindowsUpdate
Skips Windows Update checks.

```powershell
.\Update-WindowsApps.ps1 -SkipWindowsUpdate
```

## Logs

Logs are stored in:
```
C:\ProgramData\Rippling\Logs\WindowsAppUpdater_YYYYMMDD_HHMMSS.log
```

If the directory cannot be created, logs fall back to `%TEMP%`.

### Viewing Logs

```powershell
# View latest log
Get-ChildItem "C:\ProgramData\Rippling\Logs\WindowsAppUpdater_*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    Get-Content

# Monitor log in real-time
Get-Content "C:\ProgramData\Rippling\Logs\WindowsAppUpdater_*.log" -Wait -Tail 50
```

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or higher
- Administrator privileges
- Internet connection

## How It Works

1. **Elevation Check** - Requests admin privileges if needed
2. **Detect Running Apps** - Records currently running applications
3. **Install Chocolatey** - Installs if not present
4. **Update Packages** - Upgrades all Chocolatey packages
5. **Windows Updates** - Checks and installs Windows updates
6. **Reopen Apps** - Restarts previously running applications (if no reboot needed)

## Troubleshooting

### Script doesn't run
- Ensure execution policy allows scripts: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Verify internet connectivity
- Check if PowerShell is available

### Chocolatey installation fails
- Check internet connectivity
- Verify TLS 1.2 is enabled
- Ensure admin privileges

### Windows Update fails
- Try running Windows Update manually first
- Check Windows Update service is running: `Get-Service wuauserv`
- Review logs for specific errors

### Permission errors
- Script must run with Administrator privileges
- Check UAC settings
- Verify executing user has appropriate permissions

## Testing

Test the deployment manually before scheduling:

```powershell
# Test without auto-reboot
powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"

# Check logs
Get-ChildItem "C:\ProgramData\Rippling\Logs\WindowsAppUpdater_*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    Get-Content -Tail 50
```

## Security Considerations

- Script runs with Administrator privileges
- All downloads over HTTPS
- No credentials or secrets stored
- Public repository for transparency
- Uses official Chocolatey and Microsoft update sources

## Customization

To modify which applications are tracked for restart, edit the `$processNames` array in `Update-WindowsApps.ps1`:

```powershell
$processNames = @(
    'chrome', 'msedge', 'firefox',
    'YourApp'  # Add your application here
)
```

Commit and push changes - updates take effect on next run.

## Contributing

To customize for your organization:

1. Fork this repository
2. Update application list as needed
3. Modify logging paths if desired
4. Update repository URLs in Install.ps1 and this README
5. Test thoroughly before deploying

## License

MIT License - Free to modify and use for your organization.

## Support

For issues or questions:
- Check logs in `C:\ProgramData\Rippling\Logs\`
- Review Chocolatey documentation: https://chocolatey.org/docs
- Review Windows Update documentation: https://docs.microsoft.com/windows-update
- File an issue in this repository

---

**Repository**: https://github.com/TG-orlando/rippling-windows-updates
**Maintainer**: TG-orlando (orlando.roberts@theguarantors.com)
