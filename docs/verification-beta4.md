# Beta4 验证记录 / Verification record

> Latest LES application results and APK hashes are in the **Android LES integration addendum** below. Earlier sections are historical checks of the pre-integration APK, not the current performance status. 最新应用内成绩见文末；旧段落保留为历史记录。

本记录区分源码测试、APK 启动和性能验收。它不是全功能认证或 MiniCPM 35B 达标报告。
This separates source tests, APK launch checks and performance acceptance. It is neither complete feature certification nor a MiniCPM 35B success report.

## 构建与真机 / Build and device

- 日期 / Date: 2026-10-13–14。
- Flutter 3.47.0 / Dart 3.13.0，本机构建环境；Windows 使用英文项目入口与缓存路径。
- APK: `1.0.0-beta.4`, `versionCode=4300`, Android API 29–37, arm64-v8a。
- Debug: 105,372,742 bytes; SHA-256 `704C2BFEF09B11B996A5DB3DC01913783A34A86DBAB8C4DEE69B2769C16A6397`。
- Release: 41,236,816 bytes; SHA-256 `4361C67F1D276D6941A20A9C298B3265973BEB816B21768C8BE08D48FB5F62A1`。
- 两包签名验证通过，均为当前本机的 Android Debug 证书；Release 是优化构建，不等于生产签名。/ Both signatures verify with the current local Android Debug certificate; optimized Release is not production signing.
- Release 覆盖安装成功；手机 `2206122SC` / `SM8475` / Android SDK 37 正常启动，已有会话和 OSS‑20B 文件仍可见。

| 检查 / Check | 结果 / Result |
| --- | --- |
| 静态分析 / Analysis | 无问题 / clean |
| 自动测试 / Tests | 43 项通过 / 43 passed |
| SQLite 6→7 / Migration | 自动测试通过，真机旧会话可加载 / tests passed; previous sessions loaded |
| 品牌资源 / Branding | 相比本轮开始的 Git revision，logo/icon 无修改 / unchanged from the pre-change revision |
| 默认亮屏 / Default awake | 真机窗口有 `KEEP_SCREEN_ON` |
| 关闭亮屏 / Toggle off | 真机标志清除 / flag cleared |
| 前后台 / Lifecycle | 后台清除，前台恢复 / cleared in background, restored on resume |
| 黑白主题 / Themes | 真机检查；320px 与 1.5x 文本另有 widget tests / device checks plus narrow-layout tests |
| 失败日志 / Failure trace | 未安装 MiniCPM5 请求被拦截；任务仍记录，可打开 `siqi-agent-failures.json` 系统分享界面 / guarded request persisted and share sheet opened |
| JSONL 汇总 / Summary | 合成 fixture 正确报告失败、未完成和坏行；不是设备成绩 / synthetic fixture checked |

真机测试新增了一条只读用途的独立 Agent 测试记录，没有执行文件动作或远程 API 调用；恢复原有浅色主题、亮屏开启、Chat 模式和 OSS‑20B 选择。已启动的 MiniCPM 下载未被取消。
One isolated read-only Agent test was added, without tool execution or remote API requests. Original light theme, awake setting, Chat mode and OSS selection were restored. The existing MiniCPM download was not cancelled.

## OSS‑20B 短回归 / Short regression

原始完成摘要：[JSON](research/benchmarks/beta4-oss20b-sm8475-20261014.json)。来源为 Release 性能实验页面，经 accessibility tree 读取；没有附上逐点 JSONL 采样文件。
The completed summary was captured from the Release performance page via its accessibility tree. Per-sample JSONL is not attached.

