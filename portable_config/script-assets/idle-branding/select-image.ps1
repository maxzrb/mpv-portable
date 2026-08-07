param(
    [Parameter(Mandatory = $true)]
    [string]$OutputRaw,
    [string]$InputPath = '',
    [ValidateRange(64, 2048)]
    [int]$MaxPixels = 512
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$selectedPath = $InputPath
if ([string]::IsNullOrWhiteSpace($selectedPath)) {
    Add-Type -AssemblyName PresentationFramework
    $dialog = [Microsoft.Win32.OpenFileDialog]::new()
    $dialog.Title = '选择 mpv 启动页图片'
    $dialog.Filter = 'Image files|*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.tif;*.tiff|All files|*.*'
    $dialog.Multiselect = $false
    if ($dialog.ShowDialog() -ne $true) {
        @{ cancelled = $true } | ConvertTo-Json -Compress
        exit 0
    }
    $selectedPath = $dialog.FileName
}

$resolvedPath = [System.IO.Path]::GetFullPath($selectedPath)
$stream = [System.IO.File]::Open(
    $resolvedPath,
    [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::Read,
    [System.IO.FileShare]::Read
)
try {
    $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
        $stream,
        [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    )
    $source = $decoder.Frames[0]
} finally {
    $stream.Dispose()
}

if ($source.PixelWidth -lt 1 -or $source.PixelHeight -lt 1) {
    throw 'Invalid image dimensions'
}

$scale = [Math]::Min(
    1.0,
    [Math]::Min(
        $MaxPixels / [double]$source.PixelWidth,
        $MaxPixels / [double]$source.PixelHeight
    )
)
if ($scale -lt 0.9999) {
    $transform = [System.Windows.Media.ScaleTransform]::new($scale, $scale)
    $source = [System.Windows.Media.Imaging.TransformedBitmap]::new($source, $transform)
}

# mpv overlay-add expects premultiplied BGRA alpha.
$converted = [System.Windows.Media.Imaging.FormatConvertedBitmap]::new(
    $source,
    [System.Windows.Media.PixelFormats]::Pbgra32,
    $null,
    0
)
$width = $converted.PixelWidth
$height = $converted.PixelHeight
$stride = $width * 4
$pixels = [byte[]]::new($stride * $height)
$converted.CopyPixels($pixels, $stride, 0)

$outputDirectory = [System.IO.Path]::GetDirectoryName($OutputRaw)
if (-not [System.IO.Directory]::Exists($outputDirectory)) {
    [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}
$temporaryRaw = "$OutputRaw.tmp-$PID"
try {
    [System.IO.File]::WriteAllBytes($temporaryRaw, $pixels)
    [System.IO.File]::Copy($temporaryRaw, $OutputRaw, $true)
} finally {
    if ([System.IO.File]::Exists($temporaryRaw)) {
        [System.IO.File]::Delete($temporaryRaw)
    }
}

@{
    cancelled = $false
    width = $width
    height = $height
    stride = $stride
    source_name = [System.IO.Path]::GetFileName($resolvedPath)
} | ConvertTo-Json -Compress
