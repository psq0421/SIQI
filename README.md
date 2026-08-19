# 司器（SIQI）

司器是一款面向 Android 的端侧优先 AI 工作站。会话、配置、API 密钥、模型记录、工作区信息、权限审计、工作日志和缓存索引均保存在本机；联网只用于用户明确配置的 API、模型下载、MCP 目录同步、GitHub 导入和官方资源访问。

应用 ID：`com.psq.siqi`  
最低版本：Android 10（API 29）  
当前目标版本：Android 16（API 36）  
Flutter：stable 3.38.0 或更高兼容版本  
源代码许可：MIT License

> MIT 许可允许个人及商业使用。模型、MCP 服务、Harness 运行包和其他第三方资源仍分别受其自身许可证与服务条款约束。

## 当前实现

### 对话工作台

- Chat：标准问答、会话历史、本地搜索、流式响应、附件能力检测。
- Agent：面向本地工作区的自主编程流程，先展示计划和动作，再由用户批准写入或执行。
- Harness：仅接受已测试的 DeepSeek API 配置，提供审查、静态检查和测试建议。
- MCP：管理 HTTP、SSE 与开发者 stdio 服务，执行连接测试并读取工具列表。
- AI 团队：最多选择 8 个已测试的 API 配置，多轮共享前序输出，由协调成员生成最终汇总。
- 纯文本模型会禁用图片、PDF 和音频附件入口；多模态能力由模型配置显式声明。

内置系统提示词强调本地优先、证据验证、工作区边界、最小修改、非破坏性操作和远程数据边界。用户仍可在设置中编辑提示词，并使用 `{user_name}`、`{current_time}` 变量。

### 端侧模型

应用集成 `llama.cpp` FFI，通过独立 Isolate 加载 GGUF 和执行推理。Release APK 内直接包含 arm64 原生库，不依赖占位桥或远程推理服务。

模型市场只列出以下 Q4_K_M 包；每项都有固定下载地址、文件大小、来源页面和 SHA-256。下载支持断点续传，安装前必须校验散列值。

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

### 模型下载与完整性

1. 打开“实验室 → 模型市场”。
2. 查看模型大小、最低内存、许可证和官方来源。
3. 点击下载。通知权限只在需要显示下载进度时申请；拒绝后下载仍可继续。
4. 暂停后再次点击可从 `.part` 文件续传。
5. 下载完成后应用计算 SHA-256；不匹配的临时文件会被删除并写入工作日志。
6. 已安装文件按路径、大小和修改时间缓存校验结果，界面刷新不会反复扫描整个 GGUF。

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
- 可验证并下载官方 npm 运行包。
- 可同步并管理指定插件目录中的插件归档。
- 官方运行环境要求 Node.js，Android APK 不会伪装内嵌一个不完整运行时；可连接由 Termux 或同一局域网电脑启动的兼容服务。
- 插件只下载和校验，不会自动执行。

### 多模态专区

专区读取设备总内存和当前可用内存，以总内存的 60% 作为模型加任务的硬上限，并据剩余内存估算单次音频建议时长。

截至当前核验：

- 官方 MiMo-V2.5-ASR 权重约 32.07 GB；
- MiMo-Audio-7B-Instruct 加 Audio Tokenizer 约 23.85 GB；
- 官方尚未提供经过验证、可在本项目 Android 运行时上执行的小型量化 TTS/ASR 包。

因此 24 GB 及以下内存设备会显示不兼容并禁止下载。专区保留官方来源链接；只有同时满足真实下载源、Android 运行时可用和 60% 峰值限制后才会开放下载，绝不展示虚假的“可用模型”。

### 工作区与项目文件

首次引导可选择工作区。默认建议位置为：

`/storage/emulated/0/Siqi/Projects`

Android 11 及以上使用系统目录选择器和 Scoped Storage。应用不会申请 Root，也不会申请“管理所有文件”权限。若系统未授予建议目录，用户可选择其他目录，拒绝不会阻止应用启动。

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

可能使用的权限包括通知、麦克风、相机和用户选择的媒体文件。工作区与模型目录通过系统选择器授权。应用不申请 Root 和所有文件访问权。

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

界面遵循 Material 3 和原生 Android 导航、颜色、触控目标、返回行为与系统动效。所有表面统一使用 12 px 圆角，不包含自定义背景或强制高刷新率逻辑。

### 配置远程 API

1. 打开“设置 → API 配置”。
2. 选择厂商模板或兼容格式。
3. 填写名称、Base URL、模型 ID、API Key 和可选 Headers。
4. 标记模型是否支持多模态。
5. 点击“测试连接”。未测试的配置不能用于对话。

API Key 存入 Android 加密存储，数据库只保存非密钥配置。远程请求只发往用户明确填写的站点。

### 使用 AI 团队

1. 至少创建两个已测试的 API 配置。
2. 打开“实验室 → AI 团队”。
3. 新建团队并选择最多 8 个成员。
4. 设置 1–4 轮协作。
5. 输入任务并启动。
6. 成员依次读取任务和前序结果，最后由协调成员汇总。
7. 可随时停止或删除本地团队记录。

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
- Flutter stable 3.38.0 或兼容更新版；
- Android Studio；
- Android SDK Platform 36；
- Android SDK Build-Tools 36；
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
C:\Users\Public\flutter-siqi-3.38.0
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

### 4. 构建 APK

本地 arm64 Release：

```powershell
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter build apk --release --split-per-abi --target-platform android-arm64
```

输出文件：

`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

覆盖安装且保留数据：

```powershell
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

发布前应在 `android/key.properties` 配置独立签名。没有发布密钥时，工程只为本地验证回退到 debug 签名，不能作为正式商店包。

## 已验证基线

- `flutter analyze`：0 问题；
- Android 14-17 / arm64 / 小米10-17系列、：Release 覆盖安装成功；
- Release 版本号：`1.0.0 (2001)`；
- 冷启动 Activity 返回成功，进程持续存活；
- APK 内包含 `libllama_cpp.so` 和 `libomp.so`；
- 未发现 Flutter/Dart 崩溃；
- 安全锁屏状态下无法自动完成可视化页面巡检，需用户解锁后继续交互测试。

## 安全与限制

- 不绕过设备锁屏、系统沙箱、SELinux 或 Scoped Storage。
- 不执行下载的 MCP/Harness 插件，除非开发者明确配置并启动。
- 不提供未验证的模型下载项。
- 不隐藏远程请求目的地。
- Agent 和 Shell 可能修改本地文件，使用前请备份重要工作区。
- GitHub OAuth、厂商 API、MCP 与模型镜像的可用性由对应服务控制。

## 许可证与项目

- 项目主页：<https://github.com/psq0421/SIQI>
- 源代码：MIT License
- 本项目为独立开源项目，与模型厂商、API 厂商和模型托管平台不存在商业隶属关系。
