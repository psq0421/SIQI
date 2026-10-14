# Beta4：可复现的研究记录 / Reproducible research records

## 实现与证据 / Implementation and evidence

本页记录研究接口与验收口径；新增的短文本真机结果见[Android LES 优化](android-les-optimization.md)，不代表全部上下文与模态均达标。
This page describes research interfaces and acceptance criteria. Dated short-text results are in the Android LES report, not a claim for every context or modality.

| 记录 / Record | 实现 / Implementation | 内容 / Contents |
| --- | --- | --- |
| Agent 任务 / Task | `lib/core/services/agent_service.dart` | 输入、模型请求、计划、动作、每步结果、终止原因 / instruction, model request, plan, actions, results, termination |
| 持久化 / Persistence | `lib/core/database/local_database.dart` | SQLite v7，单调事件序列；重启标记中断 / ordered events, restart interruption detection |
| 导出 / Export | 设置 → 日志与缓存 / Settings → Logs and cache | JSON；完整轨迹或失败/取消/中断轨迹；最近 100 条 / latest 100 traces, optional failure filter |
| 内存保护 / Watchdog | `lib/core/services/inference_health_policy.dart` | 三次持续低内存、CRITICAL 温控、模型 RSS 目标 / consecutive pressure, critical thermal state, model RSS target |
| 基准 / Benchmark | `lib/features/settings/performance_lab_page.dart` | JSONL started/sample/completed，设备、量化、校验值、后端、上下文、RSS/PSS、缺页、温度、吞吐 / durable run journal and metrics |
| 验收 / Acceptance | `lib/core/services/memory_acceptance_report.dart` | passed / failed / inconclusive；请求上下文与实际上下文分别记录 / requested and effective context stay separate |
| 汇总 / Summary | `tools/research/summarize_runs.dart` | 按模型校验、配置、SoC、输入 SHA、实际输入/输出、上下文及冷/热状态分组；未知信息另组 / workload-specific grouping, unknown metadata isolated |

Agent 日志先在写入时脱敏，输出最大 12,000 字符；写文件动作记录内容长度及 SHA-256，不把全部新代码重复复制进事件表。原始指令、路径和工具输出仍可能含隐私。分享前必须人工审阅；不得把自动脱敏当成匿名化保证。

Agent events are redacted before persistence and bounded to 12,000 characters. File-write actions record content length and SHA-256 instead of duplicating entire files. Instructions, paths and tool output may still contain private data. Review exports manually; redaction is not an anonymity guarantee.

## MiniCPM 35B：验收口径 / Acceptance contract

- 主目标：MiniCPM‑V 4.7 35B‑A3B；优先比较 `mix_q3gud_im` 与 `Q4_K_M`。两个权重产物来自 ModelScope，下载与运行时兼容性分开管理。
- 5GB 指 **5,000,000,000 字节**的采样整应用 RSS/PSS 峰值，包含 Flutter、原生模型、KV 和视觉组件；不只统计“激活参数”，不等同于 GGUF 文件大小。
- 内存规划与 watchdog 不是硬分配器，周期采样可能漏掉瞬时峰值。超预算停止不能证明模型已在预算内完整运行。
- 基准入口默认 2K，可选择窗口、真实文档和模型复用；实际输入 token、实际窗口与输出必须独立读取，不能用窗口选项宣称 128K 驻留或 5 t/s 已达标。
- `SIQI_LES_RUNTIME=true` 的专用开发包包含 4.7 35B 混合量化 **文本**运行时；不带该库的默认构建仍保留适配中状态。35B Q4_K_M 和视觉/音频不伪装为已验证。
- LES 路径不以固定 5GB 取消，而根据持续内核压力与 CRITICAL 温控安全停止；decimal 5GB 保留为研究比较目标。56 专家窗口的五轮短输入采样通过，生命周期高水位仍曾超出；长上下文与严格硬上限未通过。
- 不以 llama.cpp 为唯一方案：后续 LES 专家流式后端、MNN 或其他原生后端均需独立验证算子、量化格式、取消机制、视觉编码器和模型许可。语言或芯片名称不能代替运行时兼容证据。

English summary: target the 4.7 35B‑A3B mixed/Q4 artifacts; measure sampled whole-app RSS/PSS against decimal 5GB; record actual context and throughput separately. The optional mixed-35B LES text library is integrated and device-tested. The 2K short-prompt result is not a 128K test; vision, Q4_K_M and other native backends need independent validation.

## 实验方案 / Experiment protocol

### 上游核验与移植前置 / Upstream verification and port prerequisites

