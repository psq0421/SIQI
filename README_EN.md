# SIQI

> A local-first AI workstation for Android · local models · agents · Harness · MCP · multimodality

[![Version](https://img.shields.io/badge/version-1.0.0.Beta.3-2457D6)](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.3) [![Android](https://img.shields.io/badge/Android-10--17-3DDC84)](https://github.com/psq0421/SIQI/releases) [![License](https://img.shields.io/badge/license-MIT-111827)](LICENSE)

<p align="center"><img src="assets/branding/siqi_brand.jpg" alt="SIQI" width="180" /></p>
<p align="center"><strong>Put models, tools, projects, and workflows on your own device.</strong><br />Sessions and configuration stay local by default; networking is explicit.</p>

[简体中文](README.md) | English

## Beta.3 in one sentence

Beta.3 moves SIQI from a model container toward an observable, schedulable mobile AI workstation. The product context ceiling is now **128K**; per-core CPU discovery and process affinity are available; Android runtime, memory pressure, and NPU candidate detection are reported; and overlay installation was verified on a real Android 17 device.

> **Honest boundary:** 128K is a product configuration ceiling. Actual resident context remains constrained by device memory, model size, and current pressure. Performance records include both `requestedContext` and `effectiveContext` so a setting is never presented as measured KV capacity.

## Why SIQI

The name combines the idea of directing and governing with the idea of a practical instrument. A model should be observable, configurable, switchable, and manageable—not a remote black box. SIQI is designed for research, coding, documents, and model experiments on Android.

## Four-layer work mechanism

![SIQI four-layer work mechanism](docs/images/siqi-workflows.svg)

| Layer | Responsibility | Principle |
| --- | --- | --- |
| Interaction | Chat, attachments, voice, OCR, model switching | Capabilities are explicit; unsupported actions are blocked |
| Orchestration | Chat, Agent, Harness, MCP, AI teams | Plan first, authorize actions, audit tool calls |
| Execution | llama.cpp, LiteRT-LM, CPU/GPU/NPU, Isolates | Select a backend from live resources and fail over safely |
| Data & safety | Local database, encrypted secrets, workspace, logs | Local-first boundaries, path safety, no silent execution |

![SIQI local-first architecture](docs/images/siqi-architecture.svg)

## Core capabilities

- **Chat:** history search, streaming, reasoning effort, remote APIs, and local model switching.
- **Agent:** plan, modify, run, and review within a selected workspace; writes are visible and reversible.
- **Harness:** DeepSeek API-powered code review, static checks, and test guidance.
- **MCP:** Streamable HTTP and HTTP+SSE; stdio management in Developer mode.
- **AI teams:** up to eight tested API profiles collaborate over multiple rounds.
- One catalog manages chat, TTS, ASR, and OCR models; cards show source, format, license, and runtime state.
- GGUF models run through llama.cpp FFI in an isolated worker, with resumable downloads and SHA-256 verification.
- Images, PDFs, audio, Office documents, and large text use path-backed or streamed processing.

## CPU / GPU / NPU scheduling

Settings → **CPU and accelerator scheduling** lists every core with architecture and maximum frequency and lets the user choose process affinity:

```text
CPU0–3  Cortex-A510  @ 2.02 GHz
CPU4–6  Cortex-A710  @ 2.75 GHz
CPU7    Cortex-X2    @ 3.19 GHz
```

SIQI warns against using only A5xx efficiency cores for large models. Arm v9, Hexagon, and QNN are detected in separate layers. LiteRT-LM NPU selection is attempted only when a verifiable delegate and compatible model are present; GGUF is never mislabeled as NPU inference.

## Permissions, workspaces, and privacy

- Permissions are requested when a feature is first used; denial does not block startup.
- App-specific directories work without Root or user-entered commands.
- API keys use Android encrypted storage; sessions, model records, MCP, permission audits, and work logs stay local.
- Workspace paths, model storage, imports/exports, work logs, and cache are manageable in Settings.

## Install and upgrade

Download from [v1.0.0.Beta.3 Releases](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.3):

| Package | Purpose |
| --- | --- |
| `app-release.apk` | Recommended daily-use package |
| `app-debug.apk` | Development and diagnostics; much larger |

Use Android 10–17 on arm64-v8a and keep enough model storage available. Overlay installation preserves sessions, configuration, and downloaded models. Values above 128K are migrated to the new cap.

## Quick start

1. Set a display name, theme, and workspace on first launch.
2. Download or import a model in Lab and review its license, source, and verification state.
3. Test remote API profiles before sending a conversation.
4. Check the active workspace and proposed writes before entering Agent.
5. Harness plugins are imported and managed, never silently executed.
6. Inspect logs, memory pressure, cache, and the active backend for long-running tasks.

## Known issue and Beta.4 plan

- **Known issue:** GPT‑OSS‑20B may pause unexpectedly while generating a long conversation.
- **Planned fix:** improve the streaming watchdog, KV/paging pressure handling, thread wake-up, and resumable generation, with regression coverage across context sizes and thermal states.

Include device model, quantization, context, GPU setting, and a sanitized work-log summary when reporting it.

## Development build

```bash
flutter pub get
flutter analyze
flutter build apk --debug
flutter build apk --release
```

SIQI uses Flutter stable, Riverpod, SQLite, and llama.cpp FFI. Native runtimes and model files retain their own licenses. Redact API keys, private files, and full conversation text before filing an issue.

## License and feedback

SIQI source code is MIT-licensed. Models, MCP services, Harness runtimes, and other third-party components do not automatically inherit this license; follow each project's terms.

- Issues: <https://github.com/psq0421/SIQI/issues>
- Discussions: <https://github.com/psq0421/SIQI/discussions>
- Repository: <https://github.com/psq0421/SIQI>
