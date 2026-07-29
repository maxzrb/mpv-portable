# STATUS.md — MPV 便携配置项目

## 当前状态快照

| 项目 | 状态 |
|------|------|
| **项目** | MPV 便携播放器个人配置（fork from gaoxing64/MPV-lazy-full v2.0.0） |
| **分支** | `master` |
| **最新发布提交** | `bf1be68`（tag: `v1.1.0`） |
| **工作区** | v1.1.0 已发布，本地与远程同步 |
| **MPV 核心版本** | v0.41.0-860-gc8c7d91a8 (2026-07-06, dyphire/mpv-winbuild) |
| **项目版本** | v1.1.0（已发布） |
| **上次操作** | 发布并核验 GitHub Release v1.1.0 |
| **自定义脚本** | portable_config/scripts/stats.lua (覆盖内置) |

## 环境

- **操作系统**: Windows 11 Pro for Workstations 10.0.26220
- **架构**: x86_64
- **Python**: 3.14 (便携，根目录)
- **MPV 构建源**: dyphire/mpv-winbuild

## 工作目录结构

```
c:\Program portable\mpv2\
├── mpv.exe, mpv.com          # MPV 核心 (gitignore)
├── portable_config/          # 配置文件 (git 跟踪)
│   └── scripts/stats.lua     # 汉化版统计信息脚本
├── vs-plugins/, vs-scripts/  # VapourSynth (gitignore)
├── Faster-Whisper-XXL/       # AI 字幕 (gitignore)
├── lua/, socket/, mime/      # Lua 运行时
├── installer/                # 安装/更新脚本
└── settings.xml              # 更新器配置 (未跟踪)
```

## TODO

- [x] `settings.xml` 已加入 `.gitignore`
- [ ] 根据个人需求定制 mpv.conf
- [ ] 后续可考虑升级 yt-dlp
- [x] 恢复“着色器 / 视频滤镜”一级分类，在完整技术分类前补充少量互斥推荐入口
- [x] 去掉 VapourSynth 菜单中间层，让补帧、超分、降噪按用途直达
- [x] 将完整着色器库按用途重组，同时保留按原算法家族查找的专家库
- [x] 允许补帧、超分、降噪同时启用，并提供竖排状态 OSD 与直属清空入口

---

## 会话日志

### 2026-07-27 会话 2: 汉化 stats.lua OSD 统计界面

- **操作**: 从 mpv 源码获取 stats.lua → 翻译所有 OSD 显示文为中文
- **文件变更**: 新增 `portable_config/scripts/stats.lua` (覆盖内置)
- **翻译范围**: 6 个信息页的标题、标签、状态文本全覆盖
  - 页1 默认信息: 文件、视频、音频、HDR、滤镜等 40+ 字段
  - 页2 扩展帧时间: 帧时间表格、总计
  - 页3 缓存统计: 队列、状态、速度、范围
  - 页4 活跃键位绑定: 搜索提示
  - 页5 轨道信息: 编解码器、回放增益、杜比视界、轨道标志
  - 页0 内部性能信息
- **保留原文**: HDR10+、PQ(Y) 等技术标准名称
- **验证**: `mpv --no-config --script=stats.lua` 加载无报错
- **状态**: 完成，期待用户实际播放视频时测试显示效果

### 2026-07-27 会话 3: 创建 GitHub 仓库 + 三包发布

