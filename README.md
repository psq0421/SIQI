# 司器（SIQI）
English：[README_EN.md](https://github.com/psq0421/SIQI/edit/master/README_EN.md)

司器是一款面向 Android 的端侧优先 AI 工作站。会话、配置、API 密钥、模型记录、工作区信息、权限审计、工作日志和缓存索引均保存在本机；联网只用于用户明确配置的 API、模型下载、MCP 目录同步、GitHub 导入和官方资源访问。

应用 ID：`com.psq.siqi`  
最低版本：Android 10（API 29）  
当前目标版本：Android 17（API 37）  
Flutter：stable 3.47.0 或更高兼容版本  
当前版本：`1.0.0-beta.1+4006`  
源代码许可：MIT License

> MIT 许可允许个人及商业使用。模型、MCP 服务、Harness 运行包和其他第三方资源仍分别受其自身许可证与服务条款约束。

### Beta1（build 4006）

- 保持 Alpha3 全部功能和界面体验，发行包统一为具备完整端侧推理能力的 arm64-v8a 架构。
- 压缩 APK 内的 llama.cpp、ONNX Runtime、Sherpa-ONNX 等原生运行库，安装后由 Android 自动解压，不改变推理结果与模型兼容性。
- 移除未使用的代码生成链和重复直接依赖，缩短依赖解析与构建路径。
- Release APK 从 Alpha3 的 247.5 MB 降至 39.2 MiB，减少约 84.2%；Debug 保留调试符号与开发运行时，因此体积显著更大。

### Alpha3（build 4005）

- 全新安装时自动创建应用专属的 `Projects`、`Models`、`Exports`、`Logs`、`Cache` 目录，并将工作区和模型目录初始化到可直接读写的位置，修复首次选目录被统一判定为不可写的问题。
- 权限页新增传统文件读写权限和可选“所有文件访问”。后者只由用户主动打开 Android 专用设置页，不在启动时强制申请；Root 仍不申请。
- 端侧推理、TTS 与 ASR 的物理内存保护上限由 60% 放宽至 85%。
- 一个 API Key 配置可管理多个模型映射，并支持备注、默认兜底模型、请求地址、自定义 Headers 和可选的输入/输出 Token 计费。

## 当前实现

### 对话工作台

- Chat：标准问答、会话历史、本地搜索、流式响应、附件能力检测。
- Agent：面向本地工作区的自主编程闭环，先展示计划和动作，再由用户批准写入或执行；支持执行结果复核、继续修复和按本轮快照撤销。
- Harness：仅接受已测试且已保存密钥的 DeepSeek API 配置，提供审查、静态检查和测试建议。
- MCP：默认使用 Streamable HTTP，兼容旧式 HTTP+SSE，并为开发者提供 stdio；支持连接测试、工具发现和逐次批准后的工具调用。
- AI 团队：最多选择 8 个已测试的 API 配置，多轮共享前序输出，由协调成员生成最终汇总。
- 纯文本模型会禁用图片、PDF 和音频附件入口；多模态能力由模型配置显式声明。

内置系统提示词强调本地优先、证据验证、工作区边界、最小修改、非破坏性操作和远程数据边界。用户仍可在设置中编辑提示词，并使用 `{user_name}`、`{current_time}` 变量。

### 端侧模型

应用集成 `llama.cpp` FFI，通过独立 Isolate 加载 GGUF 和执行推理。Release APK 内直接包含 arm64 原生库，不依赖占位桥或远程推理服务。移动端资源规划会按物理内存 85% 硬上限动态收缩上下文；视觉输入在工作 Isolate 中缩放到最长边 1024 px，并按模型体量限制单次本地输出，避免把远程 API 的 256K 配置直接套到手机推理。

以下对话模型提供可由当前 APK 直接执行的 Q4_K_M 构件；每项都有固定下载地址、真实文件大小、来源页面和 SHA-256。下载支持断点续传，安装前必须校验散列值。

| 模型 | 大小 | 最低建议内存 | 来源 |
|---|---:|---:|---|
| Hunyuan-0.5B | 0.35 GB | 2 GB | ModelScope / bartowski |
| Hunyuan-1.8B | 1.13 GB | 4 GB | ModelScope / bartowski |
| Hunyuan-4B | 2.61 GB | 6 GB | ModelScope / bartowski |
| Hunyuan-7B | 4.62 GB | 10 GB | ModelScope / bartowski |
| Gemma4-E2B | 3.11 GB | 6 GB | ModelScope / Unsloth |
| Gemma4-E4B | 4.98 GB | 9 GB | ModelScope / Unsloth |
| Qwen3.5-0.8B | 0.53 GB | 3 GB | ModelScope / Unsloth |
| Qwen3.5-2B | 1.28 GB | 5 GB | ModelScope / Unsloth |
| Qwen3.5-4B | 2.74 GB | 7 GB | ModelScope / Unsloth |
| Qwen3.5-9B | 5.68 GB | 12 GB | ModelScope / Unsloth |

模型卡片显示许可证。腾讯混元包受腾讯混元社区许可约束；Qwen 与 Gemma 条目按各自模型卡展示的许可证执行。下载源变更或散列值不一致时，应用不会安装文件。

### 统一模型任务目录

模型市场现统一管理对话、TTS、ASR 与 OCR 四类任务，并明确区分以下状态：

- **端侧可运行**：APK 已包含能够解释该模型构件的原生运行时；
- **仅管理官方权重**：可以下载和校验官方文件，但当前 Android FFI 不能直接执行其格式；
- **等待官方兼容构件**：保留兼容目标和官方说明，不提供必然失败的下载按钮。

新增兼容目录包括：

| 类别 | 型号 |
|---|---|
| 对话 | openPangu 2.0 7B、BlueLM 3.5 Nano、MiMo 3B、AndesGPT，以及原有 Hunyuan、Gemma 4、Qwen3.5 型号 |
| TTS | Supertonic 3、MOSS-TTS-Nano、Soprano-1.1-80M、Qwen3.5-TTS、Pangu-TTS |
| ASR | Qwen3-ASR-1.7B、Qwen3.5-ASR、OctoASR、Moonshine、Pangu-ASR |
| OCR | PP-OCRv6 Tiny、XCurOS-OCR、GLM-OCR、Qwen3.5-Vision、Pangu-Vision |

Supertonic 3 使用 `sherpa-onnx` FFI 和 ModelScope 中国大陆源，可直接完成本地语音合成。MOSS-TTS-Nano、Qwen3-ASR-1.7B 与 GLM-OCR 已接入可核验的官方权重管理，但当前官方格式不是 APK 内置 FFI 可直接执行的格式。其余未公开可验证构件的型号只显示兼容状态，不会伪装为可用模型。

### 模型下载与完整性

1. 打开“实验室 → 模型市场”。
2. 查看模型大小、最低内存、许可证和官方来源。
3. 点击下载。所有已开放下载的模型构件均使用 ModelScope 大陆 CDN；通知权限只在需要显示下载进度时申请，拒绝后下载仍可继续。
4. 暂停后再次点击可从 `.part` 文件续传。
5. 下载完成后应用计算 SHA-256；不匹配的临时文件会被删除并写入工作日志。
6. 下载成功时持久化校验时间。文件大小和修改时间未变时复用 30 天；文件被改动或校验过期后重新计算 SHA-256，避免每次冷启动都扫描整个 GGUF。

### MCP 商店与管理

“实验室 → MCP 商店”读取 ModelScope 的公开 MCP 目录，支持：

- 分页同步、SQLite 本地缓存和离线搜索；
- 按名称、作者或说明过滤；
- 打开官方详情；
- 对具有公开 HTTP/SSE 托管端点的条目一键导入管理器；
- 导入后先测试连接，再查看服务公开的工具列表；
- 同步和导入操作写入本地工作日志。

ModelScope 可能要求浏览器完成 WAF 安全验证。应用会验证响应确实是 JSON；若收到挑战页面，不会把 HTML 当成插件数据，也不会清空已有缓存。此时可从右上角打开官方目录。

普通用户只能配置 URL 型 MCP。stdio 与命令型 MCP 仅在开启开发者模式后显示，下载或导入的第三方内容不会被静默执行。

### DeepSeek Harness

- Harness 模式只使用 DeepSeek API 配置。
- API 配置必须先通过连接测试。
- 可验证并下载官方 npm 运行包 `0.1.1-rc.2`。
- 可同步并管理指定插件目录中的插件归档。
- 官方运行环境要求 Node.js，Android APK 不会伪装内嵌一个不完整运行时；可连接由 Termux 或同一局域网电脑启动的兼容服务。
- 插件只下载和校验，不会自动执行。

### TTS、ASR 与 OCR

应用接入真实 `sherpa_onnx 1.13.6` FFI，并在 `lib/core/services/` 下提供独立的 TTS、ASR 与 OCR 服务。服务以模型定义为参数，支持多模型切换和统一的完整性、运行时及内存检查。

- **TTS**：Supertonic 3 在工作 Isolate 中生成本地 WAV；长按 AI 回复可选择“语音朗读”，并支持停止播放。
- **ASR**：对话输入框提供录音按钮。麦克风权限只在用户主动录音时申请；单个音频最长 180 分钟，以 30 秒分片识别，不把整段录音读入 Dart 内存。
- **音频解码**：Android MediaCodec 可将 MP3、M4A、AAC、FLAC、OGG、OPUS、AMR、3GP、MP4 等容器转换为路径型单声道 PCM WAV。
- **OCR**：对话输入框可从相册或截图选择图片，复用已安装的 Qwen3.5 或 Gemma 4 视觉模型和投影文件，结果直接写入输入框。
- **内存保护**：模型加工作缓冲区不得超过物理内存的 85%，不足时在加载前阻止任务。

多模态专区读取设备总内存和当前可用内存，展示各模型的真实运行状态，并按剩余内存给出单次音频建议时长。只有同时满足真实来源、完整校验信息、Android 运行时可用和内存峰值限制后，模型才会显示为可运行。

### 源文件格式

对话附件、OCR 和 ASR 共用统一的文件读取层：

- 代码与脚本：Dart、Kotlin、Java、Python、JavaScript、TypeScript、Go、Rust、C/C++、Swift、Objective-C、C#、F#、Scala、Ruby、PHP、Lua、R、Perl、SQL、Shell、PowerShell、Gradle、Groovy、Vue、Svelte 等；
- 文本与配置：TXT、Markdown、RST、TeX、JSON/JSONL、YAML、TOML、XML、HTML、CSS、CSV/TSV、INI、Properties、ENV 和日志；
- 办公与电子文档：PDF、DOCX、PPTX、XLSX、ODT、ODS、ODP、EPUB、RTF；
- 图片：PNG、JPEG、WebP、GIF、BMP、TIFF、HEIC、HEIF；
- 音频：WAV、MP3、M4A、AAC、FLAC、OGG、OPUS、AMR、3GP、MP4。

超过 5 MB 的文本和长音频优先采用流式或路径型处理；Office/OpenDocument 文件按压缩条目提取正文或大纲，图片会在后台线程归一化，避免在 UI 线程复制大文件。

### 工作区与项目文件

首次启动会自动创建并使用无需额外权限的应用专属工作区，典型位置为：

`/storage/emulated/0/Android/data/com.psq.siqi/files/Projects`

Android 11 及以上受 Scoped Storage 管理。用户仍可通过系统目录选择器更换目录；若确需直接操作共享存储中的任意工作区，可在“权限与隐私”中主动开启“所有文件访问”。该高级权限不是启动必需项，拒绝不会阻止应用启动。

Agent 文件操作执行以下约束：

- 读取、写入、建目录和索引必须位于当前工作区；
- 拒绝 `..` 路径穿越和越界解析路径；
- 写入前展示动作、目标和原因；
- 默认要求用户确认修改；
- 不宣称未实际执行的命令、修改或测试结果。

生成项目的建议下载位置可在“设置 → 数据与存储”中查看和修改。

### 开发者 Shell

普通用户界面不显示 Shell，也不要求输入任何命令。开启“设置 → 开发者模式”后，实验室才会出现完整 Shell 队列。

Shell 具备命令历史、消息队列、工作目录、超时、输出截断和工作日志。执行使用 Android 的 Linux 用户空间：

- 系统 Shell：`sh -c`；
- 可选 Termux 或 Shizuku 环境；
- 禁止 `su`、`sudo`、Magisk、提权和系统分区写入；
- 高危命令需要二次确认；
- 单任务默认两分钟超时；
- 标准输出和错误输出按 UTF-8 记录，单项最多保留 1 MiB。

应用不申请 Root 权限。Android 底层基于 Linux，但应用仍受 UID 沙箱、SELinux 和 Scoped Storage 约束。

### 权限与隐私

权限在对应功能首次使用时申请，不在启动时批量索取。拒绝任何权限都不会导致启动失败。

“设置 → 权限与隐私”会列出：

- 权限名称；
- 触发功能；
- 申请理由；
- 请求时间与结果；
- 用户可清除的本地审计记录。

可能使用的权限包括通知、麦克风、相机、媒体文件、旧版 Android 文件读写，以及用户主动选择的“所有文件访问”。工作区与模型目录默认位于无需存储权限的应用专属目录。应用不申请 Root；“所有文件访问”具有应用商店合规限制，仅作为明确说明用途后的高级可选项。

### 工作日志与缓存

“设置 → 日志与缓存”支持：

- 查看模型下载、权限、Shell、MCP、Harness、Agent 和团队任务日志；
- 清除工作日志；
- 统计应用缓存；
- 删除可再生成的缓存，不删除会话、API 配置或已安装模型。

## 用户使用流程

### 首次启动

1. 阅读 MIT 许可、隐私边界和独立项目声明。
2. 设置昵称。
3. 选择浅色、深色或跟随系统。
4. 选择工作区，或暂时跳过。
5. 进入主界面后按实际功能申请权限。

界面遵循 Material 3 和原生 Android 导航、颜色、触控目标、返回行为与系统动效。所有表面统一使用 12 px 圆角，不包含自定义背景、液态玻璃、华丽模式或强制高刷新率逻辑。

### 配置远程 API

1. 打开“设置 → API 配置”。
2. 选择厂商模板或兼容格式。
3. 填写供应商名称、备注、请求地址、API Key 和可选 Headers。
4. 填写默认兜底模型；如一枚 Key 可调用多个模型，可按“显示名称 = 上游模型 ID”逐行添加映射。
5. 标记模型是否支持多模态，并可选填币种、输入单价和输出单价（每百万 Tokens）。
6. 点击“测试连接”。未测试的配置不能用于对话；测试使用默认兜底模型。

API Key 存入 Android 加密存储，数据库只保存非密钥配置。远程请求只发往用户明确填写的站点。

### 使用 AI 团队

1. 至少创建两个已测试的 API 配置。
2. 打开“实验室 → AI 团队”。
3. 新建团队并选择最多 8 个成员。
4. 设置 1–4 轮协作。
5. 输入任务并启动。
6. 成员依次读取任务和前序结果，最后由协调成员汇总。
7. 可随时停止或删除本地团队记录。

### 使用本地语音与 OCR

1. 在“实验室 → 模型市场”按“语音合成”“语音识别”或“OCR”筛选模型。
2. 只有标记为“端侧运行时已内置”的模型可以直接执行；“仅管理模型文件”不会被错误传给不兼容的运行时。
3. 安装 Supertonic 3 后，长按任意 AI 回复并选择“语音朗读”。
4. 安装兼容 ASR 模型后，点击输入框旁的麦克风按钮开始录音，再次点击停止并转写。
5. 安装带视觉投影的 Qwen3.5 或 Gemma 4 后，点击图片识别按钮，从相册或截图选择图片。
6. 录音、转写、OCR 和语音生成都在本地执行；若所选对话模型是远程模型，只有用户主动发送输入框内容时才会产生远程请求。

## 本地数据

- `shared_preferences`：轻量设置；
- `sqflite`：会话、消息、API 配置、模型记录、MCP、权限审计、工作日志和团队记录；
- `flutter_secure_storage`：API Key 等敏感凭据；
- 应用支持目录：默认模型与可再生成缓存；
- 用户授权目录：工作区和导出文件。

导出 `.siqi` 包可包含会话与代码文件；配置导出为 `.siji_config`，API Key 永远脱敏。导入前应确认文件来源。

## 在 Windows PC 配置 Flutter

### 1. 安装依赖

安装以下软件：

- Git for Windows；
- Flutter stable 3.47.0 或兼容更新版；
- Android Studio；
- Android SDK Platform 37；
- Android SDK Build-Tools 37；
- Android SDK Command-line Tools；
- Android NDK `29.0.14206865`；
- CMake 3.22.1；
- JDK 17（可使用 Android Studio 内置 JBR）。

把 Flutter 的 `bin` 加入 PATH 后，在 PowerShell 运行：

```powershell
flutter doctor -v
flutter doctor --android-licenses
```

确保 Android toolchain 和 Android Studio 均通过检查。

### 2. 打开工程

1. Android Studio 选择 **Open**，打开仓库根目录，不要只打开 `android/`。
2. 安装 Flutter 与 Dart 插件。
3. 等待 `pub get` 和 Gradle Sync 完成。
4. 运行 `flutter gen-l10n`。
5. 运行 `flutter analyze`，确认无问题。

如果用户名、OneDrive 或工程路径含中文导致 CMake/Ninja 异常，可为工程、Flutter 和 Pub Cache 创建纯 ASCII 入口。本项目验证环境使用：

```text
C:\Users\Public\siqi-build-workspace
C:\Users\Public\flutter-siqi-3.47.0
C:\Users\Public\siqi-pub-cache
C:\Users\Public\android-sdk
```

ASCII 入口可以是目录联接，不需要移动或删除原工程。

### 3. USB 真机调试

1. 在手机开启开发者选项与 USB 调试。
2. USB 连接后在手机上确认调试指纹。
3. 在 PowerShell 运行 `flutter devices`。
4. Android Studio 顶部选择真机，点击 Run 调试。
5. 性能问题使用 Profile，而不是用 Debug 帧率判断：

```powershell
flutter run --profile -d <device-id>
```

### 4. 构建 Debug 与 Release APK

先执行统一检查：

```powershell
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
```

构建可附加调试器的 Debug APK：

```powershell
flutter build apk --debug
adb install -r -t build/app/outputs/flutter-apk/app-debug.apk
```

构建最终 Release APK：

```powershell
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

以上 `-r` 为覆盖安装，会保留会话、设置和已下载模型。不要为升级验证执行卸载或清除应用数据。

如只发布 arm64，可另外构建：

```powershell
flutter build apk --release --split-per-abi --target-platform android-arm64
```

发布前应在 `android/key.properties` 配置独立签名。没有发布密钥时，工程只为本地验证回退到 debug 签名，不能作为正式商店包。

## 已验证基线

- `flutter analyze`：0 问题；
- Android 17 / API 37 / arm64 真机（设备代号 `2206122SC`）：Debug 与 Release 均覆盖安装成功，保留原应用数据；
- 当前版本号：`1.0.0-beta.1 (4006)`；
- Qwen3.5-4B Q4_K_M 主模型与视觉投影从断点续传完成并通过 SHA-256；
- 真实端侧文本推理成功，热请求复用已加载引擎，停止操作能阻止同一引擎并发生成；
- 真实端侧图片输入已完成最长边 1024 px 归一化，并在 4B 模型上生成了与截图内容一致的流式回答；
- Release 冷启动进程保持运行，清单不含 `debuggable`，并通过 16 KB 页面与 ZIP 对齐校验；
- APK 内包含 `libllama.so`、`libllamadart.so`、`libggml*.so`、`libmtmd.so`、`libsherpa-onnx-c-api.so` 与 `libonnxruntime.so`，覆盖文本、Vulkan/CPU、多模态投影和语音运行时；
- Supertonic 3、Qwen3-ASR-1.7B、MOSS-TTS-Nano 与 GLM-OCR 的代表性 ModelScope 构件地址已返回 HTTP 200；
- 未发现 Flutter/Dart 崩溃；
- 安全锁屏状态下无法自动完成可视化页面巡检，需用户解锁后继续交互测试。

## 安全与限制

- 不绕过设备锁屏、系统沙箱、SELinux 或 Scoped Storage。
- 不执行下载的 MCP/Harness 插件，除非开发者明确配置并启动。
- 不提供未验证的模型下载项。
- 不会把“可下载的官方权重”错误标记为“当前 APK 可执行”；模型卡片会明确显示运行状态。
- 不隐藏远程请求目的地。
- Agent 和 Shell 可能修改本地文件，使用前请备份重要工作区。
- GitHub OAuth、厂商 API、MCP 与模型镜像的可用性由对应服务控制。

## 许可证与项目

- 项目主页：<https://github.com/psq0421/SIQI>
- 源代码：MIT License
- 本项目为独立开源项目，与模型厂商、API 厂商和模型托管平台不存在商业隶属关系。
