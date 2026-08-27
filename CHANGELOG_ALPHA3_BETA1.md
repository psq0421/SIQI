# SIQI Alpha3 & Beta1 Combined Changelog

Version: `1.0.0-beta.1+4006`  
Included releases: Alpha3 (`build 4005`) → Beta1 (`build 4006`)  
Android compatibility: Android 10–17 (`API 29–37`)

This release contains all storage, permission, local-model, multimodal, and API-configuration improvements introduced in Alpha3. Beta1 preserves those capabilities while substantially simplifying the build and reducing the Release APK size.

## English

### Alpha3 — Storage, permissions, and provider configuration

#### Reliable workspace initialization

- Fixed the fresh-install issue that incorrectly reported a selected folder as not directly readable or writable.
- Automatically creates app-specific `Projects`, `Models`, `Exports`, `Logs`, and `Cache` directories.
- Initializes the workspace and model storage to locations that work without broad storage permission.
- Keeps Android's system directory picker available for user-selected locations.
- Follows Scoped Storage and never requests root access.

#### Permission and privacy management

- Added management for legacy file read/write permissions where applicable.
- Added an optional entry for Android's “All files access” setting.
- Broad file access is never forced during startup and must be enabled explicitly by the user.
- Denying a permission does not prevent the app from starting or using unrelated features.
- The permission page records the permission, feature, reason, request time, and result.
- Local permission audit entries can be deleted by the user.

#### Expanded local-memory allowance

- Raised the physical-memory safety ceiling for local inference, TTS, and ASR from 60% to 85%.
- Checks total memory, available memory, model size, and runtime buffers before loading.
- Rejects unsafe tasks before model loading to reduce process termination and out-of-memory crashes.

#### One API key, multiple models

- Expanded provider profiles with provider name, notes, API key, endpoint, and custom headers.
- One API key can expose multiple display-name-to-upstream-model mappings.
- Added a configurable fallback model.
- Added per-model multimodal capability metadata.
- Added optional currency and input/output token pricing fields.
- Untested configurations are prevented from entering the selectable model list.
- API keys remain in Android encrypted storage rather than the local SQLite database.

### Beta1 — Smaller builds with the same feature set

#### Release architecture optimization

- Standardized the Release APK on `arm64-v8a` for current Android phones and tablets.
- Removed unused `x86_64` and `armeabi-v7a` Release artifacts.
- Preserved the native runtimes required for local text generation, multimodal projection, TTS, ASR, and OCR.
- Retained Flutter, llama.cpp, Vulkan/CPU inference, ONNX Runtime, and Sherpa-ONNX libraries.

#### Native-library and dependency cleanup

- Compressed large native runtime libraries and lets Android extract them during installation.
- Removed unused code-generation packages and duplicate direct dependencies.
- Shortened dependency resolution and build paths without changing model formats or inference behavior.
- Preserved compatibility with Alpha3 sessions, settings, API profiles, workspaces, and downloaded models.

#### APK size reduction

| Build | APK size |
|---|---:|
| Alpha3 Release | approximately 247.5 MB |
| Beta1 Release | approximately 39.2 MiB |
| Beta1 Debug | approximately 168.7 MiB |

The Beta1 Release APK is approximately 84.2% smaller than the Alpha3 Release APK. The Debug package remains larger because it includes development runtimes and debugging information.

### Capabilities retained in Beta1

- Chat, Agent, DeepSeek Harness, MCP, and AI Team workflows with up to eight configured AI members.
- ModelScope-based mainland China model downloads with resumable transfers and integrity checks.
- Local GGUF inference through llama.cpp.
- Unified dialogue, TTS, ASR, and OCR model management.
- Multimodal attachments with explicit model capability checks.
- MCP catalog, configuration, connection tests, and tool discovery.
- Workspace, developer Shell, work-log, and cache management.
- Local persistence for conversations, models, configuration, and permission audit history.
- `.siqi` import, export, and sharing.
- Simplified Chinese, Traditional Chinese, English, and Japanese.
- Material 3 and native Android navigation behavior.

### Build baseline

- Application ID: `com.psq.siqi`
- Version name: `1.0.0-beta.1`
- Version code: `4006`
- Minimum Android version: Android 10 / API 29
- Target Android version: Android 17 / API 37
- `flutter analyze`: 0 issues at the verified build baseline
- Debug and Release APKs support in-place installation while retaining app data.
- The Release APK passed arm64 native-library and APK V2 signature checks.

### Upgrade notes

Install the new APK over the existing version. Do not uninstall the previous version or clear app data if you want to retain conversations, API profiles, downloaded models, workspace settings, MCP configurations, permission audit records, and work logs.

The current locally distributed APK uses a development signing certificate for upgrade testing. A long-term production signing key is required before store or public production distribution.

---

## 中文