- 模型 / Model: GPT‑OSS‑20B Q4_K_M；CPU 4 线程、Q4 KV、batch64/micro32。
- 实际上下文 / Effective context: **2048**；输出上限 / output limit: **256**。
- 解码 / Decode: **2.235959 token/s**，256 个 eval tokens，114,492.254 ms。
- 冷加载 / Cold load: 50,973 ms；整轮 generation wall time 145,410 ms。
- 推理 watchdog 采样峰值 RSS 6,158,696,448 bytes；实验室 5s 采样 RSS/PSS 峰值分别 6,107,271,168 / 6,524,510,208 bytes。
- 完成状态 / Completion: completed；相对实验室默认 decimal 5GB 比较目标，内存验收 / memory verdict: **failed**。

运行期间存在大型模型下载，存储 I/O 不是隔离条件；只跑了这一轮。它说明本次短请求可完整结束，并不能证明长对话 bug 全部消失、128K 下 5 t/s 或 MiniCPM 5GB 达标。`firstVisibleDeltaMs` 当前按首个非空文本或 reasoning delta 计时，不能直接当作用户实际看到正文的 TTFT。
Concurrent downloading affected I/O, and this is a single run. It establishes short-request completion, not full stall elimination, 128K/5 t/s or MiniCPM memory acceptance. The current first-delta counter includes reasoning deltas and is not necessarily user-visible-answer TTFT.

## 未验证 / Not validated

- Debug 的独立真机启动：已覆盖安装并冷启动；已有模型文件保留。
- 全部供应商 API、MCP 服务、长时 ASR、长对话、所有模型/模态组合。
- MiniCPM‑V 4.7 35B LES 已完成独立 CPU 流式探针的打包、逐字节校验和短文本回合；应用内运行时与 5GB 整应用验收仍未完成。
- CI 远端执行、GitHub 推送、Release 发布、论文或上游 PR。

Debug launch is verified. Every API/MCP/modality combination, extended sessions, app-integrated 35B LES/5GB execution, remote CI, publishing and research conclusions remain unvalidated or unpublished.

## Independent LES probe / 独立 LES 探针

`tools/native/minicpm_cpu_probe` is a developer-only Android arm64 executable. It is separate from the packaged llamadart ABI. It packs expert-major files, creates a stripped base GGUF, verifies routed/base tensors byte-for-byte, rejects deliberate corruption, and runs a bounded text-only CPU smoke benchmark. The pinned source is OpenBMB `llama.cpp-omni` revision `0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2` with two marked Android patches: a CPU writable expert-slot buffer and a no-op warning for Apple's `F_NOCACHE` API on Android.

The real SM8475 / Android 17 result is recorded in [beta4-minicpmv47-les-sm8475-20261014.json](research/benchmarks/beta4-minicpmv47-les-sm8475-20261014.json): 8 output tokens, 2K context, CPU mask `f0`, **0.0428 token/s**, standalone probe RSS **2.20 GB**. It is a negative baseline, not a whole-app acceptance result and not evidence for 5 t/s or 5 GB. Temporary packed files and the probe binary were removed from the phone; the two downloaded model artifacts were preserved.

## 2026-10-14 build addendum

The final source changes also make the onboarding flow use the complete safety/workspace system prompt, scroll an opened history session to its newest message, and expose the developer terminal directly from Shell settings. These are source-level checks; they do not change the LES result above.

The rebuilt artifacts are:

| Artifact | Size | SHA-256 | Package metadata |
| --- | ---: | --- | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | 41,236,816 bytes | `4361C67F1D276D6941A20A9C298B3265973BEB816B21768C8BE08D48FB5F62A1` | `com.psq.siqi`, `1.0.0-beta.4`, `4300` |
| `build/app/outputs/flutter-apk/app-debug.apk` | 105,372,742 bytes | `704C2BFEF09B11B996A5DB3DC01913783A34A86DBAB8C4DEE69B2769C16A6397` | `com.psq.siqi`, `1.0.0-beta.4`, `4300` |

Both APKs pass `apksigner verify` (v2). Debug was installed over the existing package with `adb install -r` and cold-launched on the SM8475 reference device; the existing app data and downloaded model artifacts were retained. No GitHub push or Release publication was performed at that historical stage.

### Ten-request acceptance checklist

