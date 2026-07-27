
<#
.SYNOPSIS
    MPV Portable Release Builder - 3-package build script
.DESCRIPTION
    Creates three packages:
      - mpv-config-vX.Y.Z.7z     Config files (scripts/settings/fonts/OSC)
      - mpv-base-vX.Y.Z.7z       Core player + Config = ready to play
      - mpv-extras-vX.Y.Z.7z     Shaders + VapourSynth + AI + Tools (split volumes)
.PARAMETER Version
    Version number, e.g. "1.0.0"
.EXAMPLE
    .\build-release.ps1 -Version "1.0.0"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [string]$OutputDir = "release"
)

$ErrorActionPreference = "Stop"
$RootDir = $PSScriptRoot
Set-Location $RootDir

# Tools
$7z = Join-Path $RootDir "7z.exe"
if (-not (Test-Path $7z)) {
    Write-Error "Cannot find 7z.exe. Run this script from the mpv root directory."
    exit 1
}

# Output directory
$null = New-Item -ItemType Directory -Force (Join-Path $RootDir $OutputDir)
$BuildDir = Join-Path $RootDir "build"
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }

# Package names
$ConfigName = "mpv-config-v${Version}"
$BaseName   = "mpv-base-v${Version}"
$ExtrasName = "mpv-extras-v${Version}"

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  MPV Portable Release Builder v${Version}" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# Helper functions
# ============================================================

function Invoke-Pack {
    param([string]$ArchiveName, [string]$SourceDir, [string]$Description, [switch]$Split)
    $archivePath = Join-Path $OutputDir $ArchiveName
    Write-Host "[PACK] ${Description}" -ForegroundColor Yellow
    Write-Host "       Output: ${archivePath}.7z" -ForegroundColor Gray

    if (Test-Path "${archivePath}.7z") { Remove-Item -Force "${archivePath}.7z" }
    if (Test-Path "${archivePath}.7z.001") {
        Remove-Item -Force "${archivePath}.7z.*"
    }

    if ($Split) {
        # Split volumes: max 1900MB each (< GitHub 2GB limit)
        & $7z a -t7z -mx=7 -md=64m -ms=on -v1900m "${archivePath}.7z" "$SourceDir\*"
    } else {
        & $7z a -t7z -mx=7 -md=64m -ms=on "${archivePath}.7z" "$SourceDir\*"
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Packaging failed: ${Description}"
        exit 1
    }

    $size = if ($Split) {
        (Get-ChildItem "${archivePath}.7z.*" | Measure-Object -Property Length -Sum).Sum
    } else {
        (Get-Item "${archivePath}.7z").Length
    }
    $sizeMB = [math]::Round($size/1MB, 1)
    Write-Host "       Done (${sizeMB} MB)" -ForegroundColor Green
    Write-Host ""
}

function Invoke-CopyTo {
    param([string]$Dest, [string[]]$Sources)
    foreach ($src in $Sources) {
        $target = Join-Path $Dest $src
        $parent = Split-Path $target -Parent
        if (-not (Test-Path $parent)) {
            $null = New-Item -ItemType Directory -Force $parent
        }
        $srcPath = Join-Path $RootDir $src
        if (Test-Path $srcPath) {
            Copy-Item -Recurse -Force $srcPath $target
        }
    }
}

function Invoke-CopyConfig {
    param([string]$Dest)
    $configDest = Join-Path $Dest "portable_config"
    $configSrc = Join-Path $RootDir "portable_config"
    Write-Host "       Copying portable_config/ (excluding shaders vs cache files)..." -ForegroundColor Gray
    $null = New-Item -ItemType Directory -Force $configDest
    Copy-Item -Recurse -Force "$configSrc\*" $configDest
    # Remove heavy content (goes into extras)
    foreach ($exclude in @("shaders", "vs", "cache", "files")) {
        $exPath = Join-Path $configDest $exclude
        if (Test-Path $exPath) { Remove-Item -Recurse -Force $exPath }
    }
}