### Alpha3：存储、权限与供应商配置完善

#### 工作区可靠初始化

- 修复全新安装后选择文件夹时，被错误提示为无法直接读写的问题。
- 自动创建应用专属的 `Projects`、`Models`、`Exports`、`Logs` 和 `Cache` 目录。
- 将工作区和模型目录初始化到无需广泛存储权限即可工作的安全位置。
- 保留 Android 系统目录选择器，允许用户主动选择其他位置。
- 遵循 Scoped Storage，始终不申请 Root 权限。

#### 权限与隐私管理

- 在适用的 Android 版本上加入传统文件读取、写入权限管理。
- 新增可选的“所有文件访问”系统设置入口。
- 不在启动时强制索取广泛文件权限，必须由用户主动开启。
- 拒绝任意权限均不会阻止应用启动，也不会影响无关功能。
- 权限页面记录权限名称、触发功能、申请理由、请求时间和结果。
- 用户可以自行删除本地权限审计记录。

#### 放宽端侧内存限制

- 将本地推理、TTS 与 ASR 的物理内存安全上限由 60% 调整为 85%。
- 加载前综合检查总内存、可用内存、模型体积和运行缓冲区。
- 在模型加载前阻止不安全任务，降低系统杀进程与内存不足闪退风险。

#### 一枚 API Key 管理多个模型

- 供应商配置新增供应商名称、备注、API Key、请求地址和自定义 Headers。
- 同一枚 API Key 可以维护多条“显示名称 → 上游模型 ID”映射。
- 新增默认兜底模型配置。
- 支持为每个模型单独标记多模态能力。
- 新增可选的币种、输入 Token 单价与输出 Token 单价。
- 未通过连接测试的配置不会进入可选模型列表。
- API Key 继续保存在 Android 加密存储中，不写入本地 SQLite 数据库。

### Beta1：保持完整体验，显著缩小构建体积

#### Release 架构优化

- Release APK 统一面向当前 Android 手机和平板使用的 `arm64-v8a` 架构。
- 移除未使用的 `x86_64` 与 `armeabi-v7a` Release 构件。
- 保留本地文本生成、多模态投影、TTS、ASR 和 OCR 所需原生运行时。
- 保留 Flutter、llama.cpp、Vulkan/CPU 推理、ONNX Runtime 与 Sherpa-ONNX 库。

#### 原生库与依赖精简

- 压缩大型原生运行库，安装时由 Android 自动解压。
- 移除未使用的代码生成包和重复直接依赖。
- 缩短依赖解析与构建路径，不改变模型格式和推理行为。
- 兼容 Alpha3 的会话、设置、API 配置、工作区与已下载模型。

#### APK 体积变化

| 构建版本 | APK 体积 |
|---|---:|
| Alpha3 Release | 约 247.5 MB |
| Beta1 Release | 约 39.2 MiB |
| Beta1 Debug | 约 168.7 MiB |

Beta1 Release 相比 Alpha3 Release 缩小约 84.2%。Debug 包因保留开发运行时与调试信息，体积仍明显大于 Release 包。

### Beta1 完整保留的能力

- Chat、Agent、DeepSeek Harness、MCP，以及最多八个已配置 AI 成员的团队协作流程。
- 基于 ModelScope 中国大陆源的模型下载、断点续传与完整性校验。
- 通过 llama.cpp 执行本地 GGUF 推理。
- 对话、TTS、ASR 和 OCR 模型统一管理。
- 多模态附件及模型能力显式检查。
- MCP 目录、配置、连接测试和工具发现。
- 工作区、开发者 Shell、工作日志和缓存管理。
- 会话、模型、配置与权限审计历史全部本地持久化。
- `.siqi` 导入、导出和分享。
- 简体中文、繁体中文、英语和日语。
- Material 3 与原生 Android 导航行为。

### 构建基线

- 应用 ID：`com.psq.siqi`
- 版本名称：`1.0.0-beta.1`
- 版本代码：`4006`
- 最低系统：Android 10 / API 29
- 目标系统：Android 17 / API 37
- 已验证构建基线的 `flutter analyze`：0 个问题
- Debug 与 Release APK 均支持覆盖安装并保留应用数据。
- Release APK 已通过 arm64 原生库和 APK V2 签名检查。

### 升级说明

请直接覆盖安装新版 APK。如果需要保留会话、API 配置、已下载模型、工作区设置、MCP 配置、权限审计记录和工作日志，请勿卸载旧版本，也不要清除应用数据。

当前本地分发 APK 使用开发签名证书，适合升级与真机测试。正式上架或公开生产分发前，需要换用长期保存的正式签名密钥。

## Project links / 项目链接

- Repository / 项目仓库：[github.com/psq0421/SIQI](https://github.com/psq0421/SIQI)
- License / 开源协议：MIT License
