# MPV Portable

> 个人定制版 MPV 便携播放器，三包发布，按需组装。
>
> Fork from [gaoxing64/MPV-lazy-full](https://github.com/gaoxing64/MPV-lazy-full) v2.0.0

## 三个包的关系

```
┌─────────────────────────────────────────────────┐
│                   mpv-extras                     │
│   ┌─────────────────────────────────────────┐   │
│   │              mpv-base                    │   │
│   │   ┌─────────────────────────────────┐   │   │
│   │   │         mpv-config              │   │   │
│   │   │   scripts / settings / fonts    │   │   │
│   │   └─────────────────────────────────┘   │   │
│   │   mpv.exe + DLLs + Lua runtime          │   │
│   └─────────────────────────────────────────┘   │
│   shaders + VapourSynth + AI + Python + tools    │
└─────────────────────────────────────────────────┘
```

| 包 | 解压即用? | 内容 |
|----|----------|------|
| **Config** | ✗ (需要 mpv 本体) | 脚本、设置、OSC 主题、字体 |
| **Base** | ✅ 基本播放 | Config + mpv 核心 + 运行时 |
| **Extras** | ✗ (需要 Base) | 着色器、VapourSynth 补帧/超分、AI 字幕、工具 |
| **Base + Extras** | ✅ 完整体验 | 所有功能 |

## 下载与安装

### 方案一：完整安装（推荐）

从 [Releases](https://github.com/maxzrb/mpv-portable/releases) 下载：

1. 下载 `mpv-base-vX.Y.Z.7z`
2. 下载 `mpv-extras-vX.Y.Z.7z.001` 和 `.002`（两个分卷都需要）
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

1. 下载 `mpv-config-vX.Y.Z.7z`
2. 解压到 mpv 的配置目录（覆盖 `portable_config/`）

### 方案三：手动组装

1. 下载任意标准 mpv Windows 构建
2. 下载 `mpv-config-vX.Y.Z.7z`，解压到 mpv 目录
3. 如需完整功能，再下载 `mpv-extras-vX.Y.Z.7z.00x` 解压

## 更新方式

- **仅更新配置**：下载最新 Config 包，解压覆盖即可
- **更新核心**：下载最新 Base 包
- **更新着色器/插件**：下载最新 Extras 包

日常小改动通常只需要更新 Config 包。

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
