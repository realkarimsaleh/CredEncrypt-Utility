<#
.SYNOPSIS
    Run-once credential setup script.
    Generates a unique AES key per machine, encrypts credentials locally.
    Designed to run as SYSTEM via SCCM software deployment.

.DESCRIPTION
    Credential Encryption Utility
    Configure the SETTINGS block at the top for each deployment.
    Plaintext values are never written to disk - only encrypted blobs are stored.
    Safe to run multiple times - will overwrite existing files.
    Set -Dev $true to prevent self-deletion after successful setup (testing only).

.NOTES
    Name       : CredEncrypt-Utility
    Author     : Karim Saleh (SALEH03)
    Version    : 2.0.1
    Released   : 26/02/26

.EXAMPLE
    ##Panopto deployment
    .\CredEncrypt-Utility.ps1 -Credentials @{ ClientSecret="x"; Username="y"; Password="z" }

    ##Any other app
    .\CredEncrypt-Utility.ps1 -Credentials @{ ApiKey="x"; TenantId="y" }

    ##Dev mode - script not deleted on success
    .\CredEncrypt-Utility.ps1 -Credentials @{ ApiKey="x" } -Dev $true
#>


param(
    ##Hashtable of credential name/value pairs - keys become the encrypted file names
    #e.g. @{ ClientSecret="x"; Username="y"; Password="z" }
    [Parameter(Mandatory=$true)][hashtable]$Credentials,
    ##Set $true to skip self-deletion after setup (dev/testing only)
    ##Set $false for production SCCM deployment - script deletes itself on success
    [bool]$Dev = $false
)


##Setting Variables
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)

##Script path used for self-deletion at the end
$scriptPath = $MyInvocation.MyCommand.Definition

#Change these values to retarget this script for a different application
$appName  = "Panopto"
$basePath = "C:\Windows\Build"

##Hardcoded non-sensitive credentials - leave empty string if none required
#These are added to the encrypted store alongside the runtime parameters above
$hardcodedCredentials = [ordered]@{
    ClientId = "520d6e92-8211-419b-8fb3-b3f5009e7803"
}

##Derived paths
#Driven entirely by $appName
$credPath = "$basePath\$appName"
$logPath  = "$basePath\Logs\$($appName)_$scriptName.log"
$keyFile  = "K_$appName.txt"

##Ensure folders exist
foreach ($path in @($credPath, (Split-Path $logPath)))
{
    if (-not (Test-Path $path))
    {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

##Function to write timestamped entry to log file
function Write-SetupLog
{
    param([string]$Message)
    "[$((Get-Date).ToString('dd/MM/yyyy HH:mm:ss'))] [$env:COMPUTERNAME] $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

Write-SetupLog "Credential setup started - App: $appName (Mode: $(if ($Dev) { 'DEV - no self-delete' } else { 'Production' }))"

##Generate a unique AES-256 key for THIS machine only
$aesKey = New-Object byte[] 32
$rng    = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
$rng.GetBytes($aesKey)
$rng.Dispose()

$aesKey | Out-File -FilePath "$credPath\$keyFile" -Encoding Default
Write-SetupLog "Unique AES key generated and saved: $keyFile"

##Function to encrypt a plaintext string with this machine's AES key
function Save-EncryptedCredential
{
    param(
        [string]$PlainText,
        [string]$OutputPath,
        [byte[]]$Key,
        [string]$Label
    )

    $secureString  = ConvertTo-SecureString -String $PlainText -AsPlainText -Force
    $encryptedText = ConvertFrom-SecureString -SecureString $secureString -Key $Key
    $encryptedText | Out-File -FilePath $OutputPath -Encoding Default

    ##Clear plaintext from memory immediately
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    )

    Write-SetupLog "Encrypted and saved: $Label"
}

##Merge hardcoded credentials with runtime credentials
#Runtime parameters take precedence if the same key is supplied in both
$allCredentials = [ordered]@{}

foreach ($entry in $hardcodedCredentials.GetEnumerator())
{
    $allCredentials[$entry.Key] = $entry.Value
}

foreach ($entry in $Credentials.GetEnumerator())
{
    $allCredentials[$entry.Key] = $entry.Value
}

##Encrypt all credentials
#Plaintext only exists in memory, never touches disk
$encryptedFiles = @("$keyFile")

foreach ($entry in $allCredentials.GetEnumerator())
{
    $fileName = "C_$($appName)$($entry.Key).txt"
    $filePath = "$credPath\$fileName"

    Save-EncryptedCredential -PlainText $entry.Value -OutputPath $filePath -Key $aesKey -Label $entry.Key

    $encryptedFiles += $fileName
}

##Verify all files were created with non-zero size
Write-SetupLog "Verifying output files..."

$allGood = $true

foreach ($file in $encryptedFiles)
{
    $fullPath = Join-Path $credPath $file

    if ([System.IO.File]::Exists($fullPath) -and (Get-Item $fullPath).Length -gt 0)
    {
        Write-SetupLog "Verified: $file"
    }

    else
    {
        Write-SetupLog "MISSING OR EMPTY: $file"
        $allGood = $false
    }
}

##Self-deletion block
#Production only will be skipped entirely in dev mode
if ($allGood)
{
    Write-SetupLog "Setup completed successfully - $($encryptedFiles.Count - 1) credential(s) stored for $appName"

    if ($Dev)
    {
        Write-SetupLog "DEV mode - skipping self-deletion, script kept at: $scriptPath"
        Write-Host "Setup complete (DEV mode) - script not deleted" -ForegroundColor DarkYellow
        exit 0
    }

    else
    {
        Write-SetupLog "Production mode - scheduling self-deletion of script"

        ##Use cmd.exe to delete the script after PowerShell exits
        #Timeout gives PowerShell time to fully exit before deletion runs
        Start-Process -FilePath "cmd.exe" -ArgumentList "/C timeout /T 3 /NOBREAK >nul & del /F /Q `"$scriptPath`"" -WindowStyle Hidden
        Write-SetupLog "Self-deletion scheduled"
        exit 0
    }
}

else
{
    Write-SetupLog "Setup FAILED - one or more files missing, script NOT deleted"
    Write-Host "Setup FAILED - check log at $logPath" -ForegroundColor Red

    ##Never self-delete on failure regardless of mode - keep script for diagnosis
    exit 1
}