1. MiniCPM-V 4.7 35B: **partial** — the independent Android LES probe can decode a bounded text request; the production APK still has no bundled LES/projector runtime.
2. 64K stable / 128K target: **partial** — new installs default to 64K and the UI exposes 128K; the planner may lower effective local context and no 64K device acceptance run exists.
3. Multimodal file generation: **partial** — attachments and text/Office/PDF extraction plus workspace file writing exist; native rendering of arbitrary PSD/CAD and “100+ formats” is not claimed.
4. Compatibility targets: **partial** — verified ModelScope artifacts are downloadable where checksums/runtime exist; targets without a verified runtime remain explicitly blocked.
5. CPU/GPU/Hexagon scheduling: **partial** — per-core affinity, Vulkan profiles, ZRAM/pressure telemetry and conservative Hexagon eligibility detection exist; no QNN/HTP delegate is bundled.
6. MNN: **not complete** — the model enum is reserved, but no MNN native ABI/model conversion is shipped; llama.cpp remains the only production local engine.
7. Default system prompt: **complete** — onboarding now persists the full safety, workspace, privacy and verification prompt from `AppSettings`.
8. History tail-first: **complete** — selecting a session schedules a post-layout jump to the latest message.
9. Built-in terminal: **complete** — the existing developer-only terminal is reachable directly from Shell settings and retains dangerous-command confirmation.
10. Harness on local/other APIs: **partial** — Harness API adapters and local task plumbing exist, but full protocol parity across every local backend is not verified.

## Android LES integration addendum — 2026-10-14 / 首轮 64 专家运行时接入（历史包）

### Build / 构建

Optional build flag: `SIQI_LES_RUNTIME=true`. Version remains
`com.psq.siqi` / `1.0.0-beta.4` / `4300`; logo and launcher icons are unchanged.
Release was installed over the previous app and cold-launched successfully
(711 ms Activity launch; this is **not model loading time**). Existing model
artifacts and settings remained available. Neither GitHub nor Releases was updated.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Release APK | 42725163 | `C243E3B266256895255437E343A2588422A57838AA643E66F40DB285C93F54B6` |
| Debug APK | 137122443 | `57B212F0B81B523BB2C4E0ADA3F388D912932551C7040F86265028A67E4897AC` |

Release v2 signature verification passed using the existing local debug
certificate, not a production signing key. `lib/arm64-v8a/libsiqi_les.so` is
present; upstream llama/ggml symbols are hidden and only `siqi_les_*` ABI 1
is exported. ELF load segments have 16KB alignment, but a physical 16KB-page
Android device was not tested. KleidiAI and llama.cpp-omni licenses are bundled
and available through About → Open-source license.

Analysis is clean; normal and LES-flag test configurations each pass **44 tests**.
Native reserved-arena mapping/corruption tests and the repeated opaque-ABI
lifecycle selftest passed on the device.

### Release app measurements / 应用内成绩

Model: the already downloaded MiniCPM-V 4.7 35B-A3B **mix_q3gud_im**, not
Q4_K_M; CPU LES, four adaptive threads, poll=0, Q4_0 K/V, window64, bank128,
prefetch depth4, four I/O workers. The model file SHA is recorded in each run.
The five runs below used **51 actual input tokens**, **2048 context** and
**128 actual output tokens**; storage cache state was uncontrolled.

| Run | All Decode t/s | After 8 warmup tokens t/s | Whole-app sampled RSS peak | Whole-app sampled PSS peak |
| --- | ---: | ---: | ---: | ---: |
| First preparation | 4.275407 | 4.359311 | 5124943872 | 5206456320 |
| 2 | 4.518012 | 4.679393 | 5066371072 | 5147232256 |
| 3 | 4.528410 | 4.615286 | 5197615104 | 5270371328 |
| 4 | 4.489122 | 4.598639 | 5139812352 | 5236803584 |
| 5 | 4.325899 | 4.407801 | 5122056192 | 5219282944 |

