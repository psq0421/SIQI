# 司器 SIQI

> Android 端侧优先 AI 工作站 · 本地模型 · Agent · Harness · MCP · 多模态

[![Version](https://img.shields.io/badge/version-1.0.0.Beta.3-2457D6)](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.3) [![Android](https://img.shields.io/badge/Android-10--17-3DDC84)](https://github.com/psq0421/SIQI/releases) [![License](https://img.shields.io/badge/license-MIT-111827)](LICENSE)

<p align="center"><img src="assets/branding/siqi_brand.jpg" alt="司器 SIQI" width="180" /></p>
<p align="center"><strong>把模型、工具、项目和工作流，装进自己的设备。</strong><br />会话与配置默认留在本机；联网只在用户明确需要时发生。</p>

中文 | [English](README_EN.md)

## Beta.3 一句话

Beta.3 把 SIQI 从“能聊天的模型容器”推进为可观测、可调度的移动 AI 工作站：上下文产品上限统一为 **128K**，新增逐核心 CPU 识别与亲和性调度，补齐 Android 端运行时、内存压力和 NPU 候选能力检测，并通过真实 Android 17 设备完成覆盖安装验证。

> **诚实边界**：128K 是产品配置上限。大模型的实际驻留上下文仍由设备内存、模型大小和当前压力动态决定；性能记录同时保存 `requestedContext` 与 `effectiveContext`，不把配置值冒充成实际 KV 容量。

## 为什么是司器

“司”代表掌控与调度，“器”代表可使用、可观测的工具。模型不是远程黑盒，而是可以被观察、配置、切换和管理的生产工具。

## 四层工作机制

![SIQI 四层工作机制](docs/images/siqi-workflows.svg)

| 层级 | 负责什么 | 关键原则 |
| --- | --- | --- |
| 交互层 | 对话、附件、语音、OCR、模型切换 | 能力显式展示，空输入和不支持的模态不会误触发 |
| 编排层 | Chat、Agent、Harness、MCP、AI 团队 | 先计划、再授权；工具调用逐次可审计 |
| 执行层 | llama.cpp、LiteRT-LM、CPU/GPU/NPU、Isolate | 按设备实时资源选择后端，失败可回退 |
| 数据与安全层 | 本地数据库、加密密钥、工作区、日志 | 本地优先、边界清晰、拒绝越界和静默执行 |

![SIQI 本地优先架构](docs/images/siqi-architecture.svg)

## 核心能力

- **Chat**：历史搜索、流式输出、思考强度、远程 API 与端侧模型切换。
- **Agent**：在选定工作区内理解需求、规划、修改、运行和复核；写入前展示动作并支持撤销。
- **Harness**：DeepSeek API 驱动的代码审查、静态检查和测试建议。
- **MCP**：Streamable HTTP、HTTP+SSE；开发者模式下可管理 stdio 工具。
- **AI 团队**：最多 8 个已测试云端模型协作，多轮共享上下文并生成汇总。
- 统一管理对话、TTS、ASR、OCR 模型；卡片显示来源、格式、许可证和实际运行状态。
- GGUF 通过 llama.cpp FFI 在独立工作线程中运行，下载支持断点续传和 SHA-256 校验。
- 图片、PDF、音频、Office 文档和大文本采用路径或流式处理，避免复制整份文件到 UI 内存。

## CPU / GPU / NPU 调度

设置 → **CPU 与加速器调度** 可查看每个核心的架构与最高频率，并选择进程亲和性：

```text
CPU0–3  Cortex-A510  @ 2.02 GHz
CPU4–6  Cortex-A710  @ 2.75 GHz
CPU7    Cortex-X2    @ 3.19 GHz
```

系统会提示不建议只使用 A5xx 能效小核运行大模型。Arm v9、Hexagon 和 QNN runtime 分层检测；只有检测到可验证 delegate 且模型格式支持时才尝试 LiteRT-LM NPU，GGUF 不会被虚假标记为 NPU 推理。

## 权限、工作区与隐私

- 权限按功能首次使用申请；拒绝不会阻止启动。
- 默认使用应用专属目录，不需要 Root，也不要求用户输入命令。
- API 密钥使用 Android 加密存储；会话、模型记录、MCP、权限审计和工作日志使用本地数据库。
- 工作区、模型路径、导入导出、工作日志和缓存均可在设置中管理。

## 安装与升级

前往 [v1.0.0.Beta.3 Releases](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.3) 下载：

| 包 | 用途 |
| --- | --- |
| `app-release.apk` | 日常使用，推荐安装 |
| `app-debug.apk` | 开发调试，体积较大 |

适用于 Android 10–17、arm64-v8a。覆盖安装不会主动删除会话、配置或已下载模型；旧版本超过 128K 的上下文设置会自动迁移到 128K。

## 快速上手

1. 首次启动设置昵称、主题和工作区。
2. 在实验室下载或导入模型，查看许可证、来源和校验状态。
3. 远程 API 必须先完成连接测试；未测试配置不能发送对话。
4. 进入 Agent 前确认工作区和拟执行动作。
5. Harness 插件只导入和管理，不会静默执行。
6. 长任务可查看工作日志、内存压力、缓存和当前推理后端。

## 已知问题与 Beta.4 计划

- **已知问题**：GPT‑OSS‑20B 在长对话生成过程中偶发暂停输出。
- **计划修复**：优化流式 watchdog、KV/分页压力处理、线程唤醒与断点续生成，并补充不同上下文和温控状态下的回归测试。

反馈时请提供设备型号、模型量化、上下文、GPU 设置和脱敏工作日志摘要。

## 开发构建

```bash
flutter pub get
flutter analyze
flutter build apk --debug
flutter build apk --release
```

项目使用 Flutter stable、Riverpod、SQLite、llama.cpp FFI；原生运行时和模型文件遵循各自许可证。提交 Issue 前请隐藏 API Key、个人文件内容和完整会话文本。

## 许可证与反馈

司器源码采用 MIT License。模型、MCP 服务、Harness 运行包和其他第三方组件不自动继承本项目许可证，请遵循对应项目条款。

- Issues：<https://github.com/psq0421/SIQI/issues>
- Discussions：<https://github.com/psq0421/SIQI/discussions>
- 项目主页：<https://github.com/psq0421/SIQI>
