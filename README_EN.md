# SIQI

SIQI is a local-first AI workstation for Android. Conversations, settings, API credentials, model records, workspace metadata, permission audits, work logs, and cache indexes stay on the device. Network access is used only for user-configured APIs, model downloads, MCP catalog sync, GitHub import, and explicit access to official resources.

Application ID: `com.psq.siqi`  
Minimum OS: Android 10 (API 29)  
Current target: Android 17 (API 37)  
Flutter: stable 3.47.0 or a compatible newer release  
Current version: `1.0.0-beta.1+4006`  
Source license: MIT License

> The MIT license permits personal and commercial use. Models, MCP services, Harness runtimes, and other third-party resources remain subject to their own licenses and terms.

### Beta1 (build 4006)

- Preserves every Alpha3 feature and interaction while standardizing the release package on arm64-v8a, the architecture with the complete bundled on-device inference runtime.
- Compresses bundled llama.cpp, ONNX Runtime, and Sherpa-ONNX native libraries. Android extracts them at installation time without changing inference output or model compatibility.
- Removes an unused code-generation chain and redundant direct dependencies to simplify dependency resolution and builds.
- The Release APK drops from Alpha3's 247.5 MB to 39.2 MiB, an approximately 84.2% reduction. Debug remains much larger because it retains debugging symbols and development runtimes.

### Alpha3 (build 4005)

- A fresh install creates app-specific `Projects`, `Models`, `Exports`, `Logs`, and `Cache` directories and initializes workspace/model paths to locations that are immediately writable, fixing the first-run false “folder not writable” result.
- Permissions now include legacy file read/write and optional all-files access. The latter opens Android's dedicated settings page only after an explicit user action; it is never forced at startup. Root remains unsupported.
- The physical-memory guard for local inference, TTS, and ASR is raised from 60% to 85%.
- One API-key profile can expose multiple model mappings and now supports notes, a fallback model, endpoint, custom headers, and optional input/output token pricing.

## Implemented features

### Conversation workbench

- Chat: standard conversations, local history, search, streaming responses, and attachment capability checks.
- Agent: an autonomous programming loop within a selected local workspace. Plans and actions are shown before writes or execution; real results can be reviewed, continued, or undone from per-run snapshots.
- Harness: accepts only tested DeepSeek API profiles with a stored key and provides review, static-analysis, and test guidance.
- MCP: defaults to Streamable HTTP, supports legacy HTTP+SSE and developer-only stdio, and provides connection tests, tool discovery, and per-call approval.
- AI team: coordinates up to eight tested API profiles. Members share previous outputs over multiple rounds, then a coordinator produces one synthesis.
- Text-only models disable image, PDF, and audio attachment actions. Multimodal capability is declared explicitly by each profile.

The built-in system prompt prioritizes local processing, evidence, workspace boundaries, minimal coherent changes, non-destructive behavior, and clear remote-data boundaries. It remains editable and supports `{user_name}` and `{current_time}`.

### On-device models

The APK embeds a real `llama.cpp` FFI runtime. GGUF loading and generation run through a worker Isolate, without a placeholder native bridge or remote inference dependency. Mobile resource planning enforces a hard 85% physical-memory ceiling and shrinks context when necessary. Visual inputs are resized to a 1024 px long edge off the UI isolate, while local output is capped by model size so a remote 256K setting cannot freeze a phone-sized workload.

The following chat models provide Q4_K_M artifacts that the current APK can execute directly. Every entry has a fixed download URL, real byte size, source page, and SHA-256. Downloads resume from partial files and must pass hashing before installation.

| Model | Size | Suggested minimum RAM | Source |
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

Model cards disclose licenses. Hunyuan packages are subject to the Tencent Hunyuan Community License; Qwen and Gemma entries follow the licenses shown on their respective model cards. A changed source or checksum mismatch prevents installation.

### Unified model task catalog

Model Market now manages chat, TTS, ASR, and OCR tasks in one catalog. Every entry has one explicit runtime state:

- **Runnable on device**: the APK contains a native runtime that understands the model artifacts;
- **Official files only**: SIQI can download and verify official files, but the bundled Android FFI cannot execute their current format;
- **Awaiting compatible artifacts**: the compatibility target and official information remain visible, without a download action that is known to fail.

The expanded catalog includes:

| Category | Models |
|---|---|
| Chat | openPangu 2.0 7B, BlueLM 3.5 Nano, MiMo 3B, AndesGPT, plus the existing Hunyuan, Gemma 4, and Qwen3.5 families |
| TTS | Supertonic 3, MOSS-TTS-Nano, Soprano-1.1-80M, Qwen3.5-TTS, Pangu-TTS |
| ASR | Qwen3-ASR-1.7B, Qwen3.5-ASR, OctoASR, Moonshine, Pangu-ASR |
| OCR | PP-OCRv6 Tiny, XCurOS-OCR, GLM-OCR, Qwen3.5-Vision, Pangu-Vision |