All five meet the requested short-input **≥3 t/s Decode** target. Median
whole-decode rate: **4.489122**; median warmed rate: **4.598639**.
They **fail** the earlier decimal-5GB sampled whole-app memory target and
do not establish sustained thermal performance, 64K/128K filled context,
vision performance or every quantization. First preparation plus loading took
71.446 seconds; subsequent cold model loads from the prepared cache took
1.542–1.916 seconds. Whole-generation and prefill time are recorded separately.

Evidence was captured from the Release performance page's accessibility tree;
the full per-sample private JSONL was not attached. See
[`app-first-run.json`](research/benchmarks/20261014-les/app-first-run.json) and
the four `app-repeat-*.json` files. These runs use APK SHA `C3A72561…`, before
the benchmark-control-only update in the final Release package.

The final package also completed a cold model run at **4.725663 t/s** and an
actual runtime-reuse run at **4.477989 t/s**; warmed rates were **4.883051**
and **4.642287**. The latter reports `coldLoad=false` and a reuse-stage time
of 19.23 ms; prefill still takes time and is not skipped. Records:
[`app-final-load.json`](research/benchmarks/20261014-les/app-final-load.json),
[`app-final-reuse.json`](research/benchmarks/20261014-les/app-final-reuse.json).

Manual Stop during an active run produced `status=cancelled` with an explicit
termination reason. After unloading, `dumpsys meminfo` reported app RSS
**261361664 bytes** (255236 KB), rather than retaining the model working set.
See [`app-cancel.json`](research/benchmarks/20261014-les/app-cancel.json).
Original weights and derivative cache were preserved.

### Remaining limits / 未完成项

The eight-request implementation/measurement matrix and all standalone
successes/failures are in [android-les-optimization.md](android-les-optimization.md).
The Adreno hybrid probe is safe with quantized-matmul CPU fallback but slower;
there is no validated QNN/HTP path on this device. The new 35B library is
text-only and rejects image/audio input. The Q4_K_M 35B card remains blocked.
Earlier **0.0428 t/s**, **2.917046 t/s**, timeouts and Vulkan crashes remain
in the historical evidence rather than being replaced by successful runs.

## Historical 56-expert package — 2026-10-14 / 历史 56 专家开发包

This section supersedes earlier package hashes, not the historical benchmark
measurements. Version and branding remain unchanged: `com.psq.siqi`,
`1.0.0-beta.4`, `4300`, arm64-v8a.
本节曾为最终包信息，现属于历史阶段；后续包信息见本文件末尾，成绩保留用于追溯。

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Release APK | 42728595 | `4CC9954F1783B6E32741D31BE5726ECE4F5B24FB6F856135D8C34D66CC3D98F3` |
| Debug APK | 137117825 | `8FD064F6E85581293E120A5F15F6D6D73DAA4F29509CCB3B84FD6EFA22C114C6` |

Both verify with APK v2 using the existing local debug certificate; production
release-key signing remains outside this development delivery. The Release
native library SHA is
`86AA7225F01738A7EFC7221BD0C21A4D878E49B1A58A91E181A520A2B5BEB1EB`.
Only nine `siqi_les_*` entry points are public; no public llama/ggml symbols.
ELF LOAD alignment is 0x4000, not proof of a physical 16KB-page device test.

Analysis is clean. Normal and LES-flag suites each pass **47 tests**, including
the 56-slot default and concurrent model-release lifecycle checks.
Debug and Release were installed over the existing package and cold-launched:
Activity times **5021 ms / 836 ms**, not model load or render-ready times.
The final Release Activity is resumed in the foreground.

原始 15,503,944,896 字节权重在覆盖安装后重新计算 SHA-256，仍为
`51e32201f0ddaf87dbb9689ceef9e3aa1a1543a1366706aa2abbf3aabb34df6b`。
视觉组件仍存在；没有清空应用数据。仅删除本轮自行生成的两个实验重排副本：
`/data/local/tmp/siqi-les-native` 和
`/storage/emulated/0/Android/data/com.psq.siqi/cache/siqi-les-bench/packed`，
释放约 31GB（约 29GiB），这些副本可重建。正式私有 LES 缓存、模型、会话和
配置保留，未推送 GitHub 或发布 Release。

