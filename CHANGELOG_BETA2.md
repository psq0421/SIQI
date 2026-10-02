# SIQI 1.0.0-beta.2 更新日志 / Release Notes

版本：`1.0.0-beta.2+4100`  
发布日期：2026-10-02  
应用 ID：`com.psq.siqi`  
支持范围：Android 10–17（API 29–37）

## 中文

Beta2 是一次面向真实设备使用的功能整合版本，重点完善本地模型、Harness 工作流、插件管理、局域网控制和 Android 系统集成。版本号保持不变，支持覆盖安装并保留已有会话、配置和模型文件。

### 1. 模型与 API

- 增加 GPT‑OSS‑20B Q4_K_M 与 Qwen3‑8B Q4_K_M 的 ModelScope 一键下载入口。
- 下载过程支持断点续传、真实文件大小展示、SHA‑256 校验和损坏后重新下载。
- 支持从设备外部导入 GGUF、GGML、BIN、SafeTensors、MNN、ONNX、TFLite 等模型文件。
- 导入模型会进入本地模型选择器，并可在管理界面移除，不影响其他模型。
- 优化 OpenAI、GLM 等 API 的思考能力与思考强度映射。
- 支持多模型映射、默认兜底模型和多模态能力标记。

### 2. DeepSeek Harness 工作流

- 集成并校验 Harness `0.2.0-rc.2` 运行时归档及 SHA‑512 完整性。
- 移除应用内在线插件目录，不再自动聚合或下载未经审核的插件列表。
- 新增“Harness 插件管理”：支持导入 ZIP、TGZ、TAR.GZ、DSH、JSON 插件归档。
- 插件归档统一保存在应用专属目录，可搜索、查看路径和删除。
- 提供 GitHub `dsh-plugin` 主题页与中文插件站外链，用户可自行选择来源。
- 修复“打开本地运行时”按钮：改为查看已下载的运行时文件；Android 无关联应用时显示可复制的本地路径，不再跳转到未启动的固定端口。
- 外部插件默认不执行，界面明确提示用户自行检查来源、许可证和脚本。

### 3. 本地推理与资源管理

- 增加 ZRAM / Swap 状态读取与运行时 spill 缓存统计。
- 支持手动释放已加载模型，帮助用户在长时间使用后回收原生内存。
- 完善模型下载、导入、删除和本地路径管理，保持现有模型可继续调用。
- 继续使用 llama.cpp 端侧推理，并保留多模态、TTS、ASR、OCR 模型管理能力。

### 4. Android 系统集成

- 补充系统相机权限声明，修复首次调用相机时权限缺失导致的失败。
- 支持优先调用 `com.android.camera`，不可用时回退到系统相机选择器。
- 增强 FileProvider 授权和相机启动异常回退处理。
- Release APK 已在 Android 17 小米真机上覆盖安装并成功启动，未产生新的崩溃记录。

### 5. LAN Gateway

- 保留端口 `1158` 的加密局域网网关和本地密令验证。
- 提供网关启停、设备密令轮换、仅 Wi‑Fi、模型列表、远程对话、文件上传、审计日志、最大并发数和请求超时等设置。
- 完成设置页中文化，降低普通用户配置门槛。
- 网关默认关闭，仅建议在可信局域网中使用。

### 6. 实验室与界面

- 移除实验室首页“工作站概览”统计区，减少信息噪音。
- 将 Harness 作为实验室顶部主推功能，提供直接进入入口。
- 保持 Material 3、原生 Android 导航和四语言资源。
- 延续 Beta2 品牌图片在欢迎页、关于页、启动页和 Android 启动图标中的统一使用。

### 7. 构建与验证

- `flutter analyze`：0 issues。
- 已生成 Debug 与 Release APK。
- Release APK：约 39.2 MB，保持 `arm64-v8a` 优化构建。
- Release SHA‑256：`4F5819D7A49310BC5A4319AFD1F612E5D5E31C975A4705F5F79A215E72F1A181`。
- 覆盖安装不会主动删除旧版本会话、API 配置、模型、工作区、MCP 配置、权限审计和工作日志。