Supertonic 3 uses `sherpa-onnx` FFI and a mainland-accessible ModelScope source, so it can synthesize speech locally. MOSS-TTS-Nano, Qwen3-ASR-1.7B, and GLM-OCR have verified official-file management, but their current official formats are not directly executable by the bundled FFI. Models without published, verifiable artifacts remain compatibility targets and are never presented as runnable downloads.

### Download and integrity workflow

1. Open **Lab → Model market**.
2. Review size, minimum memory, license, and official source.
3. Start the download. Every artifact currently offered for download uses a ModelScope mainland CDN endpoint. Notification permission is requested only for progress notifications; denial does not stop the download.
4. Pause and resume from the `.part` file as needed.
5. SIQI calculates SHA-256 before renaming the completed file. A mismatched partial file is removed and logged.
6. Successful verification time is persisted. An unchanged file is trusted for 30 days; a modified or expired file is hashed again, avoiding a full GGUF scan on every cold start.

### MCP store and management

**Lab → MCP store** reads the public ModelScope MCP catalog and provides:

- paginated sync, SQLite caching, and offline search;
- filtering by name, author, or description;
- links to official details;
- one-tap import for entries exposing a public HTTP/SSE hosted endpoint;
- connection testing and tool discovery after import;
- local work logs for sync and import operations.

ModelScope may require a browser WAF security check. SIQI validates that the response is JSON. It never stores challenge HTML as catalog data and never erases a previous cache after such a response. The toolbar can open the official catalog when browser verification is necessary.

Regular users can configure URL-based MCP services only. stdio and command-based MCP settings appear only after Developer mode is enabled. Downloaded or imported third-party content never runs silently.

### DeepSeek Harness

- Harness mode uses DeepSeek API profiles only.
- A profile must pass a connection test first.
- SIQI can verify and download official npm runtime package `0.1.1-rc.2`.
- It can synchronize and manage plugin source archives from the configured catalog.
- The official runtime requires Node.js. The APK does not pretend to embed an incomplete runtime; it can connect to a compatible service started in Termux or on a LAN computer.
- Plugins are downloaded and verified, never auto-executed.

### TTS, ASR, and OCR

SIQI integrates the real `sherpa_onnx 1.13.6` FFI runtime and exposes separate TTS, ASR, and OCR services under `lib/core/services/`. Services receive a model definition, allowing model switching while sharing integrity, runtime, and memory checks.

- **TTS**: Supertonic 3 generates a local WAV in a worker Isolate. Long-press an AI reply to choose **Read aloud**, and stop playback when needed.
- **ASR**: the composer includes a recording button. Microphone permission is requested only after an explicit recording action. One audio item may be up to 180 minutes and is decoded in 30-second chunks without loading the full recording into Dart memory.
- **Audio decoding**: Android MediaCodec converts MP3, M4A, AAC, FLAC, OGG, OPUS, AMR, 3GP, and MP4 inputs into a path-backed mono PCM WAV.
- **OCR**: the composer can select an image from the gallery or screenshots. OCR reuses an installed Qwen3.5 or Gemma 4 vision model and projector, then inserts recognized text into the composer.
- **Memory guard**: model artifacts plus working buffers must remain below 85% of physical memory; unsafe tasks are rejected before loading.

The multimodal page reports total and available memory, the real runtime state of each model, and a suggested maximum audio duration. A model is shown as runnable only when it has a real source, complete verification metadata, a compatible Android runtime, and a safe memory peak.

### Source file formats

Chat attachments, OCR, and ASR share one file-reading layer:

- code and scripts: Dart, Kotlin, Java, Python, JavaScript, TypeScript, Go, Rust, C/C++, Swift, Objective-C, C#, F#, Scala, Ruby, PHP, Lua, R, Perl, SQL, Shell, PowerShell, Gradle, Groovy, Vue, Svelte, and more;
- text and configuration: TXT, Markdown, RST, TeX, JSON/JSONL, YAML, TOML, XML, HTML, CSS, CSV/TSV, INI, Properties, ENV, and logs;
- office and electronic documents: PDF, DOCX, PPTX, XLSX, ODT, ODS, ODP, EPUB, RTF;
- images: PNG, JPEG, WebP, GIF, BMP, TIFF, HEIC, HEIF;
- audio: WAV, MP3, M4A, AAC, FLAC, OGG, OPUS, AMR, 3GP, MP4.