### Repetitions and raw journal / 复测与原始采样

The **final Release APK** also completed one 56-slot short round at
**4.325687 t/s** whole Decode / **4.413245 t/s** after eight warmup tokens.
It reports **51 input / 128 output tokens**, `fullPromptEvaluated=true`,
2K effective context and unchanged history. Sampled RSS/PSS peaks are
**4860534784 / 4861703168 bytes**; this fresh process's VmHWM is
**4919934976 bytes**. This does not undo the earlier lifetime-high-water
overshoot or establish long-context acceptance. Evidence:
[`app-final-window56.json`](research/benchmarks/20261014-les/app-final-window56.json).

Five 56-slot Release runs decode **128 tokens** at **4.235781–4.822780 t/s**,
median **4.423384**, with **51 input tokens / 2048 context**. Their sampled
whole-app RSS/PSS is below decimal 5GB, but lifetime VmHWM reached
**5002383360 bytes**: no strict ceiling, filled long context or vision claim.
See `app-window56-1.json` through `app-window56-5.json` in
[the evidence directory](research/benchmarks/20261014-les/); their test APK is
`E43E77A8…`, with explicit 56-slot tuning before it became the production default.

The complete device journal, including per-sample memory/thermal/fault data,
was captured byte-exactly as
[`app-journal-before-final-20261014.jsonl`](research/benchmarks/20261014-les/app-journal-before-final-20261014.jsonl)
(245314 bytes, SHA-256
`C42D157A22C3B6046E059225179B6F9BC05D56D0A24FFD5D40273C1AFAAC74A1`).
Its historical prefix has **two malformed lines and one unfinished run** from
before the journal-serialization fix; they are retained and the summary tool
reports them. Successful LES repetitions do not replace those old failures.
The journal contains counters and prompt hashes, not prompt bodies or API keys.

The old ten-minute document experiment was actually interrupted by its
deadline: [`app-document-timeout-10m.json`](research/benchmarks/20261014-les/app-document-timeout-10m.json).
It has no completed prefill or Decode result and is **not a successful long
test**. Document deadlines are now 60 minutes, with visible and journaled
evaluated/total token progress; built-in short tests retain ten minutes.
Timeouts still safely cancel/unload. The independent fully evaluated **4K /
2.107921 t/s** failure remains valid; 64K/128K populated acceptance is open.

## Current cooperative-barrier package — 2026-10-14 / 当前协作等待开发包

This is the current package, superseding historical APK hashes above without
changing their recorded benchmark results. Version/branding stay unchanged:
`com.psq.siqi`, `1.0.0-beta.4`, build `4300`, Android API 29–37, arm64-v8a.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Release APK | 42740615 | `31A1C69E4BAA883DEBE2A9BB380FDF25728AE887C15723A697170E4F17B20F65` |
| Debug APK | 137119320 | `9C865484D98E2E9B854535344F1AFF3B510E28E798B7068FC960982FA7F1F935` |

Both verify with APK v2 using the existing local debug certificate, **not a
production release key**. Both were overlaid and cold-launched on the device:
Debug Activity **4546 ms**, Release Activity **777 ms**; these are not model
load times. The current Release is left on the phone. Analysis is clean;
normal and LES-flag configurations each pass **51 tests**. The pinned-source
patches pass apply/reverse checks, and the updated native ABI lifecycle test
passes four iterations on the device.

The APK's LES library SHA is
`F42D1616427052BEA1C9A0D84DA8D66C9AFB6BE74F0ED6B2D4974485AEF4E324`.
It exposes nine `siqi_les_*` C entry points and no public llama/ggml symbols;
standard C++ weak RTTI/vtable symbols are also present. ELF LOAD alignment is
0x4000; a physical 16KB-page device was not tested.

