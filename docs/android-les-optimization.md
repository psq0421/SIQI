# Android MiniCPM LES optimization / 安卓专家流式优化

## Scope / 适用范围

Target device: Xiaomi 2206122SC, Snapdragon 8+ Gen1 (SM8475), Adreno 730,
Android API 37, 12GB nominal RAM. The measured artifact is
`MiniCPM-V-4_7-35B-A3B-mix_q3gud_im.gguf`, **not Q4_K_M**:

```
bytes  15503944896
sha256 51e32201f0ddaf87dbb9689ceef9e3aa1a1543a1366706aa2abbf3aabb34df6b
runtime OpenBMB/llama.cpp-omni 0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2
```

目标是模型加载后的热 Decode ≥3 token/s。模型权重为混合量化，KV 为 Q4_0；
不能把下面的数字改写成完整 Q4 权重量化、128K 驻留或视觉模式的成绩。
No root, cache-flush privilege, thermal-policy override, system swap changes,
expert pruning, skipped weights or dummy reads were used.

## Mechanism / 工作机制

1. **Artifact preparation:** preserve the original GGUF; pack each layer's
   gate/up/down weights in expert-major order, create a base GGUF and manifest,
   and verify all expert/base tensors byte-for-byte before publishing readiness.
2. **Scheduling:** keep per-layer LRU expert-slot windows and a shared prefill
   bank. Prediction affects prefetch only; actual top-k routes determine the
   weights evaluated. There is no approximation that drops cold experts.
3. **I/O:** four persistent workers prepare upcoming experts. Page-aligned
   read-only `MAP_PRIVATE` mappings replace anonymous expert copies, followed
   by `madvise(WILLNEED)` and page touch. Unsupported layouts fall back to
   `preadv`. Remapping is restricted to a separately reserved mmap arena,
   never malloc memory. File bounds, host visibility and synchronization are
   checked before installation.
4. **Compute:** Q4_0 K/V, Flash Attention, ARM FP16/DOTPROD/I8MM CPU kernels.
   The optional opaque FFI library hides all upstream llama/ggml symbols to
   avoid colliding with the existing llamadart ABI. Native work runs off the UI.

5. **Cooperative Android barriers:** for sleeping (`poll=0`) threadpools,
   retain short spin waits but add a 100µs sleep after a barrier has waited
   more than 250µs (checked every 1024 spins). Idle polling and in-graph barrier
   waiting are different. Every participant and the original atomic/fence
   contract remain mandatory; this does not disable thermal policy or claim
   that additional heterogeneous cores always improve throughput.

热专家池是 **best-effort residency**：LRU 槽位保持映射，但 Android 可以回收干净页。
这不是 `mlock` 锁定内存或永久常驻保证。主要收益来自消除 page cache 与匿名专家
副本的双份占用，不是把 ZRAM 调大。原始模型不修改，衍生缓存需要额外存储空间。

## Measurements / 实测

All five prefetch-depth-4 repetitions used a 59-token prompt, 2048 context,
8 warmup tokens and 64 timed decode tokens, four CPU threads, 64-expert windows
and a 128-slot shared bank. Filesystem cache state was uncontrolled; these are
new-process runs, **not physically cold flash-storage runs**.

| Run | Hot Decode (token/s) | Sampled standalone RSS peak (bytes) |
| --- | ---: | ---: |
| 1 | 3.836788 | 5056073728 |
| 2 | 3.613296 | 5115256832 |
| 3 | 3.537838 | 5135052800 |
| 4 | 3.335030 | 5147389952 |
| 5 | 3.293283 | 5062631424 |

Median **3.537838**, minimum **3.293283**. The earlier no-prefetch fifth run
was **2.917046** and is retained. The original **0.0428 token/s** negative
baseline is also retained. Different profiles/phases are not interchangeable.
These measurements do **not** pass the earlier decimal-5GB whole-app target.

真实 README 1024-token 输入完整预填充耗时 **272019 ms**，该轮仅输出 16 token、
无预热、无预取，Decode **2.577684 token/s**，未达 3。它和热解码的 64-token
计时不是同一口径。非重复仓库文档/代码语料另有来源清单和校验值。

256-token real-document tuning (single runs): ubatch16/bank128 achieved
**3.467175**, ubatch32/bank256 **3.495027**; adaptive threads with sleeping
workers achieved **3.271830**. Big-core-only adaptive scheduling achieved
**3.025345**, while earlier busy-poll big-core runs timed out. This motivates
avoiding forced big-core affinity as the default.

With adaptive threads, poll=0, prefetch4 and ubatch16/bank256, a new real
**1024-token** repository-document test completed every input token in
**220706 ms**. Its eight-token-warmed, **64-token** Decode achieved
**3.111944 token/s** (whole Decode including warmup: **3.034162**).
This is one standalone run, not five app repetitions or a 128K claim.

