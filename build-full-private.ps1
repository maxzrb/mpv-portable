param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$OutputDir = 'release'
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$SevenZip = Join-Path $Root '7z.exe'
$OutputRoot = Join-Path $Root $OutputDir
$PackageName = "mpv-full-private-v${Version}"
$Stage = Join-Path $Root "build/$PackageName"
$Archive = Join-Path $OutputRoot "$PackageName.7z"

$BaseArchive = Join-Path $OutputRoot "01-mpv-base-v${Version}.7z"
$ConfigArchive = Join-Path $OutputRoot "02-mpv-config-v${Version}.7z"
$ExtrasArchive = Join-Path $OutputRoot "03-mpv-extras-v${Version}.7z.001"
$AddonArchive = Join-Path $OutputRoot "04-mpv-lsfg-addon-v${Version}.7z"
$LosslessDll = Join-Path $Root 'Lossless Scaling/Lossless.dll'

foreach ($required in @(
    $SevenZip,
    $BaseArchive,
    $ConfigArchive,
    $ExtrasArchive,
    $AddonArchive,
    $LosslessDll
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "缺少个人全量包所需文件：$required"
    }
}

if (Test-Path -LiteralPath $Stage) {
    Remove-Item -LiteralPath $Stage -Recurse -Force
}
$null = New-Item -ItemType Directory -Force -Path $Stage
$null = New-Item -ItemType Directory -Force -Path $OutputRoot

function Expand-Package {
    param([string]$ArchivePath)

    Write-Host "覆盖解压：$(Split-Path -Leaf $ArchivePath)" -ForegroundColor DarkGray
    & $SevenZip x -y "-o$Stage" $ArchivePath
    if ($LASTEXITCODE -ne 0) {
        throw "解压失败：$ArchivePath"
    }
}

# 严格按公开四包的覆盖顺序合并。
Expand-Package $BaseArchive
Expand-Package $ConfigArchive
Expand-Package $ExtrasArchive
Expand-Package $AddonArchive

$LosslessTarget = Join-Path $Stage 'Lossless Scaling'
$null = New-Item -ItemType Directory -Force -Path $LosslessTarget
$Placeholder = Join-Path $LosslessTarget '请从Steam复制Lossless.dll到此目录.txt'
if (Test-Path -LiteralPath $Placeholder) {
    Remove-Item -LiteralPath $Placeholder -Force
}
Copy-Item -LiteralPath $LosslessDll -Destination $LosslessTarget -Force

$PrivateReadme = Join-Path $Stage 'README-个人私用全量包.txt'
@"
MPV 个人私用全量包 v${Version}

本包按以下顺序合并：
  01. 01-mpv-base-v${Version}.7z
  02. 02-mpv-config-v${Version}.7z
  03. 03-mpv-extras-v${Version}.7z.001/.002
  04. 04-mpv-lsfg-addon-v${Version}.7z

并加入用户从正版 Steam 版 Lossless Scaling 自行提供的：
  Lossless Scaling\Lossless.dll

这是四个公开包的完整并集，并包含播放器、配置、着色器、VapourSynth、Python、
工具、LSFG 运行文件、LSFG 研究源码和公开包说明。除不再适用的 Lossless.dll
占位提示外，不主动删减公开包内容，解压后即可按项目配置使用。

本包含有用户个人购买软件中的专有文件，只限个人本地备份和使用。
不要上传 GitHub Release，不要公开分享或转售。
"@ | Set-Content -LiteralPath $PrivateReadme -Encoding UTF8

# 全量包门禁：不得再次套入 Release、build、tmp、Git 元数据或 Python 缓存。
$ForbiddenTopLevel = @('release', 'build', 'tmp', '.git')
foreach ($name in $ForbiddenTopLevel) {
    if (Test-Path -LiteralPath (Join-Path $Stage $name)) {
        throw "个人全量包含不允许的顶层目录：$name"
    }
}

$GeneratedDirs = @(Get-ChildItem -LiteralPath $Stage -Recurse -Directory -Force `
    -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -in @('__pycache__', '.pytest_cache', '.mypy_cache')
    })
if ($GeneratedDirs.Count -gt 0) {
    throw "个人全量包仍含缓存目录：$($GeneratedDirs.FullName -join ', ')"
}

$GeneratedExtensions = @(
    '.pyc', '.pyo', '.log', '.tmp', '.bak',
    '.pdb', '.obj', '.ilk', '.dmp'
)
$GeneratedFiles = @(Get-ChildItem -LiteralPath $Stage -Recurse -File -Force `
    -ErrorAction SilentlyContinue | Where-Object {
        $_.Extension.ToLowerInvariant() -in $GeneratedExtensions
    })
if ($GeneratedFiles.Count -gt 0) {
    throw "个人全量包仍含生成文件：$($GeneratedFiles.FullName -join ', ')"
}

$PrivateLosslessFiles = @(Get-ChildItem -LiteralPath $LosslessTarget -Recurse -File)
if ($PrivateLosslessFiles.Count -ne 1 `
        -or $PrivateLosslessFiles[0].Name -ne 'Lossless.dll') {
    throw "个人全量包的 Lossless Scaling 目录不符合完整私用包要求"
}

if (Test-Path -LiteralPath $Archive) {
    Remove-Item -LiteralPath $Archive -Force
}
& $SevenZip a -t7z -mx=7 -md=64m -ms=on $Archive "$Stage\*"
if ($LASTEXITCODE -ne 0) { throw '个人全量包创建失败' }

Write-Host "个人全量包已生成：$Archive" -ForegroundColor Green
