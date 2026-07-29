param(
    [Parameter(Mandatory = $true)]
    [string]$ToolchainRoot,

    [Parameter(Mandatory = $true)]
    [string]$CMakeRoot,

    [Parameter(Mandatory = $true)]
    [string]$NinjaPath
)

$ErrorActionPreference = 'Stop'
$SourceRoot = $PSScriptRoot
$BuildRoot = Join-Path $SourceRoot 'build/windows-x64'
$InstallRoot = Join-Path $SourceRoot 'dist/windows'
$CMake = Join-Path $CMakeRoot 'bin/cmake.exe'

if (-not (Test-Path -LiteralPath $CMake)) {
    throw "找不到 CMake：$CMake"
}
if (-not (Test-Path -LiteralPath $NinjaPath)) {
    throw "找不到 Ninja：$NinjaPath"
}

$CompilerCandidates = @(
    (Join-Path $ToolchainRoot 'bin/x86_64-w64-mingw32-clang++.exe'),
    (Join-Path $ToolchainRoot 'bin/clang++.exe'),
    (Join-Path $ToolchainRoot 'bin/g++.exe')
)
$Compiler = $CompilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $Compiler) {
    throw "在 $ToolchainRoot 中找不到可用的 x86_64 C++ 编译器"
}

# GCC/Clang 会按名称启动汇编器和链接器，因此只对子进程临时补充工具链 PATH。
$env:Path = "$(Join-Path $ToolchainRoot 'bin');$env:Path"

$null = New-Item -ItemType Directory -Force -Path $BuildRoot
$null = New-Item -ItemType Directory -Force -Path $InstallRoot

& $CMake --fresh -S $SourceRoot -B $BuildRoot -G Ninja `
    "-DCMAKE_MAKE_PROGRAM=$NinjaPath" `
    "-DCMAKE_CXX_COMPILER=$Compiler" `
    '-DCMAKE_BUILD_TYPE=Release' `
    '-DLSFGVK_BUILD_UI=OFF' `
    '-DLSFGVK_BUILD_CLI=OFF' `
    '-DLSFGVK_BUILD_VK_LAYER=ON' `
    "-DCMAKE_INSTALL_PREFIX=$InstallRoot" `
    '-DLSFGVK_LAYER_LIBRARY_PATH=lsfg-vk-layer.dll'
if ($LASTEXITCODE -ne 0) { throw 'CMake 配置失败' }

& $CMake --build $BuildRoot --parallel
if ($LASTEXITCODE -ne 0) { throw '编译失败' }

& $CMake --install $BuildRoot
if ($LASTEXITCODE -ne 0) { throw '安装失败' }

Write-Host "Windows Layer 已生成：$InstallRoot" -ForegroundColor Green