The **4096-token** version also fully completed. Full prefill took
**1140673 ms** (about 19 minutes), followed by 64-token warmed Decode at
**2.107921 token/s** (including warmup: **2.066116**). It **fails ≥3 t/s**.
Logical mapped byte volume and kernel physical reads are different metrics;
neither indicates that these bytes were all resident simultaneously.
`expertMappingStats` counters are cumulative within the native process;
without a start snapshot they must not be attributed to just the latest
generation or equated with physical storage reads. App `readBytes=null`
means the kernel counter is unavailable, not zero I/O.
This exposes unresolved long-input I/O/compute costs; short-input app success
must not replace or conceal this result.

### Release app: 56-expert window / 应用内 56 专家窗口

Five Release app repetitions use **51 input tokens**, **2048 context**, **128
actual output tokens**, CPU adaptive four threads / poll=0, Q4_0 KV, bank128,
prefetch4. These are not physically cold storage or populated long contexts.
APK SHA: `E43E77A851C2D0373D3447B6362654126888447071E53E386C4C98736AD6DE9B`.

| Run | Whole Decode t/s | After 8 warmup tokens t/s | Sampled app RSS bytes | Sampled app PSS bytes |
| --- | ---: | ---: | ---: | ---: |
| 1 | 4.477685 | 4.579168 | 4894007296 | 4934024192 |
| 2 | 4.423384 | 4.484552 | 4979884032 | 4968827904 |
| 3 | 4.360372 | 4.427597 | 4937019392 | 4922108928 |
| 4 | 4.235781 | 4.301536 | 4922814464 | 4972971008 |
| 5 | 4.822780 | 4.908757 | 4855353344 | 4949673984 |

Median whole Decode **4.423384**, minimum **4.235781**. All five meet the
short-input ≥3 t/s target. Sampled decimal-5GB checks pass, but sampling can
miss transient peaks: lifetime `VmHWM` reached **5002383360 bytes** in run 2
and persisted in later runs. It is not reset by unloading a model, so it is
neither a per-run peak nor proof of a strict 5GB ceiling. The earlier
64-expert failures are retained. Production now defaults to 56; the lab keeps
explicit 64/56 controls. Weight values, routes and experts are not pruned.

Results are [`app-window56-1.json`](research/benchmarks/20261014-les/app-window56-1.json)
through `app-window56-5.json`. First-run packing, source identity, actual
backend and full-prefill boundaries remain the same. A passing short test
does not erase the independent **4096-token / 2.107921 t/s** failure above.

### App full-document follow-up / 应用内完整长文复测

The final 56-slot package (`4CC9954F…`) fully evaluated **4785 input tokens**
in an **8192-token window**, without history fitting or input truncation.
Preparation/load took **1562 ms**; full prefill **1405815 ms** (23.43 minutes).
All **256 output tokens** decoded at **2.075341 t/s**; the eight-token-warmed
rate is **2.074414 t/s**. This **fails ≥3**, corroborating rather than hiding
the earlier standalone 4K result.

Sampled whole-app RSS/PSS peaks are **4905697280 / 5038728192 bytes**:
RSS alone is below decimal 5GB, but PSS fails that comparison. The LES runtime
does not cancel at this arbitrary comparison target. Kernel critical pressure
and thermal protection remain active.

Evidence:
[`app-real-long4785-window56.json`](research/benchmarks/20261014-les/app-real-long4785-window56.json),
[`app-journal-after-long56-20261014.jsonl`](research/benchmarks/20261014-les/app-journal-after-long56-20261014.jsonl).
The journal contains **75 prefill progress events**, **308 samples** and
a completed event for run `1791951498064269`; its older malformed prefix is
retained. The selected public repository document prefix is
[`real-document-prefix.txt`](research/benchmarks/20261014-les/real-document-prefix.txt),
18332 bytes, SHA-256 `2768623d18ed22d1f3c6ed926424a14b032c38c4c1416edeb02d4c37f0c64af2`.
It is an input workload, not held-out quantization-quality evidence.

The lab additionally supports 96-slot/P4/P1/micro16 experiments. In one
**short 51-token** P1/micro16 run, 96 slots yielded **4.051767 t/s** with
sampled RSS/PSS **5368352768 / 5449460736 bytes**. This is slower than the
five 56-slot short runs and does not justify changing the default yet.
That experimental APK is `F07058F2…`; actual microbatch/prefetch settings are
recorded and changing either invalidates runtime reuse.

### Larger-window long-input result / 扩大专家窗口的长文结果

