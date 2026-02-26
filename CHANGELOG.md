# CredEncrypt-Utility Changelog

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
