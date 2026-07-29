# Windows 原生接入研究

## 已确认

- Lossless Scaling 3.2.2 的 `Lossless.dll` 含 300 个 `RT_RCDATA` 资源。
- 资源 303–400 为 SPIR-V；lsfg-vk 2.0 所需的 304–400 号资源完整存在。
- 因此无需运行 `LosslessScaling.exe`，也无需把 `Lossless.dll` 当作代码载入进程；只需按 PE 资源文件读取。
- mpv 必须使用 `vo=gpu-next`、`gpu-api=vulkan`、`gpu-context=winvk`，Layer 才能截获交换链。

## Windows 改造点

- Vulkan Loader：`vulkan-1.dll` + `GetProcAddress`。
- 外部图像：`VK_KHR_external_memory_win32`、`OPAQUE_WIN32`、`HANDLE`。
- 同步：`VK_KHR_external_semaphore_win32` + 时间线信号量。
- Layer 发现：启动时设置 `VK_ADD_IMPLICIT_LAYER_PATH`，不写系统注册表。
- 进程识别与配置目录：使用 Win32 进程路径及 `LOCALAPPDATA`；便携启动默认直接使用环境配置。

## 已通过的运行验证

- 使用本仓库的 `mpv.exe`、AMD Radeon RX 6600 和 320×240/30 fps 合成视频测试。
- Vulkan Loader 成功插入 `VK_LAYER_LSFGVK_frame_generation`。
- LSFG 后端成功读取 `Lossless.dll` 并报告 `frame generation context ready (320x240, 2x)`。
- mpv 完成 30 帧播放并以退出码 0 结束。

## 当前边界

Layer 工作在 mpv 最终 Vulkan 交换链上，因此生成帧会包含字幕、OSD 和菜单。若要只处理视频画面、再由 mpv 叠加字幕与 OSD，才需要修改 mpv 源码或 libplacebo 渲染路径；本方案不做这项侵入式改造。

## 本地运行结构

```text
mpv 根目录/
├── mpv.exe
├── start-mpv-lsfg.ps1
├── Lossless Scaling/
│   └── Lossless.dll
└── lsfg-vk/
    ├── lsfg-vk-layer.dll
    ├── VkLayer_LSFGVK_frame_generation.json
    └── runtime-manifest/                 # 启动时自动生成
        └── VkLayer_LSFGVK_frame_generation.json
```

Windows Loader 对清单中的相对 DLL 路径处理不可靠，因此启动脚本会生成一个使用
绝对 DLL 路径的运行时清单。环境变量只作用于它创建的 mpv 子进程，不会注册系统级
Layer；脚本默认屏蔽 OBS 和 Steam 隐式层，也可用 `-KeepOtherVulkanLayers` 保留它们。

## mpv 菜单测试

`portable_config/scripts/lsfg_control.lua` 在“视频滤镜 → 补帧”提供 2×质量、
2×性能、3×质量和 4×质量入口。选择后会保存当前播放时间与播放列表，通过启动器
重启到 Vulkan Layer 模式；“关闭补帧”会按相同方式切回普通 mpv。

LSFG 启用期间，mpv 轻量插值和 VapourSynth 补帧菜单会被禁用，避免两套补帧同时
运行。切换进程是 Vulkan Layer 的生命周期要求，不是菜单脚本本身的限制。

## 实时帧率覆盖层

Layer 对成功完成的原始与生成 `QueuePresentKHR` 调用分别计数，每 0.5 秒将输入
Present FPS、输出 Present FPS、倍率和模式写入 `lsfg-vk/telemetry.json`。
`lsfg_control.lua` 每 0.25 秒读取一次，并通过独立 ASS OSD 覆盖层显示：

```text
LSFG 2× · 质量
原始 30.0 FPS
实时 60.0 FPS
```

覆盖层跟随 `Tab`（等同原大写 `I`）切换的常驻 stats OSD：stats 打开时显示在屏幕
右上角，关闭时同步隐藏，避免遮挡左侧统计内容。同步状态由自定义 `stats.lua` 通过
`user-data/stats/toggled` 发布，因此用 `Tab`、大写 `I` 或 stats 自身的 Esc 关闭都会
保持一致。这里统计的是 Layer 成功提交给 Vulkan 交换链的速率，比“源帧率 × 倍率”
估算更准确；它不等同于显示器面板最终扫描出的物理帧数，后台窗口也可能被 DWM 节流。

“视频滤镜”一级菜单还提供与着色器一致的“查看当前启用项”和“清空全部滤镜”。
后者会同时清空 `vf`、关闭 mpv 插值，并在必要时退出 LSFG 后按当前进度续播。
