# CredEncrypt-Utility

Run-once credential encryption utility. Generates a unique AES-256 key per
machine and encrypts a set of application credentials into individual files.
Designed for SCCM deployment as a pre-requisite to PanoptoDeltaInformant.

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

## Quick Start

### 1. Retrieve credentials from Secret Server

Get the following values from Thycotic Secret Server
> **Secret Server:** <https://thycotic.leedsbeckett.ac.uk/>
> **Path:** <Secrets\ Support Services\ PanoptoDeltaInformant>

| Secret Name                             | Purpose                                                    |
|-----------------------------------------|------------------------------------------------------------|
| `520d6e92-8211-419b-8fb3-b3f5009e7803`  | Client ID and Client Secret for API                        |
| Panopto Delta Informant Service Account | Panopto Account used to Authenticate API                   |

### 2. Run the script (Dev / Testing)

```powershell
.\CredEncrypt-Utility.ps1 -Credentials @{ ClientSecret="x"; Username="y"; Password="z" } -Dev $true
```

### 3. Run the script (Production — script self-deletes on success)

```powershell
.\CredEncrypt-Utility.ps1 -Credentials @{ ClientSecret="x"; Username="y"; Password="z" }
```

### 4. Verify output

Check that the following files exist and are non-empty at `C:\Windows\Build\Panopto\`:

```
K_Panopto.txt
C_PanoptoClientId.txt
C_PanoptoClientSecret.txt
C_PanoptoUsername.txt
C_PanoptoPassword.txt
```

### 5. Deploy PanoptoDeltaInformant

Once credential files are confirmed on the machine, deploy
`PanoptoDeltaInformant.ps1` via SCCM with `$useEncryptedCredentials = $true`.

---

## Settings Block

To retarget this script for a different application, only the SETTINGS block
near the top of the script needs to change. No other edits are required.

```powershell
$appName  = "Panopto"
$basePath = "C:\Windows\Build"

$hardcodedCredentials = [ordered]@{
    ClientId = "520d6e92-8211-419b-8fb3-b3f5009e7803"
}
```

`$appName` drives all output paths and filenames automatically:

```
C:\Windows\Build\Panopto\K_Panopto.txt
C:\Windows\Build\Panopto\C_PanoptoClientId.txt
C:\Windows\Build\Panopto\C_PanoptoClientSecret.txt
C:\Windows\Build\Panopto\C_PanoptoUsername.txt
C:\Windows\Build\Panopto\C_PanoptoPassword.txt
```

---

## Parameters

| Parameter      | Required | Default  | Description                                           |
|----------------|----------|----------|-------------------------------------------------------|
| `-Credentials` | Yes      | —        | Hashtable of credential name/value pairs to encrypt   |
| `-Dev`         | No       | `$false` | `$true` skips self-deletion on success (testing only) |

---

## Usage Examples

```powershell
# Panopto deployment
.\CredEncrypt-Utility.ps1 -Credentials @{ ClientSecret="x"; Username="y"; Password="z" }

# Any other app
.\CredEncrypt-Utility.ps1 -Credentials @{ ApiKey="x"; TenantId="y" }

# Dev mode - script not deleted on success
.\CredEncrypt-Utility.ps1 -Credentials @{ ApiKey="x" } -Dev $true
```

### SCCM Program Command Line

```
powershell.exe -ExecutionPolicy Bypass -File ".\CredEncrypt-Utility.ps1" -Credentials @{ ClientSecret="x"; Username="y"; Password="z" }
```

---

## Output Files

| File                        | Contents                             |
|-----------------------------|--------------------------------------|
| `K_Panopto.txt`             | 32-byte AES-256 key (machine-unique) |
| `C_PanoptoClientId.txt`     | Encrypted ClientId                   |
| `C_PanoptoClientSecret.txt` | Encrypted ClientSecret               |
| `C_PanoptoUsername.txt`     | Encrypted Username                   |
| `C_PanoptoPassword.txt`     | Encrypted Password                   |

---

## Credential Merge Order

Credentials are merged in this order before encryption:

1. `$hardcodedCredentials` — defined in the SETTINGS block (e.g. ClientId)
2. `-Credentials` parameter — runtime values passed at execution

Runtime values take precedence. If the same key appears in both, the runtime
value wins. This allows hardcoded defaults to be overridden per-deployment
without editing the script.

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
C:\Windows\Build\Logs\Panopto_CredEncrypt-Utility.log
```

Log entries include timestamp, machine name, and result for each file written.

---

## When Credentials Change

1. Update the `-Credentials` parameter values in the SCCM program command line
2. Update Distribution Points in SCCM
3. Redeploy - each machine generates a new unique key and overwrites all files
