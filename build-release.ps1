
<#
.SYNOPSIS
    MPV Portable 三包发布打包脚本
.DESCRIPTION
    生成三个包:
      - mpv-config-vX.Y.Z.7z     配置文件 (脚本/设置/字体/OSC)
      - mpv-base-vX.Y.Z.7z       核心播放器 + Config包 = 解压即用
      - mpv-extras-vX.Y.Z.7z     着色器 + VapourSynth + AI + 工具 (分卷)
.PARAMETER Version
    版本号，例如 "1.0.0"
.PARAMETER OutputDir
    输出目录，默认为 ./release
.EXAMPLE
    .\build-release.ps1 -Version "1.0.0"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [string]$OutputDir = "release"
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RootDir

# ── 工具 ──────────────────────────────────────────
$7z = Join-Path $RootDir "7z.exe"
if (-not (Test-Path $7z)) {
    Write-Error "找不到 7z.exe，请确保在 mpv 根目录运行此脚本"
    exit 1
}

# ── 输出目录 ──────────────────────────────────────
$null = New-Item -ItemType Directory -Force (Join-Path $RootDir $OutputDir)
$BuildDir = Join-Path $RootDir "build"
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }

# ── 包名定义 ──────────────────────────────────────
$ConfigName = "mpv-config-v$Version"
$BaseName   = "mpv-base-v$Version"
$ExtrasName = "mpv-extras-v$Version"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   MPV Portable 三包打包脚本 v$Version".PadRight(51) + "║"
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════════

function Invoke-Pack {
    param([string]$ArchiveName, [string]$SourceDir, [string]$Description, [switch]$Split)
    $archivePath = Join-Path $OutputDir $ArchiveName
    Write-Host "📦 打包: $Description" -ForegroundColor Yellow
    Write-Host "   输出: $archivePath.7z" -ForegroundColor Gray

    if (Test-Path "$archivePath.7z") { Remove-Item -Force "$archivePath.7z" }
    if (Test-Path "$archivePath.7z.001") {
        Remove-Item -Force "$archivePath.7z.*"
    }

    if ($Split) {
        # 分卷: 每卷最大 1900MB (< GitHub 2GB 限制)
        & $7z a -t7z -mx=7 -md=64m -ms=on -v1900m "$archivePath.7z" "$SourceDir\*"
    } else {
        & $7z a -t7z -mx=7 -md=64m -ms=on "$archivePath.7z" "$SourceDir\*"
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error "打包失败: $Description"
        exit 1
    }

    $size = if ($Split) {
        (Get-ChildItem "$archivePath.7z.*" | Measure-Object -Property Length -Sum).Sum
    } else {
        (Get-Item "$archivePath.7z").Length
    }
    Write-Host "   ✓ 完成 ($([math]::Round($size/1MB, 1)) MB)" -ForegroundColor Green
    Write-Host ""
}

function Invoke-CopyFiles {
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
    Write-Host "   复制 portable_config/ (排除 shaders vs cache files)..." -ForegroundColor Gray
    $null = New-Item -ItemType Directory -Force $configDest
    Copy-Item -Recurse -Force "$configSrc\*" $configDest
    # 排除重内容
    foreach ($exclude in @("shaders", "vs", "cache", "files")) {
        $exPath = Join-Path $configDest $exclude
        if (Test-Path $exPath) { Remove-Item -Recurse -Force $exPath }
    }
}

# ═══════════════════════════════════════════════════
# 1. Config包
# ═══════════════════════════════════════════════════
Write-Host "─── ① Config 包 ───" -ForegroundColor Magenta
$ConfigBuild = Join-Path $BuildDir $ConfigName
$null = New-Item -ItemType Directory -Force $ConfigBuild
Invoke-CopyConfig $ConfigBuild
# 项目文件
Copy-Item (Join-Path $RootDir "README.MD") $ConfigBuild
Copy-Item (Join-Path $RootDir ".gitignore") $ConfigBuild
Invoke-Pack $ConfigName $ConfigBuild "Config 包 (脚本+配置+字体+OSC)"