The same **4785-token** document was fully evaluated by the 96-slot/P1/micro16
Release (`F07058F2…`) in an 8192-token window. Preparation/load: **1678 ms**;
full prefill: **1253476 ms** (20.89 minutes); **256 output tokens**:
whole Decode **2.029385 t/s**, after eight warmup tokens **2.030385 t/s**.
No history reduction or prompt truncation occurred. Sampled whole-app
RSS/PSS peaks: **5612523520 / 5699133440 bytes**.

扩大窗口未使长文解码达到 3 t/s，反而增加内存；不能据此更改生产默认值。
原始完整日志包含成功结束及全过程采样，历史坏行照常保留：
[`app-real-long4785-window96-prefetch1.json`](research/benchmarks/20261014-les/app-real-long4785-window96-prefetch1.json),
[`app-journal-after-long96-20261014.jsonl`](research/benchmarks/20261014-les/app-journal-after-long96-20261014.jsonl)
(SHA-256 `45937374af7aeb6ef635db3874b1aeddc0d8b27968dfcf5f9995e7dea18c4c7d`).

### Same-state thread diagnostics / 同状态线程诊断

The lab-only `LES CPU4/2/6/8 / KV4 / E56 / state replay` profile evaluates a
real input once, snapshots complete KV/recurrent/logit state in memory, then
restores it before each deterministic 64-token thread trial. It records all
four configurations, actual allowed cores, per-token times, mapping deltas,
available sysfs frequency readings and token-sequence equality. Missing sysfs
permission is `null`, not a fabricated frequency. Primary performance is the
four-thread baseline, never the fastest candidate selected after the fact.

This experiment does **not** reset expert LRU/page-cache state and has fixed
order 4/2/6/8. It is exploratory, not four independent repetitions or a fair
randomized thermal comparison. Its bounded state snapshot is diagnostic-only;
ordinary chat does not allocate it. Normal inference remains CPU4/E56/P4/micro8.

The first pre-barrier-patch sweep reached three variant-completion events but
the eight-thread candidate triggered a five-minute idle timeout. Cancellation
returned normally; unreported candidate throughput is **unknown**, not zero
or a valid score. Evidence:
[`app-thread-sweep-before-barrier-timeout.json`](research/benchmarks/20261014-les/app-thread-sweep-before-barrier-timeout.json).
Later builds journal each completed variant immediately so a failed final
candidate cannot erase already-completed measurements.

The cooperative-barrier short-input sweep completed all variants:

| Requested threads | Whole Decode t/s | After 8 warmup tokens t/s | Same token sequence as baseline |
| --- | ---: | ---: | --- |
| 4 | 3.963881 | 4.082209 | Yes (reference) |
| 2 | 2.983375 | 3.035606 | No |
| 6 | 2.820643 | 2.882873 | No |
| 8 | 1.233629 | 1.195850 | No |

Evidence: [`app-thread-sweep-cooperative-short.json`](research/benchmarks/20261014-les/app-thread-sweep-cooperative-short.json),
Release SHA `31A1C69E…`. All use 51 actual input tokens and at most 64 outputs,
not the earlier 128-token five-run protocol. Eight threads now finish, but
are not faster. During this run the big-core sysfs frequency cap fell to
1.40–1.44 GHz. System background activity and file-cache order were not
controlled. This is not proof of temperature being the sole cause.

不同线程数的输出 token 序列不一致：吞吐数据保留，但不能视为品质等价或严格
数值复现。后续需同线程重复回放控制、首个差异位置及 logits 误差检查，区分
浮点归约顺序与状态回放兼容性。没有据此把低线程或全核配置推广为默认。

## Eight-request checklist / 八项验收

### Actual publication package / 实际发布包

The cooperative-barrier final Release (`31A1C69E…`) completed **four** ordinary
CPU4/E56/P4/micro8 runs, each 51 actual input tokens, a 2048 window and 128
actual output tokens. Whole Decode is **3.487520–3.898086 t/s**, median
**3.648217**; after eight warmup tokens **3.526876–3.956720**, median
**3.687689**. No fifth ordinary completion was confirmed before testing stopped.
These differ from the earlier E43E five-run and diagnostic 64-output protocols.

