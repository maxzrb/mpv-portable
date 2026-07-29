param(
    [string]$OutputDir = 'release'
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$SevenZip = Join-Path $Root '7z.exe'
$LosslessRoot = Join-Path $Root 'Lossless Scaling'
$LayerDist = Join-Path $Root 'research/lsfg-vk-win/dist/windows'
$LayerDll = Join-Path $LayerDist 'bin/lsfg-vk-layer.dll'
$LayerManifest = Join-Path $LayerDist 'share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json'
$PackageName = '04-mpv-lsfg-research-private'
$Stage = Join-Path $Root "build/$PackageName"
$OutputRoot = Join-Path $Root $OutputDir
$Archive = Join-Path $OutputRoot "$PackageName.7z"

foreach ($required in @($SevenZip, $LosslessRoot, $LayerDll, $LayerManifest)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "缺少私有研究包所需文件：$required"
    }
}

if (Test-Path -LiteralPath $Stage) {
    Remove-Item -LiteralPath $Stage -Recurse -Force
}
$null = New-Item -ItemType Directory -Force -Path $Stage
$null = New-Item -ItemType Directory -Force -Path $OutputRoot

Copy-Item -LiteralPath $LosslessRoot -Destination $Stage -Recurse
$LayerTarget = Join-Path $Stage 'lsfg-vk'
$null = New-Item -ItemType Directory -Force -Path $LayerTarget
Copy-Item -LiteralPath $LayerDll -Destination $LayerTarget
Copy-Item -LiteralPath $LayerManifest -Destination $LayerTarget
Copy-Item -LiteralPath (Join-Path $Root 'start-mpv-lsfg.ps1') -Destination $Stage

$ConfigTarget = Join-Path $Stage 'portable_config'
$ScriptsTarget = Join-Path $ConfigTarget 'scripts'
$null = New-Item -ItemType Directory -Force -Path $ScriptsTarget
Copy-Item -LiteralPath (Join-Path $Root 'portable_config/input.conf') `
    -Destination $ConfigTarget
Copy-Item -LiteralPath (Join-Path $Root 'portable_config/scripts/lsfg_control.lua') `
    -Destination $ScriptsTarget
Copy-Item -LiteralPath (Join-Path $Root 'portable_config/scripts/quality_status.lua') `
    -Destination $ScriptsTarget
Copy-Item -LiteralPath (Join-Path $Root 'portable_config/scripts/stats.lua') `
    -Destination $ScriptsTarget

$ResearchTarget = Join-Path $Stage 'research/lsfg-vk-win'
$null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ResearchTarget)
Copy-Item -LiteralPath (Join-Path $Root 'research/lsfg-vk-win') `
    -Destination $ResearchTarget -Recurse

$Readme = Join-Path $Stage 'README-私有研究包.txt'
@'
本包只用于本地 LSFG Windows Vulkan Layer 研究。

安装与覆盖顺序：
  01. 01-mpv-base-vX.Y.Z.7z
  02. 02-mpv-config-vX.Y.Z.7z（同版本 Base 已含 Config，可跳过）
  03. 03-mpv-extras-vX.Y.Z.7z.001（将 .002 放在同目录，只解压 .001）
  04. 04-mpv-lsfg-research-private.7z（本包，必须最后覆盖）

如果以后重新覆盖 Base 或 Config，必须再次解压本私有包，否则 LSFG 菜单、
控制脚本和跟随 stats 的遥测显示可能被公开包中的配置覆盖。

解压到现有 mpv 根目录后，用 PowerShell 运行：
  .\start-mpv-lsfg.ps1 -Multiplier 2 "视频文件.mkv"

也可以正常打开视频，然后在：
  右键菜单 → 视频滤镜 → 补帧
选择 LSFG 测试档位。菜单会保存当前进度并自动重启播放。
LSFG 启用后按 Tab 打开常驻统计 OSD，右上角会同步显示原始与实时 Present FPS。

包内包含用户自行提供的完整 Lossless Scaling 目录、Layer 运行文件及对应 GPL 源码。
不要将本私有包直接上传到公开 Release。
'@ | Set-Content -LiteralPath $Readme -Encoding UTF8

if (Test-Path -LiteralPath $Archive) {
    Remove-Item -LiteralPath $Archive -Force
}
& $SevenZip a -t7z -mx=7 -md=64m -ms=on $Archive "$Stage\*"
if ($LASTEXITCODE -ne 0) { throw '私有研究包创建失败' }

Write-Host "私有研究包已生成：$Archive" -ForegroundColor Green