# ═══════════════════════════════════════════════════
# 2. Base包
# ═══════════════════════════════════════════════════
Write-Host "─── ② Base 包 ───" -ForegroundColor Magenta
$BaseBuild = Join-Path $BuildDir $BaseName
$null = New-Item -ItemType Directory -Force $BaseBuild

# Config包内容
Invoke-CopyConfig $BaseBuild

# MPV 主程序
Write-Host "   复制 mpv 核心..." -ForegroundColor Gray
Copy-Item (Join-Path $RootDir "mpv.exe") $BaseBuild
Copy-Item (Join-Path $RootDir "mpv.com") $BaseBuild

# 运行时 DLL
Write-Host "   复制运行时 DLL..." -ForegroundColor Gray
$runtimeDlls = @(
    "lua51.dll", "luajit.exe", "vulkan-1.dll",
    "sqlite3.dll", "libcrypto-3.dll", "libssl-3.dll", "libffi-8.dll",
    "concrt140.dll", "msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll",
    "msvcp140_atomic_wait.dll", "msvcp140_codecvt_ids.dll",
    "vccorlib140.dll", "vcruntime140.dll", "vcruntime140_1.dll",
    "vcruntime140_threads.dll"
)
foreach ($dll in $runtimeDlls) {
    $src = Join-Path $RootDir $dll
    if (Test-Path $src) { Copy-Item $src $BaseBuild }
}

# Lua 运行时
Write-Host "   复制 Lua 运行时..." -ForegroundColor Gray
Invoke-CopyFiles $BaseBuild @("lua", "mime", "socket")

# MPV 数据
Invoke-CopyFiles $BaseBuild @("mpv", "doc")

# 安装/更新工具
Write-Host "   复制安装工具..." -ForegroundColor Gray
Invoke-CopyFiles $BaseBuild @("installer", "updater.bat")

# 单实例工具
foreach ($f in @("umpv.exe", "umpv.conf")) {
    $s = Join-Path $RootDir $f
    if (Test-Path $s) { Copy-Item $s $BaseBuild }
}

# 7z 解压工具 (需要用来解压增量包)
Invoke-CopyFiles $BaseBuild @("7z.exe", "7z.dll", "7z")

# 项目文件
Copy-Item (Join-Path $RootDir "README.MD") $BaseBuild
Copy-Item (Join-Path $RootDir ".gitignore") $BaseBuild

Invoke-Pack $BaseName $BaseBuild "Base 包 (核心播放器 + 运行时 + 配置)"

# ═══════════════════════════════════════════════════
# 3. 增量包 (Extras)
# ═══════════════════════════════════════════════════
Write-Host "─── ③ 增量包 ───" -ForegroundColor Magenta
$ExtrasBuild = Join-Path $BuildDir $ExtrasName
$null = New-Item -ItemType Directory -Force $ExtrasBuild

# 着色器
Write-Host "   复制着色器 (shaders/)..." -ForegroundColor Gray
$shadersSrc = Join-Path $RootDir "portable_config\shaders"
$shadersDst = Join-Path $ExtrasBuild "portable_config\shaders"
if (Test-Path $shadersSrc) {
    $null = New-Item -ItemType Directory -Force $shadersDst
    Copy-Item -Recurse -Force "$shadersSrc\*" $shadersDst
}

# VapourSynth 脚本
Write-Host "   复制 VapourSynth 脚本..." -ForegroundColor Gray
$vsScriptsSrc = Join-Path $RootDir "portable_config\vs"
$vsScriptsDst = Join-Path $ExtrasBuild "portable_config\vs"
if (Test-Path $vsScriptsSrc) {
    $null = New-Item -ItemType Directory -Force $vsScriptsDst
    Copy-Item -Recurse -Force "$vsScriptsSrc\*" $vsScriptsDst
}

# VapourSynth 插件 (最大的部分)
Write-Host "   复制 VapourSynth 插件 (~4GB)..." -ForegroundColor Gray
Invoke-CopyFiles $ExtrasBuild @("vs-plugins", "vs-coreplugins", "vs-scripts")

