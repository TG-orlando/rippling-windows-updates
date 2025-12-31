# 🚀 Windows Application Updater - Ready to Deploy!

Your Windows Application Updater is live on GitHub and ready for Rippling MDM deployment!

## 📍 Repository
https://github.com/TG-orlando/rippling-windows-updates

## ⚡ One-Line Command for Rippling MDM

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"
```

---

## 🔧 Deploy to Rippling MDM

### Quick Setup (5 minutes)

1. **Log into Rippling**
   - Go to your Rippling Admin Console

2. **Navigate to Scripts**
   - IT Management → Device Management → Scripts → Create Script

3. **Configure the Script**
   - **Name**: `Windows Application Updater`
   - **Description**: `Automatically updates Windows applications and system`
   - **Platform**: Windows
   - **Script Type**: PowerShell
   - **Script Content**:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"
   ```

4. **Set Schedule**
   - Recommended: Weekly (e.g., every Sunday at 2 AM)
   - Or: On-demand when you need to push updates

5. **Deploy**
   - Select target devices or groups
   - Save and deploy!

---

## 📱 What It Does

1. ✅ Checks for Administrator privileges (elevates if needed)
2. ✅ Detects running applications
3. ✅ Installs Chocolatey if not present
4. ✅ Updates all Chocolatey packages
5. ✅ Installs Windows Updates
6. ✅ Reopens applications (if no reboot needed)
7. ✅ Logs everything to `C:\ProgramData\Rippling\Logs\`

---

## 🎯 What Gets Updated

### Chocolatey Packages
- All installed Chocolatey packages
- Browsers, productivity tools, development tools, etc.

### Windows Updates
- Security updates
- Feature updates
- Driver updates
- Definition updates

### Applications Managed
- Browsers: Chrome, Edge, Firefox, Brave
- Office: Excel, OneNote, Outlook, PowerPoint, Word
- Communication: Zoom, Slack, Teams
- Security: 1Password

---

## ⚙️ Optional Parameters

### With Auto-Reboot
Automatically reboots if updates require it:
```powershell
powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex -AutoReboot"
```

### Skip Chocolatey Updates
Only run Windows updates:
```powershell
powershell.exe -ExecutionPolicy Bypass -Command "& {irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Update-WindowsApps.ps1 | Out-File $env:TEMP\update.ps1; & $env:TEMP\update.ps1 -SkipChocolatey}"
```

---

## 🧪 Test First!

Before deploying to all PCs, test on one:

```powershell
# Run on a test machine
powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"

# Check logs
Get-ChildItem "C:\ProgramData\Rippling\Logs\WindowsAppUpdater_*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    Get-Content -Tail 50
```

---

## 📊 Monitor Deployment

Check logs on any Windows PC:

```powershell
# List all logs
Get-ChildItem "C:\ProgramData\Rippling\Logs\WindowsAppUpdater_*.log" |
    Sort-Object LastWriteTime -Descending

# View latest log
Get-ChildItem "C:\ProgramData\Rippling\Logs\WindowsAppUpdater_*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    Get-Content

# Monitor in real-time
Get-Content "C:\ProgramData\Rippling\Logs\WindowsAppUpdater_*.log" -Wait -Tail 50
```

**Log format**:
```
[2024-12-30 20:15:23] [INFO] Windows Application Updater Starting
[2024-12-30 20:15:24] [SUCCESS] Running with Administrator privileges
[2024-12-30 20:15:25] [INFO] Detecting running applications...
[2024-12-30 20:15:26] [INFO]   Found running: chrome at C:\Program Files\Google\Chrome\Application\chrome.exe
...
```

---

## 🔐 Security

### What's Safe
- ✅ Script runs with admin privileges (as configured)
- ✅ All downloads over HTTPS
- ✅ Uses official Chocolatey and Microsoft sources
- ✅ No credentials stored
- ✅ Public repository - transparent code

### What to Watch
- ⚠️ Script can close user applications
- ⚠️ Script can install updates
- ⚠️ Script can reboot computer (if -AutoReboot used)
- ⚠️ Runs with elevated privileges

### Best Practices
1. Test on a small group first
2. Schedule during off-hours
3. Monitor logs after deployment
4. Review changes before pushing to GitHub
5. Use version control (git tags)

---

## 💡 Pro Tips

1. **Schedule wisely** - Run during off-hours to minimize disruption
2. **Start small** - Deploy to a test group first
3. **Monitor logs** - Check after first few runs
4. **Keep it updated** - Update the script as needed via git
5. **Use tags** - Tag stable versions in git

---

## 🆘 Troubleshooting

### Script doesn't run
- Check execution policy: `Get-ExecutionPolicy`
- Verify internet connectivity
- Check Rippling MDM deployment status
- Review device logs

### Chocolatey fails to install
- Check TLS 1.2 is enabled
- Verify internet access to chocolatey.org
- Check logs for specific error
- Ensure admin privileges

### Windows Update fails
- Check Windows Update service: `Get-Service wuauserv`
- Try Windows Update manually first
- Review logs for specific errors
- Check disk space

### Apps don't reopen
- Verify app paths are correct
- Check if app is installed
- Review logs for restart attempts
- Apps may have been closed by user

---

## ✨ You're All Set!

Just add the one-line command to Rippling MDM and you're done!

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TG-orlando/rippling-windows-updates/main/Install.ps1 | iex"
```

---

**Repository**: https://github.com/TG-orlando/rippling-windows-updates
**Local Files**: /Users/appleseed/windows-app-updater/
**Documentation**:
- README.md - Complete documentation
- DEPLOYMENT.md - This file
- ERRORS_FIXED.md - What was fixed from original
- CHANGELOG.md - Version history

Happy deploying! 🎉