### 升级建议

直接安装 Beta2 APK 即可覆盖升级。请勿先卸载旧版本或清除应用数据，否则本地会话、模型索引和配置可能无法保留。外部导入的 Harness 插件应在启用前自行审查来源和许可证。

---

## English

SIQI Beta2 is a device-oriented integration release focused on local models, the Harness workflow, plugin management, LAN control, and Android system integration. The version number remains unchanged and the APK supports in-place upgrades without intentionally deleting existing sessions, settings, or models.

### 1. Models and APIs

- Added one-tap ModelScope downloads for GPT‑OSS‑20B Q4_K_M and Qwen3‑8B Q4_K_M.
- Added resumable downloads, real file-size reporting, SHA‑256 verification, and damaged-file recovery.
- Added external import for GGUF, GGML, BIN, SafeTensors, MNN, ONNX, and TFLite model files.
- Imported models appear in the local model selector and can be removed independently.
- Improved reasoning capability and reasoning-strength mapping for OpenAI- and GLM-compatible APIs.
- Added multi-model mappings, fallback models, and multimodal capability metadata.

### 2. DeepSeek Harness workflow

- Integrated and integrity-checked the Harness `0.2.0-rc.2` runtime archive with SHA‑512 verification.
- Removed the in-app online plugin catalog; the app no longer aggregates or silently downloads unreviewed plugin lists.
- Added Harness plugin management with local ZIP, TGZ, TAR.GZ, DSH, and JSON imports.
- Local archives can be searched, inspected, and deleted from the app-specific directory.
- Added external discovery links for the GitHub `dsh-plugin` topic and the Chinese plugin site.
- Fixed the local runtime action so it opens the downloaded runtime file when Android has a handler, or shows a copyable path instead of opening an unavailable fixed port.
- External plugins are never executed silently and are accompanied by source and license warnings.

### 3. Local inference and resource management

- Added read-only ZRAM / Swap metrics and runtime spill-cache reporting.
- Added a manual model unload action to reclaim native memory after long sessions.
- Improved model download, import, deletion, and local-path management while preserving existing model availability.
- Retained llama.cpp on-device inference and unified multimodal, TTS, ASR, and OCR model management.

### 4. Android integration

- Added the system camera permission declaration, fixing first-use permission failures.
- The app attempts `com.android.camera` first and falls back to the system camera picker when unavailable.
- Improved FileProvider grants and camera-launch error fallback handling.
- Release APK in-place installation and startup were verified on a Xiaomi Android 17 test device without new crash records.

### 5. LAN Gateway

- Retained the encrypted LAN gateway on port `1158` with local device-token authentication.
- Added controls for enable/disable, token rotation, Wi‑Fi-only access, model listing, remote chat, file upload, audit logging, maximum concurrency, and request timeout.
- Localized the settings page into Chinese for easier configuration.
- The gateway remains disabled by default and is intended for trusted local networks.

### 6. Laboratory and interface

- Removed the workstation overview statistics from the Laboratory home page.
- Promoted Harness to the top featured entry in the Laboratory.
- Retained Material 3, native Android navigation behavior, and four-language resources.
- Continued using the supplied brand image consistently across the welcome, about, launch, and Android launcher surfaces.

### 7. Build and verification

- `flutter analyze`: 0 issues.
- Generated both Debug and Release APKs.
- Release APK: approximately 39.2 MB with the optimized `arm64-v8a` build.
- Release SHA‑256: `4F5819D7A49310BC5A4319AFD1F612E5D5E31C975A4705F5F79A215E72F1A181`.
- In-place installation does not intentionally remove sessions, API profiles, models, workspaces, MCP settings, permission audits, or work logs.

### Upgrade notes

Install the Beta2 APK over the previous version. Do not uninstall the old package or clear app data if local conversations, model indexes, and settings must be retained. Review the source and license of every externally imported Harness plugin before enabling it.