Source records: `app-cooperative-window56-1.json` through `-4.json` in
[the evidence directory](research/benchmarks/20261014-les/).
All four sampled whole-app RSS/PSS results are below decimal 5GB; recorded
lifetime VmHWM is 4974264320 bytes, without a transient-peak guarantee.
Existing-derivative load is 1.72–1.99 s and prefill 10.65–12.24 s.
The final APK was not retested with long documents, populated 64K/128K,
Q4_K_M or vision. See [the publication snapshot](verification-beta4.md#beta4-publication-snapshot--beta4-发版快照2026-10-14).

| Request | Evidence / boundary |
| --- | --- |
| Expert blocking/reordering | Implemented; pack/verify and deliberate-corruption rejection tested on device. |
| Hot-expert LRU | Implemented; file-backed windows, not guaranteed kernel page residency. |
| Prediction/background prefetch | Implemented; five prefetch4 short-prompt runs ≥3; no-prefetch failures retained. |
| mmap/preadv async I/O | Implemented; reserved-arena safety selftest and nonzero mapped byte/range counters. |
| Q4 KV | Q4_0 K and V with Flash Attention used in measured runs. Quality impact still needs held-out evaluation. |
| Android GPU / QNN | Vulkan probe can finish with quantized matmul CPU fallback, but only **0.636925 token/s**. Not the default. No validated QNN/HTP delegate on this device. |
| Text/vision separation | New LES path is text-only and does not load the projector. Image/audio input is rejected; 35B visual runtime is not validated. |
| Cold/long/hot tests | Process load, full prefill and warmed decode recorded separately. Physically cold storage, populated 64K/128K and sustained thermal acceptance are not established. |

## App integration / 应用接入

The optional `libsiqi_les.so` exposes only `siqi_les_*` ABI version 1.
`MiniCpmLesBackend` polls bounded native events; cancellation/unload are explicit.
First use automatically packs into app-private
`les-model-cache/<model-id>/packed-v2`; subsequent uses check source identity
before reuse. Settings → Logs and cache can remove derivative caches without
deleting original weights. Model removal first unloads the engine.

Only the mixed-35B catalog entry is enabled by `SIQI_LES_RUNTIME=true`.
The untested Q4_K_M-35B entry remains blocked. Other backends keep their existing
paths; GPU settings must not be interpreted as enabling GPU in the CPU LES path.
The production profile uses a 56-expert window, adaptive CPU thread counts and poll=0 instead of
busy waiting, and records requested/effective context, prefill, decode, first
delta, actual backend and mapping counters. Library compilation requires an
arm64 device with FP16, DOTPROD and I8MM; unsupported devices are rejected
before optimized kernels are initialized.

App launch and app inference are distinct checks. See the dated addendum in
[verification-beta4.md](verification-beta4.md) for actual application results.

文档实验上限延长到 60 分钟，短输入保留 10 分钟；原生预填充进度按实际
evaluated/total token 显示并写入 JSONL。超过期限仍会安全取消，不把部分输入
标记为完整长上下文。成功记录包含 `fullPromptEvaluated`、拟合前后输入 token
和历史是否被缩减；窗口选项不能代替这些计数。
Document experiments allow 60 minutes versus 10 for the built-in short prompt;
actual prefill progress is displayed and journaled. Timeouts still cancel
safely. Full-input evaluation, pre/post-fit counts and history reductions
are explicit rather than inferred from the window dropdown.

## Reproduction / 开发者复现

Use a fresh source directory with `tools/native/prepare_minicpm_source.ps1
-CpuRuntimeOnly`, then apply `android-les-io.patch` and
`cpu-expert-slots.patch` plus `android-cooperative-barrier.patch` from
`tools/native/patches/`. The first patch already
includes the Android F_NOCACHE adaptation; do not apply it twice. Optional
Vulkan experiments additionally require the pinned Vulkan sources and
`vulkan-driver-failure.patch`, a working host shader compiler and Vulkan SDK.
Upstream source and patches retain their licenses and explicit attribution.

```powershell
$env:PUB_CACHE = 'C:/Users/Public/pub-cache-siqi'
$env:GRADLE_USER_HOME = 'C:/Users/Public/siqi-gradle-cache'
$env:SIQI_LES_SOURCE = 'C:/Users/Public/siqi-temp/minicpm-les-source'
# Optional: point FetchContent to an already verified KleidiAI v1.24.0 checkout.
$env:SIQI_KLEIDIAI_SOURCE = 'C:/path/to/kleidiai-v1.24.0'
flutter build apk --release --no-pub --target-platform=android-arm64 `
  --dart-define=SIQI_LES_RUNTIME=true
```

Do not enable the Dart flag without the native library. Verify Gradle success,
APK mtime/hash, `lib/arm64-v8a/libsiqi_les.so`, package version and signature;
a trailing Flutter “Built” message can refer to a stale APK after failure.
`siqi-les-abi-test` tests singleton ownership, invalid JSON/settings, event
ownership and repeated destruction without loading weights.

Raw successful, failed and timed-out runs are in
[`research/benchmarks/20261014-les/`](research/benchmarks/20261014-les/).
CLI tools are developer-only; normal users operate app buttons.