The first thread sweep before cooperative barriers reached three variants
but failed with native idle timeout in the eight-thread candidate. Cancellation
completed without force-stopping the app. Its full journal remains in
[`app-journal-before-cooperative-barrier-20261014.jsonl`](research/benchmarks/20261014-les/app-journal-before-cooperative-barrier-20261014.jsonl),
SHA-256 `D965EDFD582C1A9667D766E488F4776B2B9F11856B4F686132291F67F0FEB023`.
The historical malformed prefix is not removed.

The current sweep completes all four profiles: CPU4 **3.963881 t/s**, CPU2
**2.983375**, CPU6 **2.820643**, CPU8 **1.233629**. These are 51-input/64-output
diagnostic trials, not independent repetitions. Non-reference token sequences
differ, so quality equivalence and exact numeric reproducibility are not
established. Ordinary chat stays CPU4/E56/P4/micro8; there is no recommendation
to use all cores. See [the optimization report](android-les-optimization.md).

Summary schema 2 separates model/prompt hashes, actual token counts, windows,
backend/mode and cold/reused state. In particular it no longer averages the
short 4.05 t/s and long 2.03 t/s E96 runs into a misleading 3.04 t/s result.
Full 4785-input E56/E96 runs remain **2.075341 / 2.029385 t/s**, both failures
of the long-input ≥3 target; they predate this cooperative-barrier package.
The new barriers do not by themselves establish new long-context acceptance.

## Beta.4 publication snapshot / Beta.4 发版快照（2026-10-14）

The publication packages are the **current cooperative-barrier APKs** above:
Release `31A1C69E…`, Debug `9C865484…`, unchanged version/build 4300.
The user requested stopping further testing and publishing this verified snapshot.
No extra performance run was started for the release preparation.

Four ordinary final-Release repetitions are archived separately; no fifth
completion was confirmed. All use the same mixed-quantized weights,
CPU4/E56/P4/micro8, Q4_0 K/V, **51 actual input tokens / 2048 window /
128 actual outputs**, requested output cap 256, and normal EOS.

| Run | Whole Decode t/s | After 8 warmup tokens t/s | Sampled peak RSS bytes | Sampled peak PSS bytes |
| --- | ---: | ---: | ---: | ---: |
| 1 | 3.898086 | 3.956720 | 4941987840 | 4955038720 |
| 2 | 3.572965 | 3.611325 | 4821487616 | 4911830016 |
| 3 | 3.487520 | 3.526876 | 4795904000 | 4918985728 |
| 4 | 3.723469 | 3.764053 | 4831121408 | 4919616512 |
| Median throughput | **3.648217** | **3.687689** | — | — |

Evidence: `app-cooperative-window56-1.json` through `-4.json` in
[the raw evidence directory](research/benchmarks/20261014-les/). Each record
pins the final Release SHA. Load takes 1723.44–1992.53 ms and prefill
10649.13–12236.83 ms, with existing derivatives. Reported lifetime VmHWM
is 4974264320 bytes in these records. Sampling does not establish a strict
5GB maximum. These four are neither the old E43E five-round experiment nor
the 64-output thread replay; their results must not be pooled.

The final package has no new long-document, filled 64K/128K, vision, Q4_K_M
or physical-cold-storage acceptance. The existing 4785-token failures remain
valid historical evidence. The current device's full new journal was not
recaptured after these four runs; the four archived completion records are
the publication evidence, not a claim of full raw-sample capture.

Release downloads and detailed bilingual notes:
[v1.0.0.Beta.4](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.4),
[CHANGELOG_BETA4.md](../CHANGELOG_BETA4.md).
Both APKs use the existing **local debug signing certificate**, not a
production release key. Checksums are also in
[SHA256SUMS.txt](releases/v1.0.0.Beta.4/SHA256SUMS.txt).
