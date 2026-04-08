# Val CLI installer for Windows
# ==============================
# Usage:
#   irm https://raw.githubusercontent.com/valoryck/val/main/install.ps1 | iex
#
# Options (set as env vars before running):
#   $env:VAL_VERSION = "v0.1.0"           # specific version (default: latest)
#   $env:VAL_INSTALL = "$HOME\.val\bin"    # install directory

$ErrorActionPreference = "Stop"

$Repo = "valoryck/val"
$Binary = "val"

# Resolve install directory.
$InstallDir = if ($env:VAL_INSTALL) { $env:VAL_INSTALL } else { "$HOME\.val\bin" }

# Detect architecture.
$Arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
    "X64"   { "amd64" }
    "Arm64" { "arm64" }
    default { Write-Error "Unsupported architecture: $_"; exit 1 }
}

Write-Host "Detected: windows/$Arch"

# Resolve version.
$Version = $env:VAL_VERSION
if (-not $Version) {
    Write-Host "Fetching latest version..."
    $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
    $Version = $Release.tag_name
    if (-not $Version) {
        Write-Error "Could not determine latest version."
        exit 1
    }
}

$VersionNum = $Version.TrimStart("v")
$Archive = "${Binary}_${VersionNum}_windows_${Arch}.zip"
$Checksums = "${Binary}_${VersionNum}_checksums.txt"
$BaseUrl = "https://github.com/$Repo/releases/download/$Version"

# Create temp directory.
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Download archive.
    Write-Host "Downloading $Archive..."
    Invoke-WebRequest -Uri "$BaseUrl/$Archive" -OutFile "$TempDir\$Archive"

    # Download checksums.
    Write-Host "Downloading checksums..."
    Invoke-WebRequest -Uri "$BaseUrl/$Checksums" -OutFile "$TempDir\$Checksums"

    # Verify checksum.
    Write-Host "Verifying checksum..."
    $Expected = (Get-Content "$TempDir\$Checksums" | Select-String $Archive).ToString().Split(" ")[0]
    $Actual = (Get-FileHash "$TempDir\$Archive" -Algorithm SHA256).Hash.ToLower()

    if ($Expected -ne $Actual) {
        Write-Error "Checksum mismatch! Expected: $Expected, Got: $Actual"
        exit 1
    }
    Write-Host "Checksum OK."

    # Extract.
    Write-Host "Extracting..."
    Expand-Archive -Path "$TempDir\$Archive" -DestinationPath $TempDir -Force

    # Install.
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Move-Item -Path "$TempDir\$Binary.exe" -Destination "$InstallDir\$Binary.exe" -Force

    # Add to PATH if not already there.
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$InstallDir;$UserPath", "User")
        Write-Host "Added $InstallDir to user PATH."
    }

    Write-Host ""
    Write-Host "val $Version installed to $InstallDir\$Binary.exe" -ForegroundColor Green
    Write-Host ""
    Write-Host "Restart your terminal, then run 'val version' to verify."
    Write-Host ""
    Write-Host "Shell completions:"
    Write-Host "  powershell: val completion powershell | Out-String | Invoke-Expression"
    Write-Host ""
}
finally {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