function Copy-IfExists {
    param([string]$Source, [string]$DestDir)
    $src = Join-Path $RootDir $Source
    if (Test-Path $src) { Copy-Item $src $DestDir }
}

# ============================================================
# 1. Config Package
# ============================================================
Write-Host "--- [1/3] Config Package ---" -ForegroundColor Magenta
$ConfigBuild = Join-Path $BuildDir $ConfigName
$null = New-Item -ItemType Directory -Force $ConfigBuild
Invoke-CopyConfig $ConfigBuild
# Project files
Copy-IfExists "README.MD" $ConfigBuild
Copy-IfExists ".gitignore" $ConfigBuild
Invoke-Pack $ConfigName $ConfigBuild "Config (scripts+settings+fonts+OSC)"

# ============================================================
# 2. Base Package
# ============================================================
Write-Host "--- [2/3] Base Package ---" -ForegroundColor Magenta
$BaseBuild = Join-Path $BuildDir $BaseName
$null = New-Item -ItemType Directory -Force $BaseBuild

# Config content
Invoke-CopyConfig $BaseBuild

# MPV core
Write-Host "       Copying mpv core..." -ForegroundColor Gray
Copy-IfExists "mpv.exe" $BaseBuild
Copy-IfExists "mpv.com" $BaseBuild

# Runtime DLLs
Write-Host "       Copying runtime DLLs..." -ForegroundColor Gray
$runtimeDlls = @(
    "lua51.dll", "vulkan-1.dll",
    "sqlite3.dll", "libcrypto-3.dll", "libssl-3.dll", "libffi-8.dll",
    "concrt140.dll", "msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll",
    "msvcp140_atomic_wait.dll", "msvcp140_codecvt_ids.dll",
    "vccorlib140.dll", "vcruntime140.dll", "vcruntime140_1.dll",
    "vcruntime140_threads.dll"
)
foreach ($dll in $runtimeDlls) { Copy-IfExists $dll $BaseBuild }
Copy-IfExists "luajit.exe" $BaseBuild

# Lua runtime
Write-Host "       Copying Lua runtime..." -ForegroundColor Gray
Invoke-CopyTo $BaseBuild @("lua", "mime", "socket")

# MPV data
Invoke-CopyTo $BaseBuild @("mpv", "doc")

# Installer tools
Write-Host "       Copying installer tools..." -ForegroundColor Gray
Invoke-CopyTo $BaseBuild @("installer", "updater.bat")

# Single-instance tool
Copy-IfExists "umpv.exe" $BaseBuild
Copy-IfExists "umpv.conf" $BaseBuild

# 7z extractor (needed to unpack extras)
Invoke-CopyTo $BaseBuild @("7z.exe", "7z.dll", "7z")

# Project files
Copy-IfExists "README.MD" $BaseBuild
Copy-IfExists ".gitignore" $BaseBuild

Invoke-Pack $BaseName $BaseBuild "Base (core player + runtime + config)"

# ============================================================
# 3. Extras Package
# ============================================================
Write-Host "--- [3/3] Extras Package ---" -ForegroundColor Magenta
$ExtrasBuild = Join-Path $BuildDir $ExtrasName
$null = New-Item -ItemType Directory -Force $ExtrasBuild

# Shaders
Write-Host "       Copying shaders (~129MB)..." -ForegroundColor Gray
$shadersSrc = Join-Path $RootDir "portable_config\shaders"
$shadersDst = Join-Path $ExtrasBuild "portable_config\shaders"
if (Test-Path $shadersSrc) {
    $null = New-Item -ItemType Directory -Force $shadersDst
    Copy-Item -Recurse -Force "$shadersSrc\*" $shadersDst
}

