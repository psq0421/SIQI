# SIQI

> A local-first AI workstation for Android · local models · agents · Harness · MCP · multimodality

[![Version](https://img.shields.io/badge/pre--release-Beta.4%20%2F%204300-17191E)](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.4) [![Android](https://img.shields.io/badge/Android-10--17-3DDC84)](https://github.com/psq0421/SIQI/releases) [![License](https://img.shields.io/badge/license-MIT-111827)](LICENSE)

<p align="center"><img src="assets/branding/siqi_brand.jpg" alt="SIQI" width="180" /></p>
<p align="center"><strong>Put models, tools, projects, and workflows on your own device.</strong><br />Sessions and configuration stay local by default; networking is explicit.</p>

[简体中文](README.md) | English

## Beta.4: observable and traceable

This Beta is **1.0.0-beta.4 · 4300**. It preserves existing branding, introduces a spacious monochrome interface and default foreground screen-awake policy, records Agent trajectories from the model request onward, and persists benchmark JSONL. Local-model research now prioritizes **MiniCPM, especially MiniCPM‑V 4.7 35B‑A3B**.

[Download Beta.4](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.4) · [Detailed bilingual changelog](CHANGELOG_BETA4.md) · [Research interfaces and acceptance protocol](docs/research-beta4.md). This is a pre-release: the dedicated 35B path is text-only, and long-context / full-multimodal acceptance remains open.

> **Honest boundary:** 128K is a product configuration ceiling. Actual resident context remains constrained by device memory, model size, and current pressure. Performance records include both `requestedContext` and `effectiveContext` so a setting is never presented as measured KV capacity.

## Why SIQI

The name combines the idea of directing and governing with the idea of a practical instrument. A model should be observable, configurable, switchable, and manageable—not a remote black box. SIQI is designed for research, coding, documents, and model experiments on Android.

## Four-layer work mechanism

![SIQI four-layer work mechanism](docs/images/siqi-workflows.svg)

| Layer | Responsibility | Principle |
| --- | --- | --- |
| Interaction | Chat, attachments, voice, OCR, model switching | Capabilities are explicit; unsupported actions are blocked |
| Orchestration | Chat, Agent, Harness, MCP, AI teams | Plan first, authorize actions, audit tool calls |
| Execution | llama.cpp CPU/Vulkan, dedicated LES text runtime, native speech/OCR engines, Isolates | Explicit runtime compatibility; detecting a chip is not proof of acceleration |
| Data & safety | Local database, encrypted secrets, workspace, logs | Local-first boundaries, path safety, no silent execution |

![SIQI local-first architecture](docs/images/siqi-architecture.svg)

## Core capabilities

- **Chat:** history search, streaming, reasoning effort, remote APIs, and local model switching.
- **Agent:** plan, modify, run, and review within a selected workspace; writes are visible and reversible.
- **Task traces:** SQLite v7 stores instructions, model requests, plans, ordered actions, step results and termination reasons; failure/cancellation/interruption exports are available.
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

SIQI warns against using only A5xx efficiency cores for large models. Arm v9, Hexagon, and QNN are detected separately. These APKs bundle llama.cpp CPU/Vulkan and a dedicated LES text runtime; **they do not turn GGUF into an NPU model**. LES defaults to CPU. Production MNN and QNN/HTP inference remain unimplemented; detection is not an acceleration result.

## MiniCPM: downloading is not runtime acceptance

The catalog covers MiniCPM3/4/4.1/5, MiniCPM‑V 2.6/4.x and MiniCPM‑o with ModelScope direct URLs, sizes, licenses and SHA-256. An `-o` text/vision entry is not full-duplex audio support. Cards distinguish runnable models from runtime adaptation in progress.

The priority 35B‑A3B artifacts are `mix_q3gud_im` and `Q4_K_M`: approximately 15.50/21.17 GB of weights, plus a separate 1.12 GB visual component. Artifact size is not measured resident memory.

**The Beta.4 APKs integrate the mixed-quantized 4.7 35B LES text runtime.** Four final-Release runs on Snapdragon 8+ Gen1 / 12GB / Android 17 achieve **3.49–3.90 token/s** whole Decode (median **3.65**) and **3.53–3.96** after eight warmup tokens, with 51 actual input tokens, a 2K window and 128 outputs per run. This is not a long-context or vision score; weights are `mix_q3gud_im`, not Q4_K_M. Sampled RSS/PSS is below decimal 5GB in all four runs, not a strict ceiling for transient peaks or other workloads. Historical **4.24–4.82** scores and **5.002GB** RSS high-water belong to earlier packages and stay separate. Q4_K_M 35B and vision remain unvalidated; see [optimization and the eight-request checklist](docs/android-les-optimization.md).

First use repacks and byte-verifies experts without changing original weights. Historical first preparation plus load took about 71 seconds; final-package loads from existing derivatives take 1.72–1.99 seconds, not physically cold-storage trials. Allow roughly one additional model-sized storage copy; Settings → Logs and cache clears derivatives separately. Adaptive CPU4, 56-expert windows, Q4 KV, LRU, route prefetch, file mappings and cooperative waits work together. Android can still reclaim mapped pages. The experimental Adreno path is slower and not the default. The early **0.0428 token/s** failure baseline and every timeout remain visible.

**Real long-input acceptance still fails:** historical app evaluation of 4,785 input
tokens in an 8K window, followed by 256 output tokens, yields **2.075 / 2.029
t/s** with 56/96-expert windows; full prefill takes **23.43 / 20.89 minutes**.
A larger expert cache does not solve compute, I/O or sustained thermal costs.
Long input was not retested on the final package. Same-state 4/2/6/8-thread
diagnostics have different non-reference token sequences, not verified quality
equivalence. Summary groups now
separate actual workloads and model-cold/reused states instead of averaging
short answers and long documents together.

## Everyday use and export tutorial

- Settings → Appearance → **Keep screen awake in foreground**: on by default; backgrounding clears the policy. Turning it off restores the system timeout. No wake-lock permission is required.
- Settings → **Logs and cache** → **Agent task traces**: export the latest 100 tasks, or the latest 100 failed/cancelled/interrupted tasks, with a privacy confirmation.
- Agent plans first, then runs approved actions. Out-of-workspace paths and denied writes produce failure records; unfinished tasks become interrupted after restart.
- Settings → **Performance lab**: select an installed, runtime-compatible model and CPU/Vulkan profile, then export JSONL containing device details, artifact checksum, effective context, throughput, RSS/PSS, faults and thermal state.

Events mask common credential forms at write time and bound tool output; file writes record size/checksum rather than duplicate complete code. **Redaction is not guaranteed anonymity**: review instructions, paths and tool output manually. Sharing is user-controlled, never automatically uploaded.

## Permissions, workspaces, and privacy

- Permissions are requested when a feature is first used; denial does not block startup.
- App-specific directories work without Root or user-entered commands.
- API keys use Android encrypted storage; sessions, model records, MCP, permission audits, and work logs stay local.
- Workspace paths, model storage, imports/exports, work logs, and cache are manageable in Settings.

## Install and upgrade

Download from [v1.0.0.Beta.4 Releases](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.4):

| Package | Purpose |
| --- | --- |
| `app-release.apk` | Recommended optimized build, ~40.76 MiB |
| `app-debug.apk` | Development and diagnostics, ~130.77 MiB |
| `SHA256SUMS.txt` | SHA-256 checksums for both packages |

Use Android 10–17 on arm64-v8a; the 35B optimized path additionally requires FP16 / DOTPROD / I8MM. Overlay installation does not intentionally delete sessions, configuration or downloaded models. Values above 128K migrate to the cap. Both packages use the existing local Android Debug certificate: optimized Release is **not production signing**. Export your data before resolving a signature mismatch; do not uninstall blindly.

## Quick start

1. Set a display name, theme, and workspace on first launch.
2. Download or import a model in Lab and review its license, source, and verification state.
3. Test remote API profiles before sending a conversation.
4. Check the active workspace and proposed writes before entering Agent.
5. Harness plugins are imported and managed, never silently executed.
6. Inspect logs, memory pressure, cache, and the active backend for long-running tasks.

## Beta.3 generation-pause remediation boundaries

- One concrete trigger is fixed: Android `SEVERE` indicates throttling and no longer forces cancellation. `CRITICAL` and sustained kernel low-memory pressure still trigger safe cancellation.
- Stream failure or user cancellation preserves visible partial output. An idle timeout reports an explicit error and reason instead of silently discarding content.
- Complete elimination of OSS‑20B long-dialogue stalls is not claimed. Native decode hangs, LMK and long context require dedicated extended regression. Resumable generation and 128K at 5 t/s are not implemented claims.

Include device model, quantization, context, GPU setting, and a sanitized work-log summary when reporting it.

## Development build

```bash
flutter pub get
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build apk --debug --no-pub
flutter build apk --release --no-pub
```

These are ordinary builds. Reproducing the LES-enabled APKs additionally requires
pinned native sources, the patches, `SIQI_LES_SOURCE` and
`--dart-define=SIQI_LES_RUNTIME=true`; see [native build instructions](docs/android-les-optimization.md#reproduction--开发者复现).
Enabling the Dart flag without packaging the native library is not sufficient.

## Beta4 ten-request acceptance (2026-10-14)

The pre-package checklist distinguishes verified product behavior from native
research work that is still being evaluated:

| Request | Status |
| --- | --- |
| MiniCPM-V 4.7 35B | Partial: published LES APKs run the mixed artifact in text-only mode; four final-Release short-input runs exceed 3 token/s. Q4_K_M and vision are not validated. |
| 64K / 128K context | Partial: new installs default to 64K and the UI exposes 128K; local admission can lower the effective window and no 64K device acceptance run exists. |
| Multimodal file generation | Partial: attachments, text/Office/PDF extraction and workspace writing exist; arbitrary PSD/CAD rendering is not claimed. |
| Model compatibility | Partial: verified ModelScope artifacts are downloadable; targets without a verified runtime stay blocked. |
| CPU/GPU/Hexagon | Partial: core affinity, Vulkan profiles, pressure/ZRAM telemetry and Hexagon detection exist; no QNN/HTP delegate is bundled. |
| MNN | Not complete: the runtime enum is reserved; APKs use llamadart/llama.cpp and the dedicated LES runtime. |
| Default system prompt | Complete: onboarding persists the full safety, workspace, privacy and verification prompt. |
| History tail-first | Complete: opening a history session jumps to the newest message. |
| Built-in terminal | Complete: Settings → Shell opens the developer terminal with dangerous-command confirmation. |
| Harness across backends | Partial: API adapters and local task plumbing exist; full parity for every local backend is not verified. |

APK hashes, signature checks and device evidence are recorded in
[`docs/verification-beta4.md`](docs/verification-beta4.md). Package downloads are
in the [Beta.4 Release](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.4).

SIQI uses Flutter stable, Riverpod, SQLite, and llama.cpp FFI. Native runtimes and model files retain their own licenses. Redact API keys, private files, and full conversation text before filing an issue.

Research interfaces now exist in `agent_service.dart`, `local_database.dart` and `performance_lab_page.dart`, with a JSONL summary tool at `tools/research/summarize_runs.dart` and CI checks at `.github/workflows/quality.yml`. Existing Git history is preserved; commit chronology and upstream contributions are never fabricated.

## License and feedback

SIQI source code is MIT-licensed. Models, MCP services, Harness runtimes, and other third-party components do not automatically inherit this license; follow each project's terms.

- Issues: <https://github.com/psq0421/SIQI/issues>
- Discussions: <https://github.com/psq0421/SIQI/discussions>
- Repository: <https://github.com/psq0421/SIQI>