- **仓库**: https://github.com/maxzrb/mpv-portable (公开)
- **Release**: v1.0.0 (https://github.com/maxzrb/mpv-portable/releases/tag/v1.0.0)
- **三包方案**:
  - `mpv-config-v1.0.0.7z` (32 MB) — 配置/脚本/OSC/字体
  - `mpv-base-v1.0.0.7z` (75 MB) — 核心播放器 + 运行时 + 配置
  - `mpv-extras-v1.0.0.7z.001/.002` (2.6 GB) — 着色器 + VS + AI + 工具 (分卷)
- **新增文件**: build-release.ps1 (打包脚本)
- **Git 提交**: 3 次提交推送到 origin/master
- **状态**: Release 已发布，GitHub Pages 需手动启用

### 2026-07-27 会话 1: MPV 核心升级

- **操作**: 从 dyphire/mpv-winbuild 下载并解压最新构建
- **版本变化**: v0.41.0-198-gb74121a3a (Feb 20) → v0.41.0-860-gc8c7d91a8 (Jul 6)
- **方法**: 手动下载 `mpv-x86_64-20260706-git-c8c7d91a8e.7z` + 7z 解压覆盖
- **文件变更**: mpv.exe, mpv.com, lua51.dll, luajit.exe, vulkan-1.dll, doc/, installer/, updater.bat, lua/, mime/, mpv/, socket/
- **git 可见变更**: 仅新增 settings.xml (未跟踪)
- **验证**: `mpv.com --version` 确认版本正确
- **状态**: 升级成功，工作区干净，二进制文件由 .gitignore 排除

### 2026-07-29 14:58 会话: 着色器与视频滤镜菜单分类审查

- **范围**: 只读检查 `input.conf`、`mpv.conf`、`profiles.conf`、`dyn_menu.lua`、387 个 GLSL 文件及 13 个 VapourSynth 菜单脚本。
- **硬件基线**: AMD Radeon RX 6600，1920×1080，165 Hz；当前使用 `vo=gpu-next`、`gpu-api=d3d11`。
- **主要发现**:
  - 着色器菜单共有 388 项，其中 387 项是素材库全部 GLSL 文件的直接展开，并非面向使用场景的精选菜单。
  - 121 个着色器支持运行时参数，但菜单只提供开关；317 个着色器带触发条件，未满足条件时点击可能无实际效果。
  - 所有着色器菜单项都没有动态勾选状态，无法直观看出已启用项目，且多个超分、降噪或锐化算法可以被叠加。
  - `[SD]` 条件配置会对 720p 及以下视频自动启用 `FSRCNNX+`，与手动选择其他放大着色器存在叠加风险。
  - VS 菜单混入 5 个明确的 NVIDIA 专用项目，不适用于当前 RX 6600。
  - 视频滤镜菜单将 VS、几何变换、帧率改写和色彩元数据修复混在一层；“强制 59.94 帧”不是运动补帧，`format` 色彩项主要用于修复错误标记。
- **建议方向**:
  - 改为“常用预设、片源修复、放大、色度、锐化、流畅度、画面变换、专家库”的用途分类。
  - 常用方案互斥设置并提供当前状态/一键清理，避免任意叠加。
  - 优先使用 mpv 内置缩放、去色带和轻量插值；VapourSynth 与完整 GLSL 库移入专家区。
- **文件变更**: 仅更新 HandShake 记录；播放器配置未修改。
- **Git 状态**: 本地 `master` 领先远程 1 个提交；进入本次研究前 `docs/codex/STATUS.md` 已有未提交记录。

### 2026-07-29 15:23 会话: 优化着色器与视频滤镜菜单

- **目标**: 将面向算法仓库的菜单改造成面向播放场景的日常菜单，同时保留完整专家入口。
- **菜单重组**:
  - 新增一级菜单“画质处理”，顺序为“查看当前处理 → 常用方案（互斥）→ 单项处理（替换当前方案）→ 片源修复 → 流畅度”。
  - `Ctrl+0～9` 从可叠加着色器开关改为互斥方案：关闭、通用高清、通用低清、动画柔和修复、动画高清、动画低清、色度增强、轻度降噪、SSim 低负载和 SGEDS 缩放锐化。
  - 常用方案根据 `glsl-shaders` 实际内容显示动态勾选状态。
  - 去色带、去交错、去色块归入“片源修复”；翻转、旋转和补黑边归入“画面变换”。
  - 容易误用的色彩元数据强制、帧率改写和默认 6500K 色温移动到“专家工具”。
- **流畅度优化**:
  - 日常入口保留 mpv 轻量插值、关闭动态平滑、MVT-LQ 与适配 RX 6600 的 RIFE-DML。
  - VapourSynth 使用 `@quality-vs` 标签切换，只替换自身，不再执行 `vf set` 清空其他滤镜。
  - NVIDIA 专用 VS 项目独立归档到“专家工具 > VapourSynth > NVIDIA 专用”。
- **冲突消除**:
  - 停用 `[SD]` 条件配置的自动触发，低清增强改为手动选择，避免换文件时覆盖用户方案或与其他超分叠加。
  - 完整 387 个 GLSL 文件全部保留在“专家工具 > 着色器库”，无缺失、无重复。
- **验证**:
  - `mpv --no-config --input-conf=portable_config/input.conf --idle=no`：输入配置解析成功。
  - `mpv --no-config --include=portable_config/profiles.conf --show-profile=SD`：手动 SD profile 展开正确。
  - IPC 运行时逐项验证 10 种画质方案：着色器内容和菜单勾选全部匹配。
  - IPC 验证 MVT-LQ：`quality-vs` 标签、VapourSynth 文件和流畅度勾选正确。
  - 动态 `menu-data` 验证日常菜单顺序正确；专家着色器覆盖 `387/387`。
  - `git diff --check` 通过，配置保持 UTF-8、LF。
- **文件变更**: `portable_config/input.conf`、`portable_config/profiles.conf`、`docs/codex/STATUS.md`、`version/工作进度.md`。
- **Git 状态**: `master` 领先远程 1 个提交；本次修改尚未提交。

### 2026-07-29 15:46 会话: 恢复清晰的技术分类

- **用户反馈**: “画质处理 / 专家工具”结构牺牲了原有分类，完整库入口过深，预设名称也不够直观。
- **菜单纠偏**:
  - 恢复“着色器”和“视频滤镜”两个一级菜单，移除“画质处理”和“专家工具”菜单路径。
  - 387 个 GLSL 入口直接回到“着色器”下的原技术分类，不再经过“专家工具 > 着色器库”。
  - “着色器 > 推荐”只保留关闭、真人 720p、真人低清、动画修复、动画 720p、动画 SD 六个场景化入口。
  - CfL、kBFDN、SSim 和 SGEDS 快捷项分别并回原本的 CfL、其他效果、SSim 和高通分类，避免新增重复分类。
  - 片源修复、流畅度、画面变换、错误标记修复、帧率改写、色彩调整、滤镜管理和 VapourSynth 全部直属“视频滤镜”。
- **保留的底层改进**:
  - 着色器快捷方案继续互斥替换并显示动态勾选。
  - VapourSynth 继续使用 `@quality-vs` 标签安全切换，不清空其他视频滤镜。
  - `[SD]` 自动触发继续停用，避免切换视频时覆盖手动方案。
- **验证**:
  - mpv 实际 `menu-data` 中“着色器 / 视频滤镜”均为一级菜单，旧的“画质处理 / 专家工具”入口为零。
  - 完整着色器库覆盖 `387/387`，零缺失、零过期路径、零重复。
  - `mpv --no-config --input-conf=portable_config/input.conf --idle=no` 解析成功。
- **Git 状态**: 本次纠偏仍未提交。

### 2026-07-29 15:58 会话: 提升补帧与超分入口

- **用户反馈**: 视频滤镜中的关键补帧和超分功能仍藏在“VapourSynth”深层菜单。
- **菜单调整**:
  - 去掉用户可见的“VapourSynth”中间层。
  - “补帧”“超分”“降噪”成为“视频滤镜”最前面的三个直属分类。
  - 补帧直接列出关闭、mpv 轻量插值、MVT-LQ、RIFE-DML、DRBA-DML、RIFE-STD、SVP Pro 和两个 NVIDIA 方案。
  - 超分直接列出 UAI-DML、UAI-MIGX、UAI-NV-TRT 和 ArtCNN。
  - AMD、Intel、NVIDIA 和负载要求直接写在方案名称中，不再要求用户先理解技术后端。
  - CCD 与 BM3D 移入直属“降噪”；管理菜单保留关闭当前 VS 处理的入口。
- **保留行为**:
  - 所有 VS 方案继续通过 `@quality-vs` 单一标签安全替换。
  - 每个补帧、超分和降噪方案都增加或保留动态勾选状态。
- **验证**:
  - mpv 实际菜单顺序为“补帧 → 超分 → 降噪 → 片源修复 → …”，VapourSynth 菜单路径为零。
  - RIFE-DML 与 UAI-DML 均能正确加载预期脚本，并在实际 `menu-data` 中显示勾选。
  - 输入配置解析成功，测试 mpv 进程正常退出。
- **Git 状态**: `master` 领先远程 1 个提交；整批菜单优化仍未提交。

### 2026-07-29 16:21 会话: 建立着色器用途与专家双索引

- **用户目标**: 日常按用途寻找着色器，同时避免 AMD、Anime4K 等同一技术家族因用途拆分后无法集中浏览。
- **分类依据**:
  - 读取本地 387 个 GLSL 菜单入口和文件元数据。
  - 对照 mpv_PlayKit 当前《用户着色器》Wiki 的各族用途说明，特别处理 AMD、Anime4K、ArtCNN、ESRGAN、NVIDIA、RAISR、SSim 和 ETC 等混合用途家族。
- **用途索引**:
  - 建立“超分与缩放、修复与去模糊、锐化与细节、降噪与平滑、抗锯齿与抗振铃、去色带、色度修复、色彩与观感、去交错、画面工具与特效”十个直属用途分类。
  - 每个用途继续按片源类型或处理方式、算法家族分层，避免单层塞入数百项。
  - `Ctrl+6～9` 快捷单项迁入对应用途路径，继续保留动态勾选。
- **专家索引**:
  - 新增“着色器 > 专家库”，完整复制原来的 35 个算法家族菜单路径。
  - 双索引仅重复菜单引用，不复制 GLSL 文件，不增加着色器磁盘占用。
- **典型分流**:
  - AMD 的 5 个 EASU/FSR 放大项进入“超分与缩放”，6 个 CAS/RCAS 项进入“锐化与细节”。
  - “专家库 > AMD”仍集中保留全部 11 项。
  - Anime4K 分流到超分、动画修复、降噪、动画线条和抗振铃。
- **验证**:
  - 用途索引覆盖 `387/387`，零缺失、零过期路径；另有 4 个快捷菜单项。
  - 专家索引覆盖 `387/387`，零缺失、零重复、零过期路径。
  - mpv 实际 `menu-data` 顺序、35 个专家家族、AMD 分流数量全部符合预期。
  - 双索引菜单实际读取约 7 ms；`Ctrl+8` 勾选和 `Ctrl+0` 清理正常。
  - 输入配置解析成功，测试 mpv 进程正常退出。
- **Git 状态**: `master` 领先远程 1 个提交；整批菜单优化仍未提交，建议现在提交。

### 2026-07-29 16:52 会话: 放宽滤镜叠加并改进状态查看

- **用户需求**:
  - VS 补帧、超分和降噪需要允许同时启用。
  - “查看当前启用项”必须标出并提供可记忆的快捷键。
  - 当前着色器和滤镜需要在 OSD 中逐项竖排并显示数量。
  - 着色器直属二级菜单需要一键清空全部着色器。
- **滤镜槽拆分**:
  - 将原共享 `@quality-vs` 拆为 `@quality-memc`、`@quality-upscale`、`@quality-denoise`。
  - 不同用途可以同时存在；同一用途切换时只替换自身。
  - mpv 轻量插值现在只移除 VS 补帧，保留当前 VS 超分与降噪。
  - 补帧、超分、降噪菜单分别提供关闭项；管理菜单保留一键关闭全部三类处理。
- **状态 OSD**:
  - 新增 `portable_config/scripts/quality_status.lua`。
  - 着色器和视频滤镜按“数量 + 编号 + 每行一项”显示。
  - VS 滤镜显示 `[补帧]`、`[超分]`、`[降噪]` 用途及脚本文件名，并单列 mpv 轻量插值状态。
  - 原拟使用 `Ctrl+Shift+0`，但 mpv 在 Windows 下不会把数字 Shift 组合注册为该按键；最终改为可用且无冲突的 `Ctrl+Alt+0`。
- **菜单入口**:
  - “着色器 > 查看当前启用项 · Ctrl+Alt+0”成为首项。
  - “着色器 > 清空全部着色器 · Ctrl+0”提升为直属第二项，不再藏在推荐子菜单。
- **验证**:
  - 实际同时加载 RIFE-DML、UAI-DML、CCD，三个独立标签和菜单勾选均正确。
  - 补帧从 RIFE-DML 切换到 MVT-LQ 后，超分与降噪保持不变。
  - 切换到 mpv 轻量插值后，仅 VS 补帧被移除，超分与降噪仍存在。
  - `Ctrl+Alt+0` 已进入 mpv 实际 `input-bindings`；`Ctrl+1` 加载及 `Ctrl+0` 清空着色器正常。
  - 用模拟的 2 个着色器与 4 个滤镜验证竖排 OSD 文本、数量和用途标签。
  - 测试 mpv 进程正常退出。
- **文件变更**: 新增 `portable_config/scripts/quality_status.lua`，修改 `portable_config/input.conf` 及 HandShake 记录。
- **Git 状态**: `master` 领先远程 1 个提交；整批菜单优化仍未提交，建议现在提交。

### 2026-07-29 17:46 会话: 菜单优化提交前复核

- **范围**: 对当天的着色器分类、视频滤镜槽拆分、状态 OSD 和低清 profile 调整做最终提交前复核。
- **远程状态**: 已执行 `git fetch origin`；远程 `origin/master` 没有新增提交，本地仍领先 1 个既有提交。
- **验证结果**:
  - `git diff --check` 通过。
  - 使用 `av://lavfi:testsrc` 实际启动 mpv，成功加载 `quality_status.lua`、`input.conf` 和 `profiles.conf`，退出码为 0。
  - 本地 387 个 GLSL 文件在用途索引和专家索引中均覆盖 `387/387`，引用总集无缺失、无过期路径。
  - 仓库附带的 `luajit.exe` 不支持 `-b` 命令，因此 Lua 验证改用 mpv 实际加载完成。
- **待执行**: 提交并推送本批修改；随后根据三包内容决定 Release 更新范围。
- **Git 状态**: `master` 领先远程 1 个提交；待提交文件为 `input.conf`、`profiles.conf`、`quality_status.lua` 及 HandShake 记录。

### 2026-07-29 17:56 会话: 提交菜单优化并准备 v1.1.0

- **提交与同步**:
  - 已提交 `175b4f4 feat: 按用途重组着色器与视频滤镜菜单`。
  - 已推送到 `origin/master`，本地与远程同步。
- **Release 范围判断**:
  - `v1.0.0..HEAD` 只涉及 README、菜单配置、profile、状态脚本和项目记录。
  - 着色器、VapourSynth、插件、模型、Python 环境及额外工具没有变化。
  - 决定发布 v1.1.0 的 config 与 base 两包，不重传 extras；v1.0.0 extras 保持兼容。
- **打包机制**:
  - 为 `build-release.ps1` 新增 `-SkipExtras` 开关。
  - 使用 `.\build-release.ps1 -Version '1.1.0' -SkipExtras` 构建。
- **产物**:
  - `mpv-config-v1.1.0.7z`：33,817,819 字节；SHA-256 `E44E99294C82C6979163952D6F047EB987C126F05EAD347A1EED767C89ED7C6B`。
  - `mpv-base-v1.1.0.7z`：78,173,383 字节；SHA-256 `5D34E29B84AFCE34D29E43FFF314C0494F71C11373E116785C4262524B4CC5A6`。
- **验证**:
  - 两个 7z 包完整性测试通过。
  - 两包均包含 `quality_status.lua`，且均未误包含 shaders 或 VS 素材。
  - 解压基础包后实际启动 mpv，成功加载新脚本、`input.conf` 和 `profiles.conf`。
  - 解包验证产生的忽略目录 `build/validate-v1.1.0` 仍在本地；自动递归清理被执行环境策略拦截，不影响 Git 或发布包。
- **待执行**: 提交版本与打包机制，创建并上传 GitHub Release v1.1.0。

### 2026-07-29 18:02 会话: 发布 GitHub Release v1.1.0

- **发布提交**: `bf1be68 release: 准备 v1.1.0 配置与基础包`。
- **标签**: 已创建并推送带注释标签 `v1.1.0`，远程标签解引用到 `bf1be68`。
- **Release**: https://github.com/maxzrb/mpv-portable/releases/tag/v1.1.0
- **上传资产**:
  - `mpv-config-v1.1.0.7z`：33,817,819 字节，GitHub digest 与本地 SHA-256 一致。
  - `mpv-base-v1.1.0.7z`：78,173,383 字节，GitHub digest 与本地 SHA-256 一致。
- **发布状态**: 正式发布，非草稿、非预发布；Release 说明明确复用 v1.0.0 extras。
- **未上传**: extras 分卷未变化，因此没有重新构建或上传。
- **本地临时文件**:
  - `release/` 内保留两个已上传包，由 `.gitignore` 排除。
  - `build/validate-v1.1.0` 是解包启动验证副本，由 `.gitignore` 排除；执行环境阻止递归删除，可由用户稍后手动删除。
- **Git 状态**: 发布代码和标签均已同步；本条 HandShake 收尾记录提交后应保持工作树干净。
