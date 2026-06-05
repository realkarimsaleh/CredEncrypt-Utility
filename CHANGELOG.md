# CredEncrypt-Utility CHANGELOG

## [3.3.0] - 05/06/26
### Fixed
- Replaced WinForms TabControl with custom panel-based tab switching to eliminate internal border offset that caused unequal left/right margins on the grid and form controls

### Changed
- Tab bar is now a plain Panel with two flat buttons (Encrypt / Decrypt) and a painted bottom separator
- Content areas are standard Panels toggled by visibility - controls now sit at exact x=20 on both sides with no hidden offset

## [3.2.1] - 05/06/26
### Added
- App Name field in Decrypt tab is now grayed out and auto-populated from the detected K_*.txt filename after a successful read - no manual entry required
- Decrypt tab now accepts a direct credential folder path (e.g. C:\Temp\Panopto) rather than a base path + app name combination

### Fixed
- Form centering replaced manual WorkingArea calculation (which used ClientSize instead of Form.Width) with CenterScreen

### Changed
- Cred Path label renamed to Cred Folder to clarify it expects the app-specific subfolder directly

## [3.2.0] - 05/06/26
### Added
- Decrypt / Read tab in GUI mode - browse to credential folder, click Read, results shown in read-only grid
- Show values checkbox in Decrypt tab - values masked as bullets by default, revealed on check
- -Decrypt switch for CLI mode - points -BasePath at the credential folder directly and prints key/value pairs to console
- Read-EncryptedCredentials shared function used by both GUI and CLI decrypt paths
- Auto-detection of app name from K_*.txt filename in credential folder
- Status feedback in Decrypt tab: credential count on success, error message on failure
- Action button label and colour update dynamically on tab switch (green Run / blue Read)

### Changed
- Version bumped to 3.2.0

## [3.1.0] - 05/06/26
### Added
- PandaTools.ico embedded as base64 string - no external file dependency
- Icon applied to form title bar and taskbar entry
- Small 22x22 icon rendered in the dark header panel next to the title

### Fixed
- [char]0x1F512 replaced with [char]::ConvertFromUtf32(0x1F512) - supplementary Unicode plane characters cannot be cast directly to System.Char

### Changed
- Header title font increased from 12pt to 14pt Bold
- Header panel height increased from 56px to 64px with adjusted vertical positions
- Version bumped to 3.1.0

## [3.0.0] - 03/04/26
### Added
- GUI mode: double-clicking the script (no -AppName argument) launches a WinForms interface
- GUI includes App Name field, Output Path with Browse button, Key/Value credential grid, Self-destruct checkbox
- PandaTools-style UI: dark header panel, flat green primary button, bordered secondary buttons, dark grid headers, section band dividers, green Ready status, Segoe UI throughout
- -BasePath parameter with default of C:\Temp - replaces hardcoded C:\Windows\Build
- Success and failure message boxes in GUI mode
- Set-SecondaryButton and Set-PrimaryButton helper functions for consistent button styling

### Changed
- -Dev [bool] parameter renamed to -SelfDestruct [switch] - pass the switch to enable deletion, omit for safe default (script kept)
- Logic inverted: default behaviour is now to keep the script; -SelfDestruct opts into deletion
- -AppName and -Credentials parameters are now optional strings (empty triggers GUI mode)
- Log entry updated to record SelfDestruct state and launch mode (GUI/CLI)
- Version bumped to 3.0.0

### Removed
- Hardcoded $basePath = "C:\Windows\Build" - replaced by -BasePath parameter

## [2.0.1] - 26/02/26
### Fixed
- Encrypted credential files now correctly named for example C_AppNameClientId.txt instead of C_ClientId.txt

## [2.0.0] - 26/02/26
### Added
- Fully generic and reusable - no longer Panopto-specific
- SETTINGS block at top: $appName and $basePath drive all paths and filenames
- $hardcodedCredentials ordered hashtable for non-sensitive values (e.g. ClientId)
- -Credentials hashtable parameter accepts any number of name/value pairs
- Merge logic combines hardcoded and runtime credentials before encryption
- Runtime credentials take precedence over hardcoded values on key collision
- All output paths and encrypted filenames derived from $appName automatically
- $encryptedFiles list built dynamically from merged credential keys
- Setup log entry includes app name and credential count on completion

### Changed
- -ClientSecret, -Username, -Password params replaced by single -Credentials hashtable
- K_ and C_ file prefixes now use $appName instead of hardcoded Panopto
- Script is now drop-in reusable for any application by changing SETTINGS block only
- Version bumped to 2.0.0

### Removed
- All hardcoded Panopto-specific paths, filenames, and parameter names

## [1.0.0] - 25/02/26
### Added
- Initial release of Setup-PanoptoCredentials (Panopto-specific)
- Per-machine unique AES-256 key generation via RNGCryptoServiceProvider
- AES key written to K_Panopto.txt - never shared between machines
- Encrypted credential files: C_PanoptoClientId, ClientSecret, Username, Password
- Save-EncryptedCredential function with immediate memory zeroing after encryption
- $Dev parameter: $true skips self-deletion for testing, $false deletes on success
- Script never self-deletes on failure regardless of mode - kept for diagnosis
- Self-deletion via cmd.exe with 3 second timeout to allow PowerShell to exit cleanly
- Write-SetupLog with timestamp and machine name on every entry
- File verification checks non-zero size on all output files before declaring success
- SCCM-compatible exit codes: 0 = success, 1 = failure
- Plaintext credentials passed as runtime parameters only - never written to disk