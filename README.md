# CredEncrypt-Utility

Run-once credential encryption utility. Generates a unique AES-256 key per
machine and encrypts a set of application credentials into individual files.
Designed for SCCM deployment as a pre-requisite to dependent applications.

---

## Overview

CredEncrypt-Utility solves the problem of storing API credentials securely on
managed machines without embedding plaintext in scripts or Group Policy.

Each machine generates its own random AES-256 key at runtime. Credentials are
encrypted with that key and stored as individual files. Because every machine
has a different key, compromising one machine reveals nothing about any other.

Plaintext credential values are passed as runtime parameters only — they are
never written to disk at any point.

---

## Requirements

- PowerShell 5.1 or PowerShell 7+
- Write access to `C:\Windows\Build\` (runs as SYSTEM via SCCM)

---

## Parameters

| Parameter      | Required | Default  | Description                                                      |
|----------------|----------|----------|------------------------------------------------------------------|
| `-AppName`     | Yes      | —        | Application name — drives all output folder names and filenames  |
| `-Credentials` | Yes      | —        | Hashtable of credential name/value pairs to encrypt              |
| `-Dev`         | No       | `$false` | `$true` skips self-deletion on success (testing only)            |

`-AppName` drives all output paths and filenames automatically:

```
C:\Windows\Build\AppName\K_AppName.txt
C:\Windows\Build\AppName\C_AppNameClientSecret.txt
C:\Windows\Build\AppName\C_AppNameUsername.txt
C:\Windows\Build\AppName\C_AppNamePassword.txt
```

---

## Usage Examples

```powershell
# Panopto deployment
.\CredEncrypt-Utility.ps1 -AppName "Panopto" -Credentials @{ ClientSecret="x"; Username="y"; Password="z" }

# Any other app
.\CredEncrypt-Utility.ps1 -AppName "MyApp" -Credentials @{ ApiKey="x"; TenantId="y" }

# Dev mode - script not deleted on success
.\CredEncrypt-Utility.ps1 -AppName "MyApp" -Credentials @{ ApiKey="x" } -Dev $true
```

### SCCM Program Command Line

```
powershell.exe -ExecutionPolicy Bypass -File ".\CredEncrypt-Utility.ps1" -AppName "Panopto" -Credentials @{ ClientSecret="x"; Username="y"; Password="z" }
```

---

## Output Files

All files are written to `C:\Windows\Build\<AppName>\`.

| File                        | Contents                             |
|-----------------------------|--------------------------------------|
| `K_AppName.txt`             | 32-byte AES-256 key (machine-unique) |
| `C_AppNameClientSecret.txt` | Encrypted ClientSecret               |
| `C_AppNameUsername.txt`     | Encrypted Username                   |
| `C_AppNamePassword.txt`     | Encrypted Password                   |

File names are derived directly from `-AppName` and the keys supplied in
`-Credentials`. Adding a new key to the hashtable automatically creates a
new encrypted file with no script edits required.

---

## Credential Merge Order

Credentials are merged in this order before encryption:

1. `$hardcodedCredentials` — static entries defined inside the script (empty by default)
2. `-Credentials` parameter — runtime values passed at execution

Runtime values take precedence. If the same key appears in both, the runtime
value wins. `$hardcodedCredentials` is intentionally empty in the default
script — populate it only if a credential should be baked in for all
deployments of a given app.

---

## Self-Deletion Behaviour

| Mode               | Setup succeeds                | Setup fails               |
|--------------------|-------------------------------|---------------------------|
| Production         | Script deleted after 3s delay | Script kept for diagnosis |
| Dev (`-Dev $true`) | Script kept                   | Script kept for diagnosis |

Self-deletion is handled by a hidden `cmd.exe` process with a 3 second timeout
to allow PowerShell to fully exit before the file is removed.

The script **never** self-deletes on failure regardless of mode.

---

## Logging

Every run appends to:

```
C:\Windows\Build\Logs\<AppName>_CredEncrypt-Utility.log
```

Log entries include timestamp, machine name, and result for each file written.

---

## When Credentials Change

1. Update `-AppName` and `-Credentials` values in the SCCM program command line
2. Update Distribution Points in SCCM
3. Redeploy — each machine generates a new unique key and overwrites all files