Text files larger than 5 MB and long audio use streamed or path-backed processing. Office and OpenDocument files are extracted entry by entry, while image normalization runs off the UI thread to avoid large main-isolate copies.

### Workspaces and project files

First launch automatically creates and uses an app-specific workspace that needs no storage permission. A typical path is:

`/storage/emulated/0/Android/data/com.psq.siqi/files/Projects`

Android 11 and later enforce Scoped Storage. The system picker can still change the location. If direct access to an arbitrary shared-storage workspace is genuinely required, the user can explicitly enable **All files access** under Permissions and privacy. It is not required for startup, and denial does not block the app.

Agent file operations enforce:

- reads, writes, directory creation, and indexing inside the active workspace;
- rejection of `..` traversal and resolved paths outside that boundary;
- visible actions, targets, and reasons before writes;
- confirmation for modifications by default;
- no claim that an unexecuted change or test succeeded.

The suggested generated-project location can be changed under **Settings → Data and storage**.

### Developer Shell

Regular users never see the Shell and are never asked to type commands. After **Settings → Developer mode** is enabled, a complete Shell queue appears in Lab.

It provides command history, a queue, working-directory handling, timeouts, output limits, and work logs. Execution uses Android’s Linux user space:

- system `sh -c`;
- optional Termux or Shizuku environments;
- `su`, `sudo`, Magisk, privilege escalation, and system-partition writes are blocked;
- dangerous commands require a second confirmation;
- each task has a two-minute default timeout;
- stdout and stderr are decoded as UTF-8 and capped at 1 MiB each.

SIQI never requests Root. Android is Linux-based, but the app remains constrained by its UID sandbox, SELinux, and Scoped Storage.

### Permissions and privacy

Permissions are requested when their corresponding feature is first used, never as a startup bundle. Denial does not crash or block the application.

**Settings → Permissions and privacy** shows:

- permission name;
- triggering feature;
- detailed purpose;
- request time and result;
- locally stored audit entries that the user can delete.

Potential permissions include notifications, microphone, camera, selected media, legacy Android file access, and user-initiated all-files access. Workspace and model storage default to app-specific directories that need no storage permission. Root is never requested; all-files access is an advanced optional capability subject to app-store policy restrictions.

### Work logs and cache

**Settings → Logs and cache** can:

- show model, permission, Shell, MCP, Harness, Agent, and AI-team logs;
- clear work logs;
- calculate app cache size;
- remove reproducible caches without deleting conversations, API profiles, or installed models.

## User guide

### First launch

1. Read the MIT license, privacy boundary, and independent-project notice.
2. Choose a display name.
3. Select light, dark, or system theme.
4. Select a workspace or skip it.
5. Grant permissions only when a feature actually needs them.

The interface follows Material 3 and native Android navigation, colors, touch targets, back behavior, and system motion. Surfaces use a consistent 12 px radius. There are no custom backgrounds, liquid-glass effects, elaborate motion mode, or forced high-refresh behavior.

### Configure a remote API

1. Open **Settings → API profiles**.
2. Pick a vendor template or a compatible format.
3. Enter the provider name, notes, endpoint, API key, and optional headers.
4. Set a fallback model. If the key exposes several models, add one mapping per line as `display name = upstream model ID`.
5. Declare multimodal support and optionally enter currency plus input/output prices per million tokens.
6. Run **Test connection**. The test uses the fallback model, and untested profiles cannot send conversations.

API keys use Android encrypted storage; SQLite stores only non-secret profile data. Requests go only to the endpoint explicitly configured by the user.

### Use an AI team

1. Create at least two tested API profiles.
2. Open **Lab → AI team**.
3. Create a team with up to eight members.
4. Choose one to four collaboration rounds.
5. Enter the task and start.
6. Each member reads the task and previous outputs; the coordinator produces the synthesis.
7. Stop at any time or delete the local collaboration history.

### Use local speech and OCR

1. Open **Lab → Model Market** and filter by **Text to speech**, **Speech to text**, or **OCR**.
2. Only entries marked as having a bundled on-device runtime can execute directly. An **official files only** entry is never passed to an incompatible runtime.
3. After installing Supertonic 3, long-press any AI reply and select **Read aloud**.
4. After installing a compatible ASR model, tap the microphone beside the composer to record, then tap again to stop and transcribe.
5. After installing a Qwen3.5 or Gemma 4 model with its vision projector, tap the image-recognition button and select a gallery image or screenshot.
6. Recording, transcription, OCR, and speech synthesis remain local. A remote request occurs only if the user later sends composer content through a remote chat model.

## Local data layout

