# SIQI

SIQI is a local-first AI workstation for Android. Conversations, settings, API credentials, model records, workspace metadata, permission audits, work logs, and cache indexes stay on the device. Network access is used only for user-configured APIs, model downloads, MCP catalog sync, GitHub import, and explicit access to official resources.

Application ID: `com.psq.siqi`  
Minimum OS: Android 10 (API 29)  
Current target: Android 16 (API 36)  
Flutter: stable 3.38.0 or a compatible newer release  
Source license: MIT License

> The MIT license permits personal and commercial use. Models, MCP services, Harness runtimes, and other third-party resources remain subject to their own licenses and terms.

## Implemented features

### Conversation workbench

- Chat: standard conversations, local history, search, streaming responses, and attachment capability checks.
- Agent: autonomous programming workflows within a selected local workspace. Plans and actions are shown before writes or execution.
- Harness: accepts tested DeepSeek API profiles only and provides review, static-analysis, and test guidance.
- MCP: manages HTTP, SSE, and developer-only stdio servers, tests connections, and lists discovered tools.
- AI team: coordinates up to eight tested API profiles. Members share previous outputs over multiple rounds, then a coordinator produces one synthesis.
- Text-only models disable image, PDF, and audio attachment actions. Multimodal capability is declared explicitly by each profile.

The built-in system prompt prioritizes local processing, evidence, workspace boundaries, minimal coherent changes, non-destructive behavior, and clear remote-data boundaries. It remains editable and supports `{user_name}` and `{current_time}`.

### On-device models

The APK embeds a real `llama.cpp` FFI runtime. GGUF loading and generation run through a worker Isolate, without a placeholder native bridge or remote inference dependency.

The market contains only the following Q4_K_M packages. Every entry has a fixed download URL, byte size, source page, and SHA-256. Downloads resume from partial files and must pass hashing before installation.

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

### Download and integrity workflow

1. Open **Lab → Model market**.
2. Review size, minimum memory, license, and official source.
3. Start the download. Notification permission is requested only for progress notifications; denial does not stop the download.
4. Pause and resume from the `.part` file as needed.
5. SIQI calculates SHA-256 before renaming the completed file. A mismatched partial file is removed and logged.
6. Installed-file checks are cached by path, size, and modification time, avoiding repeated full GGUF scans during UI rebuilds.

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
- SIQI can verify and download the official npm runtime package.
- It can synchronize and manage plugin source archives from the configured catalog.
- The official runtime requires Node.js. The APK does not pretend to embed an incomplete runtime; it can connect to a compatible service started in Termux or on a LAN computer.
- Plugins are downloaded and verified, never auto-executed.

### Multimodal zone

The zone reads total and available device memory. Model plus task peak memory is hard-limited to 60% of total RAM, and remaining memory determines the suggested single-audio duration.

Current verified official packages are:

- MiMo-V2.5-ASR: approximately 32.07 GB of weights;
- MiMo-Audio-7B-Instruct plus Audio Tokenizer: approximately 23.85 GB;
- no verified small quantized TTS/ASR package currently runs on this project’s Android runtime.

A roughly 24 GB or lower device therefore shows these packages as incompatible and blocks downloading. Official source links remain visible. Download becomes available only when a package has a real source, a working Android runtime, and a verified peak below the 60% limit.

### Workspaces and project files

Onboarding can select a workspace. The suggested project location is:

`/storage/emulated/0/Siqi/Projects`

Android 11 and later use the system directory picker and Scoped Storage. SIQI requests neither Root nor all-files access. If the suggested directory is unavailable, the user can choose another directory or deny access without preventing startup.

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

Potential permissions include notifications, microphone, camera, and user-selected media. Workspaces and model directories use system pickers. Root and all-files access are never requested.

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
3. Enter a name, Base URL, model ID, API key, and optional headers.
4. Declare whether the model supports multimodal input.
5. Run **Test connection**. Untested profiles cannot send conversations.

API keys use Android encrypted storage; SQLite stores only non-secret profile data. Requests go only to the endpoint explicitly configured by the user.

### Use an AI team

1. Create at least two tested API profiles.
2. Open **Lab → AI team**.
3. Create a team with up to eight members.
4. Choose one to four collaboration rounds.
5. Enter the task and start.
6. Each member reads the task and previous outputs; the coordinator produces the synthesis.
7. Stop at any time or delete the local collaboration history.

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
- Flutter stable 3.38.0 or a compatible newer version;
- Android Studio;
- Android SDK Platform 36;
- Android SDK Build-Tools 36;
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
C:\Users\Public\flutter-siqi-3.38.0
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

### 4. Build an APK

Build a local arm64 Release APK:

```powershell
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Output:

`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

Install over the existing app without clearing data:

```powershell
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Configure an independent release key in `android/key.properties` before distribution. Without one, the project falls back to debug signing for local Release verification only and is not a store-ready package.

## Verified baseline

- `flutter analyze`: zero issues;
- Android 14-17 / arm64 Xiaomi 10-17 Series: Release upgrade installation succeeded;
- Release version: `1.0.0 (2001)`;
- cold-start Activity completed and the process remained alive;
- APK contains `libllama_cpp.so` and `libomp.so`;
- no Flutter or Dart crash was observed;
- secure lock screen prevented automated visual page traversal; unlock the phone before continued interaction testing.

## Safety and limitations

- SIQI does not bypass the device lock screen, sandbox, SELinux, or Scoped Storage.
- Downloaded MCP or Harness content does not execute unless a developer explicitly configures and starts it.
- The market does not show unverified model downloads.
- Remote destinations are never concealed.
- Agent and Shell features can modify local files; back up important workspaces.
- GitHub OAuth, vendor APIs, MCP services, and mirrors remain subject to their providers’ availability.

## License and project

- Project: <https://github.com/psq0421/SIQI>
- Source: MIT License
- SIQI is an independent open-source project with no commercial affiliation to model vendors, API vendors, or model-hosting platforms.
