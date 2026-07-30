param(
    [ValidateSet(2, 3, 4)]
    [int]$Multiplier = 2,

    [ValidateRange(0.25, 1.0)]
    [double]$FlowScale = 1.0,

    [switch]$Performance,
    [switch]$NoFp16,
    [switch]$DebugLayer,
    [switch]$KeepOtherVulkanLayers,
    [switch]$Disable,

    [string]$MpvArgumentsFile,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$MpvArguments
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Mpv = Join-Path $Root 'mpv.exe'
$LosslessDll = Join-Path $Root 'Lossless Scaling/Lossless.dll'
$LayerRoot = Join-Path $Root 'lsfg-vk'
$LayerDll = Join-Path $LayerRoot 'lsfg-vk-layer.dll'
$LayerManifest = Join-Path $LayerRoot 'VkLayer_LSFGVK_frame_generation.json'
$RuntimeManifestRoot = Join-Path $LayerRoot 'runtime-manifest'
$RuntimeManifest = Join-Path $RuntimeManifestRoot 'VkLayer_LSFGVK_frame_generation.json'
$TelemetryPath = Join-Path $LayerRoot 'telemetry.json'

if (-not (Test-Path -LiteralPath $Mpv)) {
    throw "找不到 mpv：$Mpv"
}

# 原生进程调用 Windows PowerShell 时，数组参数只会绑定第一个值；菜单改用 JSON 参数文件。.
if ($MpvArgumentsFile) {
    if (-not (Test-Path -LiteralPath $MpvArgumentsFile)) {
        throw "找不到 mpv 参数文件：$MpvArgumentsFile"
    }

    $ParsedArguments = Get-Content -LiteralPath $MpvArgumentsFile -Raw -Encoding UTF8 |
        ConvertFrom-Json
    $MpvArguments = @($ParsedArguments)
    Remove-Item -LiteralPath $MpvArgumentsFile -Force

    # Lua 脚本写入所有可用帧率属性（JSON），取首个正值用作 Layer 源帧率
    $SourceFpsFile = Join-Path $LayerRoot 'lsfg-source-fps'
    $SourceFpsLog = Join-Path $LayerRoot 'lsfg-source-fps-debug.log'
    if (Test-Path -LiteralPath $SourceFpsFile) {
        $fpsData = Get-Content -LiteralPath $SourceFpsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $candidates = @($fpsData.container_fps, $fpsData.estimated_vf_fps,
                        $fpsData.video_fps, $fpsData.display_fps)
        $bestFps = $candidates | Where-Object { $_ -and $_ -gt 0 } | Select-Object -First 1
        if ($bestFps) {
            $env:LSFGVK_SOURCE_FPS = $bestFps.ToString(
                [Globalization.CultureInfo]::InvariantCulture)
            "picked source_fps=$bestFps from $($fpsData | ConvertTo-Json -Compress)" |
                Out-File -LiteralPath $SourceFpsLog -Encoding utf8
        } else {
            "all fps props <= 0: $($fpsData | ConvertTo-Json -Compress)" |
                Out-File -LiteralPath $SourceFpsLog -Encoding utf8
        }
        Remove-Item -LiteralPath $SourceFpsFile -Force
    } else {
        "source_fps file NOT FOUND" |
            Out-File -LiteralPath $SourceFpsLog -Encoding utf8
    }
}

# 从已启用 LSFG 的 mpv 切回普通播放时，子进程会继承环境变量，需要显式清理。.
if ($Disable) {
    foreach ($name in @(
        'LSFGVK_ENV',
        'LSFGVK_DLL_PATH',
        'LSFGVK_MULTIPLIER',
        'LSFGVK_FLOW_SCALE',
        'LSFGVK_PERFORMANCE_MODE',
        'LSFGVK_PACING',
        'LSFGVK_NO_FP16',
        'LSFGVK_TELEMETRY_PATH',
        'VK_LOADER_DEBUG',
        'VK_LOADER_LAYERS_DISABLE'
    )) {
        Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
    $env:DISABLE_LSFGVK = '1'
    Remove-Item -LiteralPath $TelemetryPath -Force -ErrorAction SilentlyContinue

    & $Mpv @MpvArguments
    exit $LASTEXITCODE
}

foreach ($required in @($LosslessDll, $LayerDll, $LayerManifest)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "缺少 LSFG 启动所需文件：$required"
    }
}

# Windows Vulkan Loader 不会可靠地以清单目录解析相对 DLL 路径，启动时生成绝对路径清单。.
$null = New-Item -ItemType Directory -Force -Path $RuntimeManifestRoot
$ManifestData = Get-Content -LiteralPath $LayerManifest -Raw -Encoding UTF8 | ConvertFrom-Json
$ManifestData.layer.library_path = $LayerDll
$ManifestJson = $ManifestData | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($RuntimeManifest, $ManifestJson, [Text.UTF8Encoding]::new($false))

$env:VK_ADD_IMPLICIT_LAYER_PATH = if ($env:VK_ADD_IMPLICIT_LAYER_PATH) {
    "$RuntimeManifestRoot;$env:VK_ADD_IMPLICIT_LAYER_PATH"
} else {
    $RuntimeManifestRoot
}

# 录屏和游戏平台的隐式层可能改写同一个交换链，研究模式默认隔离它们。.
if (-not $KeepOtherVulkanLayers) {
    $env:VK_LOADER_LAYERS_DISABLE = '*OBS*,*steam*'
}

Remove-Item -LiteralPath 'Env:DISABLE_LSFGVK' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $TelemetryPath -Force -ErrorAction SilentlyContinue
$env:LSFGVK_ENV = '1'
$env:LSFGVK_DLL_PATH = $LosslessDll
$env:LSFGVK_MULTIPLIER = $Multiplier.ToString([Globalization.CultureInfo]::InvariantCulture)
$env:LSFGVK_FLOW_SCALE = $FlowScale.ToString([Globalization.CultureInfo]::InvariantCulture)
$env:LSFGVK_PERFORMANCE_MODE = if ($Performance) { '1' } else { '0' }
$env:LSFGVK_PACING = 'none'
$env:LSFGVK_NO_FP16 = if ($NoFp16) { '1' } else { '0' }
$env:LSFGVK_TELEMETRY_PATH = $TelemetryPath

if ($DebugLayer) {
    $env:VK_LOADER_DEBUG = 'error,warn,layer'
}

# FIFO 模式确保 QueuePresentKHR 以源帧率调用，避免 MAILBOX 下 LSFG 误读显示器刷新率
& $Mpv '--vo=gpu-next' '--gpu-api=vulkan' '--gpu-context=winvk' '--vulkan-swap-mode=fifo' @MpvArguments
exit $LASTEXITCODE