# VapourSynth scripts
Write-Host "       Copying VapourSynth scripts..." -ForegroundColor Gray
$vsScriptsSrc = Join-Path $RootDir "portable_config\vs"
$vsScriptsDst = Join-Path $ExtrasBuild "portable_config\vs"
if (Test-Path $vsScriptsSrc) {
    $null = New-Item -ItemType Directory -Force $vsScriptsDst
    Copy-Item -Recurse -Force "$vsScriptsSrc\*" $vsScriptsDst
}

# VapourSynth plugins (the big one)
Write-Host "       Copying VapourSynth plugins (~4GB)..." -ForegroundColor Gray
Invoke-CopyTo $ExtrasBuild @("vs-plugins", "vs-coreplugins", "vs-scripts")

# VapourSynth binaries
Write-Host "       Copying VapourSynth binaries..." -ForegroundColor Gray
$vsBinaries = @(
    "VSPipe.exe", "VSScript.dll", "VSScriptPython38.dll",
    "VSVFW.dll", "AVFS.exe", "pfm-192-vapoursynth-win.exe",
    "portable.vs"
)
foreach ($b in $vsBinaries) { Copy-IfExists $b $ExtrasBuild }

# VS SDK + tools
Invoke-CopyTo $ExtrasBuild @("sdk", "vsgenstubs.py", "vsgenstubs4", "vsrepo.py", "MANIFEST.in")

# Python runtime
Write-Host "       Copying Python runtime (~130MB)..." -ForegroundColor Gray
$pythonFiles = @(
    "python.exe", "pythonw.exe", "python314.dll",
    "python314.zip", "python3.dll", "python314._pth", "python.cat"
)
foreach ($pf in $pythonFiles) { Copy-IfExists $pf $ExtrasBuild }
foreach ($pyd in Get-ChildItem "$RootDir\*.pyd" -ErrorAction Ignore) {
    Copy-Item $pyd.FullName $ExtrasBuild
}
Invoke-CopyTo $ExtrasBuild @("Lib", "Scripts")

# AI subtitle (empty directory structure)
Write-Host "       Preserving AI subtitle directory..." -ForegroundColor Gray
$fasterWhisper = Join-Path $ExtrasBuild "Faster-Whisper-XXL"
$null = New-Item -ItemType Directory -Force $fasterWhisper

# Other tools
Write-Host "       Copying extra tools..." -ForegroundColor Gray
foreach ($tool in @("TorrServer-windows-amd64.exe", "alass.exe", "get-pip.py")) {
    Copy-IfExists $tool $ExtrasBuild
}

# Readme for extras
$extrasReadme = Join-Path $ExtrasBuild "EXTRAS-README.txt"
@"
MPV Portable Extras v${Version}
==============================
Extract to the same directory as the Base package
for the complete MPV experience.

Contains:
- Shaders (portable_config/shaders/)    129 MB
- VapourSynth plugins (vs-plugins/)     ~4 GB
- VapourSynth scripts (portable_config/vs/)
- Python runtime                        127 MB
- AI subtitle placeholder (Faster-Whisper-XXL/)
- Extra tools (TorrServer, alass)       75 MB

Note: Faster-Whisper-XXL/ folder is empty.
Download the Faster-Whisper-XXL model separately for AI subtitles.
"@ | Set-Content $extrasReadme -Encoding UTF8

# Extras uses split volumes due to size
Invoke-Pack $ExtrasName $ExtrasBuild "Extras (shaders + VS + AI + tools)" -Split

# ============================================================
# Cleanup
# ============================================================
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }

# ============================================================
# Done
# ============================================================
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Get-ChildItem (Join-Path $OutputDir "*.7z*") | ForEach-Object {
    $sizeMB = [math]::Round($_.Length/1MB, 1)
    Write-Host "  $($_.Name)  (${sizeMB} MB)" -ForegroundColor White
}
Write-Host ""
Write-Host "Output directory: $(Resolve-Path $OutputDir)" -ForegroundColor Cyan
Write-Host "Next step: Create GitHub Release and upload these files" -ForegroundColor Cyan
