
<#
.SYNOPSIS
    MPV Portable Release Builder - numbered 3-package public build script
.DESCRIPTION
    Creates three numbered public packages in safe overwrite order:
      - 01-mpv-base-vX.Y.Z.7z     Core player + Config = ready to play
      - 02-mpv-config-vX.Y.Z.7z   Config files (scripts/settings/fonts/OSC)
      - 03-mpv-extras-vX.Y.Z.7z   Shaders + VapourSynth + AI + Tools (split volumes)
    The optional public LSFG add-on is generated separately as:
      - 04-mpv-lsfg-addon-vX.Y.Z.7z
.PARAMETER Version
    Version number, e.g. "1.0.0"
.PARAMETER SkipExtras
    Skip the large extras package when shaders, VapourSynth components,
    Python runtime, and extra tools have not changed.
.EXAMPLE
    .\build-release.ps1 -Version "1.0.0"
.EXAMPLE
    .\build-release.ps1 -Version "1.1.0" -SkipExtras
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [string]$OutputDir = "release",

    [switch]$SkipExtras
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

# 包名编号同时表示解压覆盖顺序。
$BaseName   = "01-mpv-base-v${Version}"
$ConfigName = "02-mpv-config-v${Version}"
$ExtrasName = "03-mpv-extras-v${Version}"

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

function Remove-GeneratedArtifacts {
    param([string]$TargetRoot)

    # 只清理明确由运行/编译过程生成的文件，不删除 Python 包自带的 tests 或源码。
    $cacheDirs = @(Get-ChildItem -LiteralPath $TargetRoot -Recurse -Directory -Force `
        -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -in @('__pycache__', '.pytest_cache', '.mypy_cache')
        } | Sort-Object FullName -Descending)
    foreach ($dir in $cacheDirs) {
        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
    }

    $generatedExtensions = @(
        '.pyc', '.pyo', '.log', '.tmp', '.bak',
        '.pdb', '.obj', '.ilk', '.dmp'
    )
    $generatedFiles = @(Get-ChildItem -LiteralPath $TargetRoot -Recurse -File -Force `
        -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension.ToLowerInvariant() -in $generatedExtensions
        })
    foreach ($file in $generatedFiles) {
        Remove-Item -LiteralPath $file.FullName -Force
    }
}

# ============================================================
# 1. Base Package
# ============================================================
Write-Host "--- [1/3] Base Package ---" -ForegroundColor Magenta
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

Remove-GeneratedArtifacts $BaseBuild
Invoke-Pack $BaseName $BaseBuild "Base (core player + runtime + config)"

# ============================================================
# 2. Config Package
# ============================================================
Write-Host "--- [2/3] Config Package ---" -ForegroundColor Magenta
$ConfigBuild = Join-Path $BuildDir $ConfigName
$null = New-Item -ItemType Directory -Force $ConfigBuild
Invoke-CopyConfig $ConfigBuild
# Project files
Copy-IfExists "README.MD" $ConfigBuild
Copy-IfExists ".gitignore" $ConfigBuild
Remove-GeneratedArtifacts $ConfigBuild
Invoke-Pack $ConfigName $ConfigBuild "Config (scripts+settings+fonts+OSC)"

# ============================================================
# 3. Extras Package
# ============================================================
if (-not $SkipExtras) {
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

    # Extras 包内说明同时保留完整的覆盖顺序，避免用户只下载分卷时漏看根 README。
    $extrasReadme = Join-Path $ExtrasBuild "EXTRAS-README.txt"
@"
MPV Portable 03 Extras v${Version}
==================================

安装与覆盖顺序：
  01. 01-mpv-base-vX.Y.Z.7z
  02. 02-mpv-config-vX.Y.Z.7z（同版本 Base 已含 Config，可跳过）
  03. 03-mpv-extras-vX.Y.Z.7z.001（本包；将 .002 放在同目录，只解压 .001）
  04. 04-mpv-lsfg-addon-v${Version}.7z（可选公开扩展包，建议最后安装）

请将本包解压到 Base 所在目录。LSFG 菜单与状态脚本由 Base/Config 管理，
04 只增加运行文件和源码；以后单独更新 Config 不需要重新解压 04。

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

    Remove-GeneratedArtifacts $ExtrasBuild

    # Extras uses split volumes due to size
    Invoke-Pack $ExtrasName $ExtrasBuild "Extras (shaders + VS + AI + tools)" -Split
} else {
    Write-Host "--- [3/3] Extras Package (skipped) ---" -ForegroundColor DarkGray
    Write-Host "       No extras content changed; reuse the previous compatible package." -ForegroundColor DarkGray
    Write-Host ""
}

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
$currentArchives = @(
    Get-ChildItem -Path (Join-Path $OutputDir "$BaseName.7z*") -ErrorAction Ignore
    Get-ChildItem -Path (Join-Path $OutputDir "$ConfigName.7z*") -ErrorAction Ignore
    Get-ChildItem -Path (Join-Path $OutputDir "$ExtrasName.7z*") -ErrorAction Ignore
)
$currentArchives | Sort-Object Name -Unique | ForEach-Object {
    $sizeMB = [math]::Round($_.Length/1MB, 1)
    Write-Host "  $($_.Name)  (${sizeMB} MB)" -ForegroundColor White
}
Write-Host ""
Write-Host "Output directory: $(Resolve-Path $OutputDir)" -ForegroundColor Cyan
Write-Host "Next step: Create GitHub Release and upload these files" -ForegroundColor Cyan
