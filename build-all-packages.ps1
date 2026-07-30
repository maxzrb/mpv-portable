param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$OutputDir = 'release',

    [switch]$IncludePrivate
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot

Write-Host "开始构建 MPV v${Version} 五个公开包" -ForegroundColor Cyan
& (Join-Path $Root 'build-release.ps1') -Version $Version -OutputDir $OutputDir
if ($LASTEXITCODE -ne 0) { throw '01～02 包构建失败' }

& (Join-Path $Root 'build-fasterwhisper-public.ps1') -Version $Version -OutputDir $OutputDir
if ($LASTEXITCODE -ne 0) { throw '03 Faster-Whisper 扩展包构建失败' }

& (Join-Path $Root 'build-lsfg-public.ps1') -Version $Version -OutputDir $OutputDir
if ($LASTEXITCODE -ne 0) { throw '04 LSFG 扩展包构建失败' }

& (Join-Path $Root 'build-config-public.ps1') -Version $Version -OutputDir $OutputDir
if ($LASTEXITCODE -ne 0) { throw '05 Config 包构建失败' }

if ($IncludePrivate) {
    Write-Host '继续构建个人私用全量包' -ForegroundColor Yellow
    & (Join-Path $Root 'build-full-private.ps1') -Version $Version -OutputDir $OutputDir
    if ($LASTEXITCODE -ne 0) { throw '个人私用全量包构建失败' }
}

Write-Host "MPV v${Version} 打包完成：$(Join-Path $Root $OutputDir)" -ForegroundColor Green
