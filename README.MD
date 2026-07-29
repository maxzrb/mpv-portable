# MPV Portable

> 个人定制版 MPV 便携播放器，按编号覆盖、按需组装。
>
> Fork from [gaoxing64/MPV-lazy-full](https://github.com/gaoxing64/MPV-lazy-full) v2.0.0

## 四类包的关系

```
01 Base（核心播放器，已包含 Config）
   ↓ 可选覆盖
02 Config（只更新配置；同版本可跳过）
   ↓ 追加
03 Extras（着色器、VapourSynth、Python 与工具）
   ↓ 最后覆盖
04 LSFG 公开扩展包（不含 Steam 文件，用户自行提供 Lossless.dll）
```

| 顺序 | 包 | 解压即用？ | 内容 |
|------|----|------------|------|
| **01** | **Base** | ✅ 基本播放 | Config + mpv 核心 + 运行时 |
| **02** | **Config** | ✗ 需要 mpv 本体 | 脚本、设置、OSC 主题、字体；同版本 Base 已包含，可跳过 |
| **03** | **Extras** | ✗ 需要 Base | 着色器、VapourSynth 补帧/超分、AI 字幕、工具 |
| **04** | **LSFG 公开扩展包** | ✗ 需要 Base 及正版 Steam 文件 | GPL Vulkan Layer、启动器和对应源码；不含 Lossless Scaling 文件 |

## 安装与覆盖顺序

四类包全部安装时，必须按文件名前缀从小到大覆盖：

1. `01-mpv-base-vX.Y.Z.7z`
2. `02-mpv-config-vX.Y.Z.7z`（同版本 Base 已包含 Config，可跳过）
3. `03-mpv-extras-vX.Y.Z.7z.001`（`.002` 放在同一目录，只解压 `.001`）
4. `04-mpv-lsfg-addon-vX.Y.Z.7z`（可选，建议最后安装）

LSFG 菜单、控制和状态脚本归 Base/Config 管理，04 只增加运行层、启动器、源码
和说明，不覆盖 Config 或 Extras。以后单独更新 Config 不需要重新解压 04。

`04` 可以公开分发，但出于版权边界不包含 Lossless Scaling 的 DLL 或模型资源。
使用者需要购买并安装 Steam 版 Lossless Scaling，然后只把其安装目录根部的
`Lossless.dll` 复制到 `<mpv根目录>\Lossless Scaling\Lossless.dll`。
不需要复制 `LosslessScaling.dll`、语言资源 DLL、.NET/WPF DLL 或任何 EXE。

个人本地也可以生成 `mpv-full-private-vX.Y.Z.7z`。它会按 01～04 的顺序合并全部
公开包，再加入本机 `Lossless Scaling\Lossless.dll`，形成解压即用的一体包。
该包含有个人购买软件中的专有文件，只能本地备份和使用，不能公开上传。

## 下载与安装

### 方案一：完整安装（推荐）

从 [Releases](https://github.com/maxzrb/mpv-portable/releases) 下载：

1. 下载 `01-mpv-base-vX.Y.Z.7z`
2. 下载 `03-mpv-extras-vX.Y.Z.7z.001` 和 `.002`（两个分卷都需要）
3. 解压 Base 包到你想要的位置
4. 解压 Extras 包到**同一目录**（用 7-Zip 打开 `.001` 即可）
5. 运行 `mpv.exe`

```
最终目录结构：
mpv-portable/
├── mpv.exe
├── portable_config/    ← Config 包的完整内容
│   ├── mpv.conf
│   ├── scripts/        ← 所有 Lua 脚本
│   ├── shaders/        ← Extras 包的着色器
│   └── vs/             ← Extras 包的 VapourSynth 脚本
├── vs-plugins/         ← Extras 包的 VS 插件
├── lua51.dll, vulkan-1.dll, ...
└── ...
```

### 方案二：只用配置

已有 mpv 播放器，只想用这套配置：

1. 下载 `02-mpv-config-vX.Y.Z.7z`
2. 解压到 mpv 的配置目录（覆盖 `portable_config/`）

### 方案三：手动组装

1. 下载任意标准 mpv Windows 构建
2. 下载 `02-mpv-config-vX.Y.Z.7z`，解压到 mpv 目录
3. 如需完整功能，再下载 `03-mpv-extras-vX.Y.Z.7z.00x` 解压

## 更新方式

- **仅更新配置**：下载最新 Config 包，解压覆盖即可
- **更新核心**：下载最新 Base 包
- **更新着色器/插件**：下载最新 Extras 包

日常小改动通常只需要更新 Config 包。

## 打包脚本

所有脚本都位于项目根目录，建议在 PowerShell 中从该目录运行。

### 一次构建四个公开包

```powershell
.\build-all-packages.ps1 -Version '1.2.0'
```

输出 01 Base、02 Config、03 Extras 分卷和 04 LSFG 公开扩展包。

### 同时构建个人私用全量包

```powershell
.\build-all-packages.ps1 -Version '1.2.0' -IncludePrivate
```

需要项目根目录已经存在个人从 Steam 安装中复制的：

```text
Lossless Scaling\Lossless.dll
```

### 分别构建

```powershell
.\build-release.ps1 -Version '1.2.0'
.\build-lsfg-public.ps1 -Version '1.2.0'
.\build-full-private.ps1 -Version '1.2.0'
```

- `build-release.ps1`：构建 01～03。
- `build-lsfg-public.ps1`：构建 04，不包含任何 Steam 文件。
- `build-full-private.ps1`：完整合并已生成的 01～04（包括 LSFG 研究源码和说明），
  再加入个人 `Lossless.dll`。
- 所有脚本可用 `-OutputDir '目录名'` 修改输出目录。

## 配置特性

### 音频
- WASAPI 输出，支持多声道
- 音速调整与音高校正

### 字幕
- 多语言、多格式字幕渲染
- AI 字幕生成（Faster-Whisper，需自行下载模型）
- 在线字幕下载（Assrt.net）

### 界面
- 基于 [uosc](https://github.com/tomasklaen/uosc) 的现代化 OSC
- 弹幕系统（[uosc_danmaku](https://github.com/Loukyuu1120/uosc_danmaku)）
- 汉化统计信息 OSD

### 视频处理
- 500+ GLSL 着色器（Anime4K、FSRCNNX、ESRGAN 等 35 类）
- VapourSynth 补帧/超分/降噪（RIFE、SVP、DRBA、ArtCNN）
- HDR/SDR 自适应切换

### 快捷键
- `h/j/k/l` — 基本播放控制
- `i` — 临时显示统计信息，`I` — 常驻显示
- `1`~`5`/`0` — 切换统计信息页面
- `Ctrl+数字` — 快速切换着色器
- `Alt+数字` — 切换预设配置组

## 自定义

配置文件在 `portable_config/` 下：

| 文件 | 用途 |
|------|------|
| `mpv.conf` | 主配置 |
| `input.conf` | 键位绑定 + uosc 右键菜单 |
| `profiles.conf` | 条件配置组（分辨率/HDR自适应） |
| `scripts/` | Lua 脚本 |
| `script-opts/` | 脚本配置 |
| `shaders/` | GLSL 着色器（Extras 包） |
| `vs/` | VapourSynth 脚本（Extras 包） |

## 项目来源

```
gaoxing64/MPV-lazy-full (v2.0.0)
    └── hooke007/MPV_lazy (原始 MPV-lazy)
    └── dyphire/mpv-config (配置参考)
    └── hooke007/mpv_PlayKit (着色器)
    └── LumeCraft-Labs/K7sfunc (VapourSynth 脚本)
```

## License

本项目各组件的许可证见各自源文件。原始项目按原作者 dyphire 的许可证约定执行。
