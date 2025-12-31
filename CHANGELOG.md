# Changelog

All notable changes to the Windows Application Updater for Rippling MDM will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2024-12-30

### Added
- Initial release of Windows Application Updater for Rippling MDM
- One-line PowerShell deployment command
- Automatic Chocolatey installation and package updates
- Windows Update installation via PSWindowsUpdate module
- COM fallback for Windows Update if module unavailable
- Application state management (detect, close, reopen)
- Comprehensive logging to `C:\ProgramData\Rippling\Logs\`
- Support for tracking these applications:
  - Browsers: Chrome, Edge, Firefox, Brave
  - Microsoft Office: Excel, OneNote, Outlook, PowerPoint, Word
  - Communication: Zoom, Slack, Teams
  - Security: 1Password
- Three operational parameters:
  - `-AutoReboot`: Enable automatic reboot if required
  - `-SkipChocolatey`: Skip Chocolatey updates
  - `-SkipWindowsUpdate`: Skip Windows updates
- Script elevation handling (auto-request admin privileges)
- Error handling and recovery
- Structured code organization with regions
- Complete PowerShell help documentation
- One-line installer script (`Install.ps1`)

### Fixed
- **Removed entire "Windows Efficiency Mode" section** - This was based on a misunderstanding of Windows features and was modifying unrelated registry keys
- **PSWindowsUpdate module scope** - Changed from `CurrentUser` to `AllUsers` scope for system-wide availability
- **COM object memory leaks** - Added proper cleanup of Windows Update COM objects
- **Missing logging** - Added comprehensive logging system with timestamps and log levels
- **Inconsistent error handling** - Added try-catch blocks to all critical operations
- **Limited Chocolatey detection** - Improved path detection with environment variable support
- **Reboot logic issues** - Centralized reboot tracking and proper app restart logic
- **Fragile application path detection** - Added fallback search paths for common applications
- **Poor code organization** - Restructured into logical regions and functions
- **Missing help documentation** - Added complete comment-based help
- **No temp file cleanup** - Added cleanup handlers for installer script
- **Chocolatey output not logged** - Capture and log all Chocolatey output

### Security
- All downloads over HTTPS (TLS 1.2)
- No credentials or secrets stored
- Public repository for transparency
- Admin privilege validation
- Uses official Chocolatey and Microsoft update sources

---

## How to Update

When making changes, follow this format:

```markdown
## [Version] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

---

## Version History

- **1.0.0** (2024-12-30) - Initial release

---

**Repository**: https://github.com/TG-orlando/rippling-windows-updates
**Maintainer**: TG-orlando (orlando.roberts@theguarantors.com)