- `shared_preferences`: lightweight settings;
- `sqflite`: conversations, messages, profiles, model records, MCP, permission audits, work logs, and teams;
- `flutter_secure_storage`: API keys and other credentials;
- app support directory: default model and reproducible cache storage;
- user-authorized directories: workspace and exported files.

A `.siqi` export can contain sessions and code files. `.siji_config` configuration exports always redact API keys. Import only files from trusted sources.

## Windows Flutter setup

### 1. Install dependencies

Install:

- Git for Windows;
- Flutter stable 3.47.0 or a compatible newer version;
- Android Studio;
- Android SDK Platform 37;
- Android SDK Build-Tools 37;
- Android SDK Command-line Tools;
- Android NDK `29.0.14206865`;
- CMake 3.22.1;
- JDK 17, including Android Studio’s bundled JBR.

Add Flutter `bin` to PATH, then run:

```powershell
flutter doctor -v
flutter doctor --android-licenses
```

Make sure Android toolchain and Android Studio checks pass.

### 2. Open the project

1. In Android Studio, choose **Open** and select the repository root, not only `android/`.
2. Install the Flutter and Dart plugins.
3. Wait for `pub get` and Gradle Sync.
4. Run `flutter gen-l10n`.
5. Run `flutter analyze` and resolve every issue.

If a non-ASCII Windows user name, OneDrive, or a long project path breaks CMake/Ninja, create ASCII path entries for the project, Flutter, SDK, and Pub Cache. The verified environment uses:

```text
C:\Users\Public\siqi-build-workspace
C:\Users\Public\flutter-siqi-3.47.0
C:\Users\Public\siqi-pub-cache
C:\Users\Public\android-sdk
```

These can be directory junctions; the original project does not need to be moved or deleted.

### 3. USB debugging

1. Enable Developer options and USB debugging on the phone.
2. Connect USB and approve the computer fingerprint.
3. Run `flutter devices`.
4. Select the phone in Android Studio and press Run.
5. Use Profile, rather than Debug frame rate, for performance checks:

```powershell
flutter run --profile -d <device-id>
```

### 4. Build Debug and Release APKs

Run the shared checks first:

```powershell
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
```

Build an attachable Debug APK:

```powershell
flutter build apk --debug
adb install -r -t build/app/outputs/flutter-apk/app-debug.apk
```

Build the final Release APK:

```powershell
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

The `-r` option preserves conversations, settings, and downloaded models. Do not uninstall or clear app data for upgrade verification.

For an arm64-only distribution build, additionally run:

```powershell
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Configure an independent release key in `android/key.properties` before distribution. Without one, the project falls back to debug signing for local Release verification only and is not a store-ready package.

## Verified baseline

- `flutter analyze`: zero issues;
- Android 17 / API 37 / arm64 device (`2206122SC`): both Debug and Release upgrade installations succeeded without clearing app data;
- current version: `1.0.0-beta.1 (4006)`;
- the Qwen3.5-4B Q4_K_M model and vision projector resumed to completion and passed SHA-256 verification;
- real on-device text inference succeeded, warm requests reuse the loaded engine, and Stop prevents concurrent generation on that engine;
- a real image input was normalized to a 1024 px long edge and the 4B model streamed an answer consistent with the screenshot;
- the Release process remains alive after a cold start, its manifest is not debuggable, and the APK passed 16 KB page and ZIP alignment verification;
- APK contains `libllama.so`, `libllamadart.so`, `libggml*.so`, `libmtmd.so`, `libsherpa-onnx-c-api.so`, and `libonnxruntime.so` for text, Vulkan/CPU, multimodal projector, and speech runtimes;
- representative Supertonic 3, Qwen3-ASR-1.7B, MOSS-TTS-Nano, and GLM-OCR ModelScope artifact URLs returned HTTP 200;
- no Flutter or Dart crash was observed;
- secure lock screen prevented automated visual page traversal; unlock the phone before continued interaction testing.

## Safety and limitations

- SIQI does not bypass the device lock screen, sandbox, SELinux, or Scoped Storage.
- Downloaded MCP or Harness content does not execute unless a developer explicitly configures and starts it.
- The market does not show unverified model downloads.
- A downloadable official weight is never mislabeled as executable by the current APK; model cards disclose the runtime state.
- Remote destinations are never concealed.
- Agent and Shell features can modify local files; back up important workspaces.
- GitHub OAuth, vendor APIs, MCP services, and mirrors remain subject to their providers’ availability.

## License and project

- Project: <https://github.com/psq0421/SIQI>
- Source: MIT License
- SIQI is an independent open-source project with no commercial affiliation to model vendors, API vendors, or model-hosting platforms.