# VapourSynth 二进制
Write-Host "   复制 VapourSynth 二进制..." -ForegroundColor Gray
$vsBinaries = @(
    "VSPipe.exe", "VSScript.dll", "VSScriptPython38.dll",
    "VSVFW.dll", "AVFS.exe", "pfm-192-vapoursynth-win.exe",
    "portable.vs"
)
foreach ($b in $vsBinaries) {
    $s = Join-Path $RootDir $b
    if (Test-Path $s) { Copy-Item $s $ExtrasBuild }
}

# VS SDK + 工具
Invoke-CopyFiles $ExtrasBuild @("sdk", "vsgenstubs.py", "vsgenstubs4", "vsrepo.py", "MANIFEST.in")

# Python 运行时
Write-Host "   复制 Python 运行时 (~130MB)..." -ForegroundColor Gray
$pythonFiles = @(
    "python.exe", "pythonw.exe", "python314.dll",
    "python314.zip", "python3.dll", "python314._pth", "python.cat"
)
foreach ($pf in $pythonFiles) {
    $s = Join-Path $RootDir $pf
    if (Test-Path $s) { Copy-Item $s $ExtrasBuild }
}
# Python .pyd 扩展
foreach ($pyd in Get-ChildItem "$RootDir\*.pyd" -ErrorAction Ignore) {
    Copy-Item $pyd.FullName $ExtrasBuild
}
Invoke-CopyFiles $ExtrasBuild @("Lib", "Scripts")

# AI 字幕 (空目录结构)
Write-Host "   保留 AI 字幕目录结构..." -ForegroundColor Gray
$fasterWhisper = Join-Path $ExtrasBuild "Faster-Whisper-XXL"
$null = New-Item -ItemType Directory -Force $fasterWhisper

# 其他工具
Write-Host "   复制附加工具..." -ForegroundColor Gray
$tools = @(
    "TorrServer-windows-amd64.exe", "alass.exe",
    "get-pip.py"
)
foreach ($tool in $tools) {
    $s = Join-Path $RootDir $tool
    if (Test-Path $s) { Copy-Item $s $ExtrasBuild }
}

# 说明文件
$extrasReadme = Join-Path $ExtrasBuild "EXTRAS-README.txt"
@"
MPV Portable Extras v$Version
==============================
解压到 Base 包所在目录即可获得完整体验。

包含:
- 着色器 (portable_config/shaders/)    129 MB
- VapourSynth 插件 (vs-plugins/)      ~4 GB
- VapourSynth 脚本 (portable_config/vs/)
- Python 运行时                       127 MB
- AI 字幕结构 (Faster-Whisper-XXL/)    空 (需自行下载模型)
- 附加工具 (TorrServer, alass)         75 MB

⚠️ Faster-Whisper-XXL/ 目录为空，如需 AI 字幕功能，
请下载 Faster-Whisper-XXL 模型放到该目录。
"@ | Set-Content $extrasReadme -Encoding UTF8

# 增量包用分卷 (>2GB 时自动分割)
Invoke-Pack $ExtrasName $ExtrasBuild "增量包 (着色器 + VS + AI + 工具)" -Split

# ═══════════════════════════════════════════════════
# 清理
# ═══════════════════════════════════════════════════
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }

# ═══════════════════════════════════════════════════
# 完成
# ═══════════════════════════════════════════════════
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   打包完成!                                       ║"
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Get-ChildItem (Join-Path $OutputDir "*.7z*") | ForEach-Object {
    $sizeMB = [math]::Round($_.Length/1MB, 1)
    Write-Host "  $($_.Name)  ($sizeMB MB)" -ForegroundColor White
}
Write-Host ""
Write-Host "输出目录: $(Resolve-Path $OutputDir)" -ForegroundColor Cyan
Write-Host "下一步: 创建 GitHub Release 并上传这些文件" -ForegroundColor Cyan