本轮核验了 OpenBMB `llama.cpp-omni` revision `0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2` 的 [LES 文档](https://github.com/OpenBMB/llama.cpp-omni/blob/0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2/docs/les/lookahead-expert-scheduling.zh.md)、`include/llama.h` 和专家 slot 实现。

- 文档给出的 17.39 token/s 是 **M4 iPad Pro、16GB**、LES + DSpark 的结果，不能转写成骁龙手机成绩或整应用 3GB 保证。
- 上游有 lookahead、park/prewarm 接口；专家 slot 加载要求 gate/up/down 按专家连续打包，且 slot 为 CPU 可寻址内存。直接把普通 GGUF 下载完，不等于完成该布局和加载器适配。
- Metal buffer park/unpark 不能直接调用于 Android。先验证 Android CPU 路径、`preadv`、宿主可见缓冲区，再独立研究 Vulkan 缓冲区同步与 DSpark；不能仅替换动态库名称或绕过 ABI 检查。
- 当前 ModelScope 仓库列出了普通 GGUF、混合量化与视觉投影产物；后续应确认专家打包工具、索引/数据产物与校验，再设计自动安装流程。
- `tools/native/prepare_minicpm_source.ps1` 只是固定 revision 的源码准备工具，不是 APK 后端。源码下载失败、模型加载失败和性能未达标均应保留为失败记录。

The verified upstream result is on a 16GB M4 iPad, not a Snapdragon memory guarantee. Android needs independent packed-expert artifacts, host-addressable slots, I/O validation, ABI checks and backend synchronization. Source preparation is not runtime integration.

1. 固定模型 SHA、运行时 revision、APK commit、ROM、SoC、RAM、可用存储、线程与电量模式。
2. 冷启动与热启动分开；中文闲聊、Agent 工具协议、单图视觉分别跑。不要把文本模式的峰值外推给图像模式。
3. 每组至少 5 次，记录全部失败；比较中位数、分位数、TTFT、prefill、decode、端到端耗时与 RSS/PSS 峰值。
4. 长对话单独做 10/30/60 轮回归，区分用户取消、温控停止、LMK 重启和解码停滞。128K 必须另用真实 token 计数的长输入验证。
5. 研究训练/校准集与保留评测集分开，记录语料许可、硬件成本与量化质量；不开 Root，不修改系统 ZRAM 分区。

Pin artifacts and revisions; separate cold/warm, text/tool/vision workloads; run at least five repetitions and retain every failure; test multi-turn and genuinely populated long context separately; keep calibration and held-out evaluation data disjoint.

## 开发者命令 / Developer commands

普通用户通过应用按钮操作，不需要输入命令。以下仅供研究开发者。
Normal users use the app controls; these commands are for developers only.

```sh
flutter pub get
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
dart run tools/research/summarize_runs.dart beta4.jsonl
```

CI 工作流见 `.github/workflows/quality.yml`。本地测试覆盖温控误取消、内存采样验收、凭据脱敏、SQLite 6→7 升级、重启中断、拒绝写入、路径越界、轨迹导入导出、黑白主题和返回控件。
The workflow checks analysis and tests. Coverage includes thermal cancellation regression, sampled memory acceptance, secret filtering, schema migration, restart interruption, denied writes, path boundaries, trace round trips and theme/back controls.

The benchmark journal is serialized by `lib/core/services/benchmark_journal.dart`; a run gate prevents two experiments from sharing the same native engine, and the page captures the run's own metrics before another request can overwrite them. Token timing records the first reasoning delta and first visible-content delta separately. The standalone probe and optional production library have separate evidence: the latter exposes only an opaque `siqi_les_*` ABI, never llamadart's incompatible llama/ggml structs. Process-cold loading, first-time packing, full prefill, whole-decode and eight-token-warmed decode metrics remain distinct.

Windows 构建时，原生插件对中文缓存路径可能不兼容。本轮改用纯英文 `PUB_CACHE` 与 Gradle 缓存路径，再核对 `aapt dump badging` 的包内版本号、签名及实际真机启动；不能只凭终端末尾的“Built”判断构建成功。
On Windows, native dependencies can fail under non-ASCII cache paths. Verify APK metadata, signing and device launch after building with ASCII caches; a trailing “Built” message alone is insufficient.

汇总工具的合成测试数据在 `test/fixtures/benchmark_synthetic.jsonl`，它不是任何真机成绩。
The summary tool's fixture is explicitly synthetic and must never be presented as a measured device result.

### Workload separation / 负载分组修正

Summary schema 2 no longer combines a short 51-token run with a fully evaluated
4785-token document merely because the thread-profile label matches. Prompt
hash, actual input/output counts, requested/effective window, model hash,
backend revision, mode and model reuse state are grouping dimensions. Missing
historical counters stay unknown in separate groups. The old schema could
produce a misleading 3.04 t/s median from one 4.05 t/s short run and one
2.03 t/s long run; that aggregate is not a long-input success.

同状态线程回放仅用于诊断：恢复真实输入的 KV、循环状态与 logits，再以贪心采样
比较 4/2/6/8 个线程，每配置至多 64 个输出 token，检查 token 序列是否一致。
固定顺序且没有清空文件缓存，不能当作独立四轮或严格公平的性能对照。它与普通
对话结果单独分组，主成绩保留第一组基线，绝不自动挑选最高值。
