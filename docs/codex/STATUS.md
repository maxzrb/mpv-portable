# STATUS.md — MPV 便携配置项目

## 当前状态快照

| 项目 | 状态 |
|------|------|
| **项目** | MPV 便携播放器个人配置（fork from gaoxing64/MPV-lazy-full v2.0.0） |
| **分支** | `master`（已与 `origin/master` 同步） |
| **最新发布提交** | `f4fa2f6`（tag: `v1.3.1`） |
| **工作区** | v1.3.1 已发布；工作树干净 |
| **MPV 核心版本** | v0.41.0-860-gc8c7d91a8 (2026-07-06, dyphire/mpv-winbuild) |
| **项目版本** | v1.3.1（已发布） |
| **上次操作** | 发布 v1.3.1：五包重构、LSFG env var 遥测修正、依赖升级 |
| **自定义脚本** | `stats.lua`、`quality_status.lua`、`lsfg_control.lua` |

## 环境

- **操作系统**: Windows 11 Pro for Workstations 10.0.26220
- **架构**: x86_64
- **Python**: 3.14.6（便携，根目录）
- **MPV 构建源**: dyphire/mpv-winbuild

## 工作目录结构

```
c:\Program portable\mpv2\
├── mpv.exe, mpv.com          # MPV 核心 (gitignore)
├── yt-dlp.exe                # 在线视频解析器 (gitignore，Base 包会复制)
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
- [x] 安装官方 yt-dlp 2026.07.04，并纳入公开 Base 包
- [x] 升级 Python 3.14.3 → 3.14.6，并验证 SSL、SQLite、pip 与现有 VapourSynth R73
- [x] 为 VapourSynth R78 设计无需全局环境变量、兼容直接双击 `mpv.exe` 的便携加载方案（已放弃：R73 为明确支持 Win7 的最后版本，暂不升级，R78 试验文件已清理）
- [x] 更新 7-Zip 25.01 → 26.02、TorrServer MatriX.141 → 142.2、umpv-go 1.4.0 → 1.5.1
- [x] 安全合并更新器报告的 15 个脚本、文档和着色器差异，保留本地个性化文件
- [x] 修复 manager 的 PlayKit 分支、quality-menu 白名单、同名脚本覆盖和 Git blob 误报
- [x] 安装 Faster-Whisper-XXL 公开版 r245.4，从 Extras 拆分为独立 04 增量包
- [x] 恢复“着色器 / 视频滤镜”一级分类，在完整技术分类前补充少量互斥推荐入口
- [x] 去掉 VapourSynth 菜单中间层，让补帧、超分、降噪按用途直达
- [x] 将完整着色器库按用途重组，同时保留按原算法家族查找的专家库
- [x] 允许补帧、超分、降噪同时启用，并提供竖排状态 OSD 与直属清空入口
- [x] 将 LSFG 2×/3×/4×测试入口接入补帧菜单，并支持按当前进度重启切换
- [x] 将四个 LSFG 预设收进独立子菜单，使其与其他补帧滤镜处于同一层级
- [x] 将左上角静态置顶标记改为可点击且带状态高亮的 uosc 顶栏按钮
- [x] 为 LSFG 增加 Layer 实时帧率遥测与可切换 OSD 覆盖层
- [x] 为视频滤镜补齐直属状态查看和完整清空入口
- [x] 让 LSFG 遥测跟随 Tab 常驻 stats OSD，并移至屏幕右上角
- [x] 将五类安装包按 01 Base → 02 Config → 03 Extras → 04 FW → 05 LSFG 编号并写明覆盖顺序
- [x] 将第 04 包改为零 Steam 文件的公开扩展包，仅要求用户自备 `Lossless.dll`
- [x] 统一生成 v1.2.0 四类公开包和个人私用全量包，并完成内容、交叉和完整性审计

---

## 会话日志

### 2026-07-30 会话: 统一 v1.2.0 打包与归档审计

- 四类公开包统一命名为 `01-mpv-base-v1.2.0.7z`、`02-mpv-config-v1.2.0.7z`、`03-mpv-extras-v1.2.0.7z.001/.002`、`04-mpv-lsfg-addon-v1.2.0.7z`。
- 新增 `mpv-full-private-v1.2.0.7z`，按 01 → 02 → 03 → 04 顺序合并，并只额外加入个人自备的 `Lossless.dll`。
- 打包门禁会排除缓存、日志、临时文件和调试产物；Extras 清除了 121 个 `__pycache__` 目录、1321 个生成文件，约 21.9 MiB。
- 未发现旧 Release、`build`、`tmp`、`.git` 或其他归档被意外套入新包。
- Config 与 Base 的 257 个相同文件属于更新包设计；LSFG 和 Extras 与 Base/Config 均无路径重叠。
- 六个实际归档文件均通过 `7z t`；个人全量包与四个公开包的合并结果一致，仅按设计移除公开源码/占位说明并加入 `Lossless.dll` 和私用说明。
- 旧 v1.1.1 输出已可恢复地移至 `tmp/release-backup-before-v1.2.0/`，没有删除。
- 新增统一入口 `build-all-packages.ps1` 和个人包脚本 `build-full-private.ps1`；当前尚未提交、推送或上传 Release。

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

### 2026-07-29 18:48 会话: 精简 SVP 菜单并准备 v1.1.1

- **用户需求**: 将“SVP Pro · 需安装 SVP”缩短为“SVP”，提交并更新 Release。
- **本地核验**:
  - 当前系统未安装 SVP 软件，但项目自带 `svpflow1_vs.dll` 与 `svpflow2_vs.dll`。
  - `MEMC_SVP_PRO.vpy` 通过 `k7sfunc.SVP_PRO()` 调用随包 SVPFlow 插件，不依赖 SVP Manager。
  - 使用测试视频实际加载 SVP 滤镜成功。
- **菜单修改**: `portable_config/input.conf` 中补帧菜单名称已改为“SVP”，滤镜命令和动态勾选逻辑保持不变。
- **验证**:
  - `input.conf` 由 mpv 实际解析成功。
  - SVP 滤镜独立处理 12 帧测试视频成功。
  - `git diff --check` 通过。
- **发布范围**: 仅菜单配置变化，构建 v1.1.1 的 config 与 base 两包；extras 继续复用 v1.0.0。
- **发布包**:
  - `mpv-config-v1.1.1.7z`：33,817,671 字节；SHA-256 `BA6270CD61493C3E8BC6EFDBDDCF33144586A4382C8E90473BBE3D76E54F2C60`。
  - `mpv-base-v1.1.1.7z`：78,173,427 字节；SHA-256 `979884132A5BA9A19EA9E8BEB076171007A1DE74D849B01F170AE265EDA526D9`。
- **包体核验**: 两包 7z 完整性测试通过，均包含新菜单文案且不含旧文案；没有误包含 shaders 或 VS 素材。
- **待执行**: 提交、推送、创建 v1.1.1 标签与 GitHub Release，并上传两包。

### 2026-07-29 18:51 会话: 发布 GitHub Release v1.1.1

- **发布提交**: `9735802 release: 发布 v1.1.1 菜单修正`，已推送到 `origin/master`。
- **标签**: 已创建并推送带注释标签 `v1.1.1`，远程标签解引用到 `9735802`。
- **Release**: https://github.com/maxzrb/mpv-portable/releases/tag/v1.1.1
- **发布状态**: 正式发布，非草稿、非预发布。
- **远程资产核验**:
  - `mpv-config-v1.1.1.7z`：33,817,671 字节，GitHub SHA-256 与本地一致。
  - `mpv-base-v1.1.1.7z`：78,173,427 字节，GitHub SHA-256 与本地一致。
- **extras**: 着色器、VapourSynth、模型和工具未变化，因此继续复用 v1.0.0 extras。
- **Git 状态**: 发布提交、分支和标签均已同步；本条 HandShake 收尾记录提交后应保持工作树干净。

### 2026-07-29 23:22 会话: Windows 原生 LSFG 接入研究

- **研究分支**: 已从当前版本建立本地 `research/lsfg-windows`，没有推送公开仓库。
- **素材核验**:
  - 用户提供的 Lossless Scaling 3.2.2 目录共 440 个文件、183,809,856 字节。
  - `Lossless.dll` 含 300 个 `RT_RCDATA` 资源；lsfg-vk 需要的 304–400 号 SPIR-V 模型资源全部存在。
  - 运行方案仅将 `Lossless.dll` 当作 PE 资源容器读取，不加载或执行其中的专有代码。
- **Windows 移植**:
  - 导入 `PancakeTAS/lsfg-vk` develop 提交 `8b0da2661c6f3473a7fccc8ba643880050e71642`。
  - 将 Linux 文件描述符共享路径改造为 Win32 `HANDLE`、`OPAQUE_WIN32`、外部内存与外部时间线信号量。
  - 增加 Windows Vulkan Loader、进程识别、便携路径、符号导出和 MinGW 构建支持。
  - 下载的 w64devkit 2.9.0、CMake 4.4.1、Ninja 1.13.2 均通过发布方 SHA-256 校验。
- **运行验证**:
  - 生成的 `lsfg-vk-layer.dll` 只依赖 Windows 系统 DLL，并正确导出 `vkNegotiateLoaderLayerInterfaceVersion`。
  - 启动器按绝对 DLL 路径动态生成 Vulkan 清单，不写注册表；默认隔离 OBS/Steam 隐式层。
  - mpv 使用 Vulkan/WinVK 播放 30 帧合成视频，Layer 报告 `frame generation context ready (320x240, 2x)`，进程退出码为 0。
  - 因为 Layer 位于最终交换链，生成帧会包含字幕、OSD 和菜单；本方案不需要重新构建 mpv。
- **私有研究包**:
  - `release/mpv-lsfg-research-private.7z`，51,938,897 字节。
  - SHA-256：`7C73A5EA24A9952ED44C77598634B7757435144D4C6B5444800F1C82C6E85B5E`。
  - 包含完整 Lossless Scaling 目录、运行 Layer、启动器和对应 GPL 研究源码；7z 完整性检查通过。
- **隔离措施**: `.gitignore` 已排除根目录 `Lossless Scaling/` 和 `lsfg-vk/`，不会误纳入公开提交。
- **Git 状态**: 本次研究改动尚未提交、未推送，也没有创建或更新公开 Release。

### 2026-07-30 00:02 会话: 将 LSFG 接入 mpv 补帧菜单

- **菜单入口**:
  - 在“视频滤镜 → 补帧”直属加入 LSFG 2×质量、2×性能、3×质量、4×质量和状态查看。
  - LSFG 启用时，对 mpv 轻量插值及所有 VapourSynth 补帧项返回 `disabled` 状态，避免双重补帧。
  - 原“关闭补帧”现在同时识别 LSFG；处于 LSFG 模式时会重启回普通 mpv。
- **续播控制**:
  - 新增 `portable_config/scripts/lsfg_control.lua`，保存当前时间、暂停状态和播放列表后启动新进程。
  - 切换到 LSFG 前移除 `@quality-memc` 并关闭 mpv 插值，防止与 RIFE/SVP 叠加。
  - 启动参数通过忽略目录中的临时 JSON 文件传递，规避 Windows PowerShell 原生数组参数只能绑定首项的问题。
  - `start-mpv-lsfg.ps1` 新增 `-Disable` 和 `-MpvArgumentsFile`，并兼容 Windows PowerShell 5.1 对无 BOM UTF-8 脚本的解析。
- **状态显示**:
  - `quality_status.lua` 增加 LSFG 启用状态、倍率及质量/性能模式。
  - `lsfg_control.lua` 将当前模式写入 `user-data/lsfg/*`，供动态菜单实时勾选。
- **验证结果**:
  - 普通模式菜单显示完整 LSFG 入口；LSFG 2×质量模式正确勾选，mpv 插值和 RIFE 菜单正确禁用。
  - 启动器烟雾测试再次报告 `frame generation context ready (320x240, 2x)`，退出码为 0。
  - 普通 mpv → LSFG：菜单消息成功，旧进程退出，新进程同时带 `--gpu-api=vulkan` 和 `--start` 续播参数。
  - LSFG → 普通 mpv：旧进程退出，新进程带 `--start` 且不再包含 Vulkan 强制参数。
  - 所有测试创建的 mpv 进程均已清理。
- **私有包更新**:
  - 包内新增 `portable_config/input.conf`、`lsfg_control.lua` 和新版 `quality_status.lua`。
  - `release/mpv-lsfg-research-private.7z`：51,957,616 字节。
  - SHA-256：`69E91F8501A5E1891D8F0E96D6981B6FD694E1BAE20D4151CC0096A800AC97B1`；7z 完整性检查通过。
- **Git 状态**: 本地 `research/lsfg-windows` 研究改动尚未提交、未推送，没有更新公开 Release。

### 2026-07-30 00:25 会话: LSFG 实时帧率覆盖层与滤镜管理

- **视频滤镜直属入口**:
  - “视频滤镜”一级菜单前两项现在与着色器一致，分别为“查看当前启用项 · Ctrl+Alt+0”和“清空全部滤镜 · Ctrl+`”。
  - 普通模式下，清空会执行完整 `vf clr` 并关闭 mpv 插值。
  - LSFG 模式下，清空会退出 Layer，携带 `--vf-clr`、`--interpolation=no` 和当前 `--start` 位置重启普通 mpv。
- **Layer 实时遥测**:
  - 在 `Swapchain::present` 成功完成全部生成帧与原始帧的 `QueuePresentKHR` 后分别计数。
  - 每 0.5 秒写入 `lsfg-vk/telemetry.json`：输入 Present FPS、输出 Present FPS、倍率、性能模式和更新时间。
  - `start-mpv-lsfg.ps1` 管理 `LSFGVK_TELEMETRY_PATH`，启动或关闭时清理旧遥测，避免显示过期数据。
- **OSD 覆盖层**:
  - `lsfg_control.lua` 每 0.25 秒读取 Layer 遥测，通过独立 ASS OSD 在左上角显示倍率、模式、原始 FPS 和实时 FPS。
  - LSFG 启用时默认显示，可在“视频滤镜 → 补帧 → LSFG 帧率覆盖层”开关。
  - 当前画质状态 OSD 也会显示“原始 FPS → 实时 FPS”。
  - 采用 mpv ASS OSD 而非在 Vulkan Layer 内额外实现字体渲染，避免修改交换链图像管线；帧率数据仍来自 Layer 的真实提交计数。
- **验证结果**:
  - 30 fps 合成视频前台烟雾测试得到 `30.01 → 60.01 FPS`，倍率准确为 2×。
  - Lua 实际读取遥测成功，`user-data/lsfg/input-fps`、`output-fps` 与覆盖层勾选状态均有效。
  - 已用窗口截图确认覆盖层实际渲染；后台隐藏窗口被 DWM 节流时仍会如实显示较低 Present 速率。
  - 普通模式测试：滤镜数量从 1 变为 0，`interpolation=false`。
  - LSFG 模式测试：旧进程退出，新普通进程不含 Vulkan 强制参数，并含 `--vf-clr`、`--interpolation=no`。
  - Windows Layer 重新编译成功；DLL SHA-256 为 `26D14A5D9953DCCB62B8D21683CC4C46511ACA5669F84BD99F16BF23FE51E9A0`。
- **统计边界**: “实时 FPS”代表 Layer 成功提交到 Vulkan 交换链的 Present 速率，不保证等同于显示器面板最终扫描率；最小化或后台窗口可能受 DWM 节流。
- **私有包更新**:
  - `release/mpv-lsfg-research-private.7z`：52,035,917 字节。
  - SHA-256：`3B4A08F24F47885960A259ED71779FBA98DAE1272231FA026ACDAD840E568F8C`；7z 完整性检查通过。
- **Git 状态**: 本地 `research/lsfg-windows` 研究改动尚未提交、未推送，没有更新公开 Release。

### 2026-07-30 00:39 会话: 遥测跟随 Tab 常驻 stats OSD

- **有效按键确认**:
  - `input.conf` 中低优先级的 Tab 是文件浏览器入口，但被 `inputevent.lua` 的增强按键覆盖。
  - 实际生效的是 `inputevent_key.conf`：Tab 单击调用 `stats/display-stats-toggle`，等同原大写 `I` 的常驻统计功能。
  - 曾为排查临时改动的文件浏览器 Tab 行已恢复，没有改变用户原有按键语义。
- **同步实现**:
  - 自定义 `stats.lua` 在常驻统计开启/关闭后写入 `user-data/stats/toggled`。
  - `lsfg_control.lua` 观察该属性：stats 关闭时遥测隐藏，Tab 或大写 `I` 开启时显示。
  - stats 自身通过 Tab、I 或 Esc 关闭时，状态都会同步更新，不依赖盲目翻转计数。
- **布局**: ASS 覆盖层从左上角改到右上角（右对齐、距边 24 px），避免遮挡左侧 stats OSD。
- **验证**:
  - 初始状态：stats=false、LSFG overlay=false。
  - 第一次真实 `keypress TAB`：stats=true、overlay=true。
  - 第二次真实 `keypress TAB`：stats=false、overlay=false。
  - 窗口截图确认左侧 stats 与右侧 LSFG `30.1 → 60.1 FPS` 同屏且不重叠。
  - 所有自动化测试 mpv 进程均已清理。
- **私有包更新**:
  - 打包脚本新增自定义 `portable_config/scripts/stats.lua`，确保状态同步代码随包交付。
  - `release/mpv-lsfg-research-private.7z`：52,051,306 字节。
  - SHA-256：`8C9BA7CA18B1BA40FBEF89BF0B0AC44490EFD752C9220DAF8BE81CB8EF512C3E`；7z 完整性检查通过。
- **Git 状态**: 本地 `research/lsfg-windows` 改动尚未提交、未推送，没有更新公开 Release。

### 2026-07-30 00:56 会话: 安装包覆盖顺序编号

- **编号规则**:
  - `01-mpv-base-vX.Y.Z.7z`
  - `02-mpv-config-vX.Y.Z.7z`
  - `03-mpv-extras-vX.Y.Z.7z.001/.002`
  - `04-mpv-lsfg-research-private.7z`
- **覆盖约定**:
  - 四类包全部安装时按 01 → 02 → 03 → 04 解压覆盖。
  - 同版本 Base 已包含 Config，因此 02 可跳过；如果安装，则仍按编号执行。
  - LSFG 私有包必须最后覆盖；以后更新 Base 或 Config 后需要再次应用 04。
- **脚本调整**:
  - `build-release.ps1` 的实际生成顺序改为 Base → Config → Extras，并为三个公开包加编号。
  - `build-lsfg-research.ps1` 将私有包更名为 `04-mpv-lsfg-research-private.7z`。
  - 根 `README.MD`、Extras 包内说明和私有包内说明均写入完整安装顺序。
- **验证**:
  - 两个 PowerShell 打包脚本通过解析器语法检查。
  - 临时实际生成 01 Base、02 Config 和 04 私有包，三个归档完整性测试通过。
  - 从三个归档中实际解出 README，均确认包含 01～04 顺序；03 Extras 因约 2.6 GB 未重新压缩，已静态核对其名称与生成说明。
  - `git diff --check` 通过，仅显示仓库现有的 autocrlf 提示。
- **临时文件**:
  - 执行策略阻止自动递归清理，测试归档仍位于 `tmp/package-order-validation/`。
  - 解出的 README 校验文件仍位于 `tmp/package-order-readme-check/`；两目录均为可删除的临时产物并已被 Git 忽略。
- **Git 状态**: 改动尚未提交、未推送，没有重新生成正式 Release 或更新公开 GitHub Release。

### 2026-07-30 01:05 会话: 验收并合并 LSFG 研究分支

- **用户决策**: LSFG Windows 研究功能和四类包编号验收通过，允许合并到主分支。
- **主分支确认**:
  - 仓库不存在 `main`；远端默认主分支为 `master`。
  - 合并前执行 `git fetch origin --prune`，确认本地 `master` 与 `origin/master` 同为 `45c2716`。
- **提交与合并**:
  - 研究提交：`a9732f6 feat: 集成 LSFG Vulkan Layer 研究功能`。
  - 合并提交：`ce60088 merge: 合并 LSFG Windows 研究功能`。
  - 合并无冲突，保留 `research/lsfg-windows` 分支作为功能基线。
- **提交范围审计**:
  - 共纳入 193 个文件，包括 mpv 菜单/控制脚本、Windows Layer GPL 源码、构建脚本、正确的 `lsfg-vk-layer.dll` 及研究文档。
  - `Lossless Scaling/`、根目录运行时 `lsfg-vk/`、`release/` 和 `tmp/` 继续由 `.gitignore` 排除。
  - 用户提供的 `Lossless.dll`、私有包和测试归档均未进入 Git。
  - 忽略早期 MinGW 生成且未被使用的 `liblsfg-vk-layer.dll` 副本。
- **合并前验证**:
  - Windows Layer 使用既有 w64devkit/CMake/Ninja 工具链重新配置并增量构建成功，安装产物保持最新。
  - `build-release.ps1`、`build-lsfg-research.ps1`、`start-mpv-lsfg.ps1` 和 `build-windows.ps1` 均通过 PowerShell 解析器检查。
  - `stats.lua`、`quality_status.lua` 和 `lsfg_control.lua` 通过 mpv `--no-config` 加载测试。
  - 修复上游 `Configuration.md` 两处尾随空格后，`git diff --cached --check` 通过。
- **未执行事项**:
  - 没有推送 `master` 或研究分支。
  - 没有创建新版本、Tag 或更新公开 GitHub Release。
  - 正式编号包尚未重新生成；此前的临时验证目录仍在 `tmp/` 且被 Git 忽略。
- **Git 状态**: 本收尾记录提交后，本地 `master` 预计领先 `origin/master` 3 个提交，工作树应保持干净。

### 2026-07-30 01:15 会话: 用公开 LSFG 扩展包取代私有包

- **Steam DLL 审计**:
  - 本机 Lossless Scaling 目录共有 433 个 DLL；旧私有归档共有 438 个 DLL 条目，额外 5 个是 Layer 运行/研究构建副本。
  - 其中 38 个为 Lossless Scaling 自有文件：`Lossless.dll`、`LosslessScaling.dll` 及 36 个语言目录中的 `LosslessScaling.resources.dll`。
  - 其余 395 个主要是 .NET、WPF、WinRT 等随 Steam 应用携带的第三方运行库；即使其中部分可能有独立再分发条款，本项目也不需要它们，因此统一排除。
  - mpv LSFG 实际只读取 `Lossless.dll` 的 `RT_RCDATA` 模型资源；用户只需从正版 Steam 安装自行复制这一文件。
- **公开包设计**:
  - 删除 `build-lsfg-research.ps1`，新增 `build-lsfg-public.ps1`。
  - 第 04 包更名为 `04-mpv-lsfg-addon.7z`，可公开分发。
  - 包内只含一个 DLL：本项目构建的 GPL `lsfg-vk-layer.dll`。
  - 包内不含 Steam DLL、EXE、模型资源或完整 Lossless Scaling 目录；只提供一个文本占位说明。
  - 随 Layer 二进制附带 `research/lsfg-vk-win` 对应 GPL 源码，但剔除本机 build 目录和重复 DLL。
  - 打包脚本设有强制门禁：额外 DLL、任意 EXE 或占位目录中的其他文件都会使构建失败。
- **文档调整**:
  - 根 `README.MD` 与 Extras 包内说明均将 04 改为公开扩展包。
  - 明确安装者只需将 Steam 安装根目录的 `Lossless.dll` 放到 `<mpv根目录>\Lossless Scaling\Lossless.dll`。
  - 明确不需要 `LosslessScaling.dll`、语言资源 DLL、.NET/WPF DLL 或任何 EXE。
- **生成结果**:
  - `release/04-mpv-lsfg-addon.7z`：2,002,853 字节。
  - SHA-256：`641DB5E204F701BE6C4BBF117321DB59080A8E22C8D6DADEAB7A4821CD88A9E9`。
  - 7-Zip 完整性检查通过；归档共 190 个文件，只含 1 个 DLL、0 个 EXE、0 个 Steam 二进制、0 个研究 build 路径。
- **旧包处理**:
  - 旧 `release/mpv-lsfg-research-private.7z` 已移出 Release 目录。
  - 为保持可恢复性，旧包暂存于被 Git 忽略的 `tmp/private-archive-backup/mpv-lsfg-research-private.7z`。
- **Git 状态**: 当前位于本地 `master`，原合并链领先 `origin/master` 3 个提交；本次公开包脚本与 README 调整尚未提交、未推送，也未上传 GitHub Release。

### 2026-07-30 02:21 会话: 发布 v1.2.0

- **提交与同步**:
  - 打包体系、公开 LSFG 扩展包和远端 README 更新提交为 `fce95b3 release: 准备 v1.2.0 LSFG 扩展包`。
  - 本地 `master` 已推送到 `origin/master`；`v1.2.0` Tag 与远端主分支均指向 `fce95b3a60e2980b4be275810ef5f113777f4599`。
- **Release**:
  - 正式 Release：https://github.com/maxzrb/mpv-portable/releases/tag/v1.2.0
  - Release 状态为正式发布，非草稿、非预发布。
  - 已上传 01 Base、02 Config、03 Extras 两个分卷和 04 LSFG 共五个公开资产。
  - GitHub 返回的五个资产大小与 SHA-256 均和本地文件一致。
- **公开边界**:
  - 04 包通过内容门禁，不含 `portable_config`、Steam DLL、EXE 或专有模型。
  - `mpv-full-private-v1.2.0.7z` 含用户自备 `Lossless.dll`，只保留本地，没有上传 Release。
  - 远端 README 已确认包含新版 01～04 安装顺序、04 不覆盖 Config/Extras，以及个人包禁止公开上传的说明。
- **验证**:
  - 01、02、03 `.001/.002` 分卷、04 和个人全量包均通过正确的 7-Zip 完整性测试。
  - PowerShell 打包/启动脚本通过解析器检查，`git diff --check` 通过。
- **Git 状态**: 发布收尾记录提交并推送后，本地 `master` 应与 `origin/master` 一致且工作树干净。

### 2026-07-30 11:18 会话: 调整 LSFG 补帧菜单层级

- **菜单调整**:
  - 将四个 LSFG 预设由 `视频滤镜 > 补帧` 直属项移入 `视频滤镜 > 补帧 > LSFG` 子菜单。
  - 将“查看 LSFG 状态”同步移入该子菜单。
  - “关闭补帧”以及 mpv、MVT、RIFE、DRBA、SVP 等其他补帧入口保持原层级。
- **验证**:
  - uosc 菜单解析器文档和实现确认支持不限层级的 `>` 嵌套路径。
  - `git diff --check` 通过。
- **文件变更**: `portable_config/input.conf`、`docs/codex/STATUS.md`、`version/工作进度.md`。
- **Git 状态**: 本次改动尚未提交或推送。

### 2026-07-30 11:45 会话: 修复左上角置顶图标行为

- **问题原因**:
  - `mpv.conf` 把 `📌` 作为 `title` 模板中的静态状态文字显示，并没有为它注册点击区域。
  - 点击该文字时事件落入全局 `MBTN_LEFT cycle pause`，因此表现为暂停。
- **实现**:
  - 从窗口标题模板移除静态 `📌`。
  - 在 uosc `TopBar` 左上角新增独立的 `push_pin` 按钮和点击区域。
  - 单击按钮执行 `cycle ontop` 并显示当前置顶状态；置顶时按钮保持高亮。
  - uosc 主状态新增 `ontop` 属性监听，保证外部快捷键 `Alt+T` 改变置顶状态时按钮同步刷新。
  - 右侧最小化、最大化和关闭按钮保持不变。
- **验证**:
  - `main.lua` 与 `TopBar.lua` 均通过 LuaJIT 语法检查。
  - 使用完整 `portable_config` 和短时 `lavfi` 视频完成脚本加载冒烟测试，mpv 正常退出。
  - `git diff --check` 通过。
- **文件变更**: `portable_config/mpv.conf`、`portable_config/scripts/uosc/main.lua`、`portable_config/scripts/uosc/elements/TopBar.lua`，以及本次 HandShake 记录。
- **Git 状态**: 本次改动与前一项 LSFG 菜单调整均尚未提交或推送。

### 2026-07-30 12:51 会话: 安装 yt-dlp 并接入公开 Base 包

- 从 yt-dlp 官方 GitHub 最新稳定 Release 下载 Windows 单文件程序 `yt-dlp.exe`，版本为 `2026.07.04`。
- 安装位置为 mpv 根目录，与 `mpv.exe` 同级；没有写入系统 PATH，也没有加入任何机器或显卡专属配置。
- 使用官方 `SHA2-256SUMS` 完成 SHA-256 校验，结果为 `52FE3C26DCF71FBDC85B528589020BB0B8E383155CFA81B64DD447BBE35E24B8`。
- `yt-dlp --version` 和 1752 个提取器枚举通过，包含 YouTube 与 Bilibili。
- 从 `tmp` 工作目录启动 mpv，内置 ytdl hook 仍能自动找到 mpv 程序目录中的 yt-dlp。
- 使用 W3Schools HTML5 视频页面完成真实联网烟测：yt-dlp 成功解析网页，mpv 成功打开解析出的媒体并解码到首帧，退出码为 0。
- `build-release.ps1` 已把 `yt-dlp.exe` 加入 01 Base 包复制清单，PowerShell 解析器检查通过。
- `yt-dlp.exe` 受根目录 `/*.exe` 规则忽略，不进入 Git；打包规则变更和本次记录尚未提交或推送。

### 2026-07-30 13:37 会话: 全项目组件更新审计

- 本轮仅检查，没有升级或覆盖运行组件；由于工作区已有未提交改动，只执行了安全的 `git fetch origin --prune`，未运行 `git pull`。
- 当前已是上游最新或无需更新：
  - mpv `0.41.0-860-gc8c7d91a8` 与 dyphire 最新构建 `mpv_own-2026-07-06` 一致。
  - yt-dlp `2026.07.04`、uosc `5.12.0`、uosc_danmaku 主分支 `3.0.0` 均为当前版本。
  - LSFG Windows 研究副本基于 `PancakeTAS/lsfg-vk develop` 提交 `8b0da2661c6f3473a7fccc8ba643880050e71642`，与上游 HEAD 完全一致。
  - Lossless.dll 文件版本为 `3.2.2.0`；alass 为 `2.0.0`；LuaJIT 为 2026-07-01 滚动快照。
- 存在明确正式新版：
  - VapourSynth `R73 → R78`，官方 R78 发布于 2026-07-24。
  - 7-Zip `25.01 → 26.02`，Python `3.14.3 → 3.14.6`。
  - TorrServer `MatriX.141 → MatriX.142.2`，umpv-go `1.4.0 → 1.5.1`。
  - Faster-Whisper-XXL 目录为空，配置虽指向其 EXE，但功能当前不可用；上游最新 Pro 为 `r3.256.1`。
- GLSL 与 PlayKit `main` 提交 `4921c6796620` 的逐文件 Git blob 审计：
  - 本地 387 个，上游 429 个；366 个同名文件字节完全一致。
  - 上游有 63 个本地缺失文件，本地有 21 个上游已移除/替换文件。
  - 变化主要在 ACNet、QCOM、FSRCNNX、ESPCN、ESRGAN、RAISR、Ani、AMD 和 Anime4K。
  - 因菜单完整引用现有滤镜路径，更新必须同步增删 `input.conf` 菜单，不能只覆盖 shader 目录。
- Lua 脚本审计：
  - evafast、playlistmanager、sub-select 以及 simple-mpv-webui 的运行代码与上游一致。
  - dyphire 的 `chapter-make-read`、`chapterskip`、`fix-avsync`、`hdr-mode`、`trackselect`，以及 `sub-assrt`、`sub-fastwhisper` 在 2026-05 有上游变化。
  - file-browser 的 `modules/utils.lua` 有 2026-03-27 更新。
  - thumbfast 上游在 2026-06-28 修复非 macOS 环境变量处理；本地同时含黑名单/排除目录定制，需手工合并。
  - uosc 虽为最新版本，但本地有多处 UI 定制和本轮置顶按钮修改，不可直接整包覆盖。
- manager 更新器审计发现：
  - PlayKit 已使用 `main`，`manager.json` 未写分支时默认取 `master`，会导致 shader fetch 失败。
  - quality-menu 白名单误写为 `qualityu%-menu%.lua$`，实际选中 0 个文件。
  - manager 不检查 fetch/subprocess 返回码，失败后仍可能显示“all files updated”。
  - 在修复更新器并加入隔离预览/备份前，不应使用“工具 → 一键更新脚本和着色器”直接覆盖。
- 项目上游整包 `gaoxing64/MPV-lazy-full` 仍为 v2.0.0，没有新版整包可直接替换。
- 审计临时 Git 仓库 `tmp/component-update-audit-20260730/` 已在收尾时删除；本轮 HandShake 记录尚未提交或推送。

### 2026-07-30 14:58 会话: 修复一键更新并保护个性化改动

- **更新前保护**:
  - 在 `tmp/pre-manager-update-20260730-135035/` 保存了 manager、input、mpv 和 uosc 关键文件快照及 SHA-256。
  - 收尾复核确认本轮之前的 `input.conf`、`mpv.conf`、`TopBar.lua` 和 uosc `main.lua` 与快照完全一致。
- **更新器重构**:
  - `manager.lua` 改为异步调用 `script-modules/manager-update.ps1`，更新期间不阻塞播放器界面。
  - 同时注册 `manager-update-all` 脚本消息和按键绑定，修复 uosc 菜单发出消息却无人接收的问题。
  - 每次更新检查 subprocess/Git 退出码；发生错误时不再显示“全部更新成功”。
  - 上游与本地完全一致时只登记基线；仅上游变化时安全快进；双方都变化时使用旧上游基线做三方合并。
  - 首次发现本地与上游不同时一律保留本地文件；以后仍保留本地专属修改。
  - 覆盖现有文件前写入时间戳备份；冲突候选、上游基线、状态和完整报告均保存到被 Git 忽略的 `portable_config/cache/manager/`。
  - 不再自动删除上游已移除的本地文件，也不再默认安装缺失脚本。
- **更新源修复**:
  - 修正 PlayKit `main` 分支和 `portable_config/shaders` 前缀。
  - 修正 quality-menu 白名单拼写。
  - 修正 stax 脚本的 `delete_current_file.lua → delete-current-file.lua` 文件名映射、Eisa 路径/匹配和 file-browser addons 扁平化。
  - 禁用未安装的 trakt-scrobble，避免“一键更新”突然加入可选组件。
  - GitHub 源使用无工作区的 Git 对象树检查，避免 Windows 非法文件名和 `autocrlf` 改写。
  - 缺失着色器不自动安装，避免公开版用户一次点击被动下载大量模型；现有本地独有着色器也不会删除。
- **真实更新结果**:
  - 最终稳定态报告：`UNCHANGED=445`、`PROTECTED=15`、`SKIPPED=74`、`UPDATED=0`、`MERGED=0`、`ERROR=0`。
  - 15 个差异文件全部保持本地版本；包括 14 个脚本/文档和 `aWarpSharp3_RT.glsl`。
  - 当前仍为 387 个 GLSL；63 个上游新增着色器没有被强制装入，21 个本地独有文件没有删除。
- **验证**:
  - PowerShell 5.1 实际执行、JSON 解析、LuaJIT 编译、mpv 隔离脚本加载和菜单消息入口均通过。
  - 新增/修改的 manager 文件为 UTF-8、LF；`git diff --check` 通过。
  - 本轮只修复更新机制和建立安全基线，没有升级 VapourSynth/Python、7-Zip、TorrServer、umpv-go 或 Faster-Whisper。
- **Git 状态**: 本次 manager 改动与前序菜单、置顶按钮、yt-dlp 打包改动均尚未提交或推送。

### 2026-07-30 16:20 会话: 安全合并 15 个差异文件并分批升级二进制

- **回滚保护**:
  - 在 `tmp/pre-safe-merge-binary-upgrade-20260730-150859/` 保存 69 个待合并文件和二进制核心文件，共约 96.49 MiB。
  - 复核 `input.conf`、`mpv.conf`、uosc `main.lua` 和 `TopBar.lua` 与更新前个性化快照 SHA-256 完全一致。
- **15 文件安全合并**:
  - 12 个历史上游版本安全快进到当前 HEAD；`undoredo.lua`、`cycle-commands.lua` 仅补齐文件尾差异；`aWarpSharp3_RT.glsl` 原本已与当前 PlayKit 完全一致。
  - 合并范围包括 chapter/fix-avsync/hdr/trackselect/sub-assrt/sub-fastwhisper/chapterskip、quality-menu、file-browser 两个模块、两个 README 和两个小脚本。
  - 新版 trackselect 已内置协议识别，因此同步移除失效的 `special_protocols` 配置项。
  - 修复 manager 的 `chapterskip.lua` 同名来源覆盖风险：保留 dyphire/mpv-scripts 的静音/片头跳过脚本，禁用另一个功能不同的同名来源。
  - Git blob 哈希改用 `git hash-object --no-filters`，消除着色器受换行过滤器影响的假冲突。
- **已升级组件**:
  - 7-Zip `25.01 → 26.02`；根目录 `7z.exe/7z.dll` 和辅助 `7zr.exe` 已更新。
  - TorrServer `MatriX.141 → MatriX.142.2`，官方资产 SHA-256 为 `BDC6E80DA81918A19D8A74D8FE43A6C1FC584889CB43DE66D573D735F2209A5E`。
  - umpv-go `1.4.0 → 1.5.1`，官方 zip SHA-256 为 `661843FDF9973A3255C064E686E48389D904D5855E6F848D4F5652EB24AD4FA6`。
  - Python `3.14.3 → 3.14.6`，保留项目原有 `python314._pth`；官方嵌入包 SHA-256 为 `DF901E84A896FF1EE720AD03377E0C8D8C2244FDA79808AEEAFF6316DF1CB75C`。
  - 安装 Faster-Whisper-XXL 公开版 `r245.4`；官方 GitHub 未提供摘要，下载包本地 SHA-256 为 `237DEE23939CDABFC96EF859FC5E584B842C3A5557E0D2CA744E1F87C14C5844`，大小与资产记录完全一致，5127 个文件通过 7-Zip 完整性测试。
  - `build-release.ps1` 现在会在 EXE 存在时把完整 Faster-Whisper 公开版放入 Extras；未安装时才保留空目录，不指定 GPU 或设备。
- **VapourSynth R78 兼容结论**:
  - 官方 R78 wheel、Python 3.14.6 和 mpv 在临时环境中均能工作；显式设置 `VSSCRIPT_PATH` 后 mpv 通过三帧滤镜烟测。
  - R78 已将 VSScript 移入 Python 包，根目录复制或硬链接均无法自动确定便携 Python；直接覆盖会破坏用户双击 `mpv.exe` 的现有用法。
  - 正式目录因此继续保留已验证可用的 R73，只升级 Python；R78 包和试验环境保存在 `tmp`，待设计便携加载方案后再迁移。
- **验证**:
  - 15 个改动 Lua 文件全部通过 `loadfile` 语法检查。
  - Python 3.14.6 的 SSL、SQLite、pip、VapourSynth R73 和 BlankClip 取帧通过。
  - TorrServer `--help`、umpv `-help`、Faster-Whisper `--help/--version`、7-Zip 压缩包测试通过。
  - 完整 mpv 配置以 lavfi 视频完成三帧加载，退出码 0；更新脚本全量只读检查无错误。
  - 损坏的 1.93GB 断点续传包已移入 Windows 回收站；正确官方包与解压结果保留。
- **Git 状态**: 本轮与前序改动均尚未提交或推送；建议按逻辑阶段分批提交。

### 2026-07-30 会话: 清理 R78、新增 FW 增量包、重编号 LSFG

- **R78 清理**:
  - VapourSynth R73 是明确支持 Windows 7 的最后版本，暂不升级 R78。
  - 删除 `tmp/` 下共约 340 MB R78 试验文件（official test、symlink test、wheel expanded、installer 和下载 zip）。
  - 确认 `tmp/` 已无 R78 残留。
- **Faster-Whisper 拆分为独立增量包**:
  - 从 `build-release.ps1` 的 03 Extras 中移除 FW 复制逻辑，Extras 仅含着色器 + VapourSynth + Python + 工具。
  - 新建 `build-fasterwhisper-public.ps1`，生成 `04-mpv-fasterwhisper-addon-vX.Y.Z.7z`。
  - FW 包内容门禁：只允许 `faster-whisper-xxl.exe` 和 `ffmpeg.exe` 两个 EXE，排除缓存和生成文件。
  - 包内 README 写明 01→02→03→04→05 安装顺序。
- **LSFG 重编号 04→05**:
  - `build-lsfg-public.ps1`：包名从 `04-mpv-lsfg-addon` 改为 `05-mpv-lsfg-addon`。
  - 包内 README 安装顺序加入 04 FW 包。
- **同步更新的文件**:
  - `build-all-packages.ps1`：构建链条改为 01～03 → 04 FW → 05 LSFG。
  - `build-full-private.ps1`：合并链从 01→02→03→04 扩展为 01→02→03→04(FW)→05(LSFG)；`$FwArchive` 新增为必需文件。
  - 根 `README.MD`：所有"四类包"改为"五类包"；ASCII 图、表格、安装步骤和打包脚本文档全部更新。
- **打包脚本依赖检查**:
  - 核对所有二进制文件名与打包脚本引用：Python 3.14.6、7-Zip 26.02、TorrServer 142.2、umpv-go 1.5.1 均无文件名变化，脚本无需额外同步。
- **验证**:
  - 全部五个 PowerShell 打包脚本通过 `System.Management.Automation.Language.Parser` 语法检查。
  - `git diff --check` 通过（仅仓库既有 autocrlf 提示）。
- **文件变更**: `build-release.ps1`、`build-fasterwhisper-public.ps1`（新增）、`build-lsfg-public.ps1`、`build-all-packages.ps1`、`build-full-private.ps1`、`README.MD`、`docs/codex/STATUS.md`、`version/工作进度.md`。
- **Git 状态**: 本批改动与前序二进制升级、菜单、置顶按钮、yt-dlp 打包等大量改动均尚未提交或推送。建议尽快分批提交。

### 2026-07-30 18:33–21:00 会话: v1.3.0/v1.3.1 打包重构 + LSFG 帧率修复

- **包结构重组** (01→02→03→04→05):
  - 01 Base: mpv 核心 + 运行时 + 基准配置，仅 mpv 升级时重打
  - 02 Extras: 着色器 + VapourSynth + Python + 工具 (原 03，移除 FW)
  - 03 FW: Faster-Whisper AI 字幕 (从 Extras 拆分为独立增量包)
  - 04 LSFG: Vulkan Layer + 启动器 + 控制脚本联动
  - 05 Config: 最终个人设置覆盖层 (原 02，移至最后)
  - 新增 `build-config-public.ps1` 构建 05 Config
  - `build-full-private.ps1` 改为全量 Lossless Scaling 目录备份
- **LSFG 帧率修复历程**:
  - 问题根因：Optimus 笔记本 iGPU 控制交换链 Present 节奏，LSFG Layer 计数错误
  - 尝试 1: `--vulkan-swap-mode=fifo` — 无效，Optimus 无视 FIFO
  - 尝试 2: `--display-fps-override` — 破坏 165Hz 主力机行为，回退
  - 尝试 3: VkImage 句柄比较 — mpv 每次 Present 申请新图像，句柄永远不同
  - 尝试 4: Layer 生成限流 — 跳帧打乱 Vulkan 信号量链导致死锁
  - 最终方案: `estimated-vf-fps` → Lua 侧文件 → PS 设 env var → Layer 遥测覆写
  - 已知限制：Optimus 笔记本仍以显示器速率生成帧，30s 预热后轻微卡顿
- **Layer 编译工具链**: w64devkit + CMake + Ninja 存放于 `buildtool/`（未纳入 Git）
- **v1.3.1 发布**:
  - Tag `v1.3.1` 已推送
  - 五个公开包上传 GitHub Release，个人全量包仅本地保留
  - SHA-256 核验: 01 `30790058` / 02 `94959d1d`+`abc25eac` / 03 `e10b1a4a` / 04 `2e2e53cc` / 05 `e2d18755`
- **Git 状态**: 全部提交已推送到 `origin/master`；工作树干净（除 `buildtool/` 未跟踪）
