# 司器 SIQI · v1.0.0 Beta.4

> 把端侧大模型跑起来，也把每一步留下来。<br />
> Run local models. Keep the evidence.

**版本 / Version:** `1.0.0-beta.4` · **build 4300**<br />
**日期 / Date:** 2026-10-14 · **渠道 / Channel:** Beta / Pre-release<br />
**平台 / Platform:** Android 10–17 · API 29–37 · arm64-v8a

[下载安装 / Downloads](https://github.com/psq0421/SIQI/releases/tag/v1.0.0.Beta.4) · [中文说明](https://github.com/psq0421/SIQI/blob/v1.0.0.Beta.4/README.md) · [English guide](https://github.com/psq0421/SIQI/blob/v1.0.0.Beta.4/README_EN.md) · [反馈 / Issues](https://github.com/psq0421/SIQI/issues)

---

## 中文更新日志

### 本次重点

Beta.4 将端侧优化主线转向 **MiniCPM，优先 MiniCPM-V 4.7 35B-A3B**。本次发布包接入混合量化模型的 LES 文本运行时，配合专家重排、文件映射、LRU 和后台预取，让它在 12GB 骁龙 8+ Gen1 真机上完成应用内推理。与此同时，重做黑白极简界面、完善长任务取消与释放、加入结构化 Agent 轨迹和可复核的性能记录。

这是一版带有实验性大模型能力的 Beta，**不是全系、全模态、长上下文的最终验收版本**。以下将交付功能、最终包实测和未完成项分别列出。

### 1. 黑白极简界面与日常体验

- 保留现有 logo、启动品牌图和桌面图标，不更换品牌标识。
- 重整浅色与深色主题，以白色、黑色和低对比中性色为主。
- 顶部返回与操作控件采用大圆角、轻光感设计；统一页面控件风格。
- 设置项增加留白和分组间距，减轻字重，减少密集堆叠。
- 对话输入区与附件工具区分行排列，模型市场标签支持换行。
- 打开已有会话时优先定位到最新消息；查看开头需要手动向上滚动。
- **前台保持亮屏默认开启**，可在「设置 → 界面与外观」关闭。仅前台生效，后台恢复系统策略，不新增唤醒锁权限。
- 首次引导保存完整默认 System Prompt，明确司器身份、工作区边界、隐私、工具授权和结果验证要求。
- 「设置 → Shell」增加内置开发者终端入口，保留危险命令确认，不申请 Root；普通用户仍可通过界面操作。

### 2. MiniCPM 模型市场与国内下载

- 模型市场优先展示 MiniCPM-V 4.7 35B-A3B，扩展 MiniCPM3 / 4 / 4.1 / 5、MiniCPM-V 2.6 / 4.x 和 MiniCPM-o 的产物目录。
- 提供 ModelScope 直链、产物大小、量化格式、许可证和 SHA-256；下载保持断点续传与完整性校验。
- 将**可下载**与**运行时兼容**分开标注，不能运行的构件不会伪装成已支持。
- 35B 提供 `mix_q3gud_im` 与 `Q4_K_M` 产物，权重约 15.50 / 21.17 GB，视觉组件另约 1.12 GB。
- **本次包实际启用的是 `mix_q3gud_im` 的 LES 文本路径。** `Q4_K_M` 35B 仍未完成运行验收，不能因为能下载就宣称可用。
- 专用 35B 文本路径不加载视觉 projector，拒绝图片、音频输入；不会把 MiniCPM-o 的文本/图像条目冒充全双工音频支持。
- 删除模型前先卸载推理引擎；LES 派生缓存可单独清理，原始 GGUF 保持不变。

### 3. 安卓专家流式化运行时

本次发布 APK 已打包独立的 `libsiqi_les.so`，并启用 `SIQI_LES_RUNTIME=true`。普通模型仍沿用既有 llamadart / llama.cpp 路径，35B 混合量化条目走专用文本运行时。

- **专家分块与重排：**按 layer / expert-major 生成派生产物，校验基础张量与专家权重，原始模型不改写。
- **热专家 LRU：**默认每层 56 个专家槽位；prefill 共享槽位 bank 为 128，减少重复匿名缓冲。
- **路由预测与后台预取：**以 lookahead 提前准备可能命中的专家；真正计算仍使用实际 top-k，不跳过冷专家。
- **异步 I/O：**4 个常驻读取 worker，使用受控预留地址区中的文件映射；非对齐数据使用 `preadv` 回退，并按实际系统页大小处理。
- **Q4 KV Cache：**已测路径使用 Q4_0 K/V 与 Flash Attention；量化品质影响仍需要独立评测。
- **ARM CPU 内核：**启用 FP16 / DOTPROD / I8MM，进入优化内核前检查指令集能力。
- **协作等待：**长同步屏障短暂自旋后休眠，避免仅关闭空闲轮询、算子之间却持续忙等；保留参与线程、原子操作和内存屏障。
- **隔离 ABI：**独立 opaque ABI v1 与原有运行时分离；公开 9 个 `siqi_les_*` C 入口，不导出上游 llama / ggml 名称。标准 C++ weak RTTI / vtable 符号仍存在。

LRU 是尽力保留的文件映射，**不是 `mlock` 常驻保证**；Android 仍可回收页面。普通对话默认 CPU 4 线程自适应、`poll=0`、专家窗口 56、预取深度 4、micro-batch 8，不默认强绑大核，也不把「所有核心都开」当作优化成果。

### 4. 长输出稳定性、取消与内存释放

- 修复 Android 温控 `SEVERE` 被误当作必须停止推理的触发条件；它表示降频，不再直接取消。
- 持续低内存采用连续采样判断；真正的 `CRITICAL` 温控和持续内核压力仍保留安全退出。
- 流失败或用户取消时保留已经显示的部分回复，给出明确原因。
- 原生完成 / 失败事件等待工作线程确认停止，避免下一次请求与仍在运行的解码器竞争。
- 消费者回调或事件解析异常时，协作取消并等待停止，不把解码线程留在后台。
- 并发卸载串行化；避免在原生解码仍使用张量时直接释放内存。
- 支持显式停止和卸载模型，原始权重与可重建缓存分别管理。

这些是对已确认代码路径的修复。**Beta.3 中 OSS-20B 长对话突然暂停的问题尚未完成彻底根治验收**，原生挂起、LMK 和长时压力仍需后续回归；不宣称实现断点续生成。

### 5. Agent 结构化轨迹与失败日志

- SQLite 升级到 v7，保存输入指令、模型请求、计划、动作顺序、每步结果和终止原因。
- 模型请求失败、尚未进入工具执行阶段的任务同样留痕。
- 规划、授权和执行复用同一条轨迹，增加重复点击保护与工作区变更检查。
- 应用重启后，未完成任务标记为中断，不计为成功。
- 「设置 → 日志与缓存 → Agent 任务轨迹」支持导出最近 100 条完整任务，或最近 100 条失败 / 取消 / 中断任务，格式为 JSON。
- 常见凭据自动遮蔽，工具输出有长度上限，写入动作记录大小与校验值，避免复制整份代码。
- 导出前提示人工隐私审查，分享由用户主动触发，没有自动上传日志。

自动脱敏不等于匿名：指令、路径和工具输出仍可能包含个人信息，请分享前检查。

### 6. 性能实验室与研究基建

- 持久 JSONL 记录 started / sample / completed，包含设备、模型 SHA、量化、后端、实际上下文、吞吐、RSS / PSS、缺页和温控数据。
- 分开记录准备 / 加载、完整 prefill、纯 Decode 和排除前 8 token 的热 Decode，不混用启动耗时与模型加载耗时。
- 记录请求与实际上下文、拟合前后输入 token、历史是否缩减、是否完整评估输入，以及请求与实际输出上限。
- 支持真实文档、窗口选择与已加载模型复用；文档实验限时 60 分钟，短提示词保持 10 分钟。
- 内存结论分为 passed / failed / inconclusive，缺失权限或指标记为未知，不补造数字。
- 汇总工具 schema 2 按模型 / 提示词 SHA、实际输入输出量、窗口、后端 / 模式和冷 / 热状态分组，修复短答与长文混算中位数的问题。
- 增加同状态 CPU 4 / 2 / 6 / 8 线程回放：输入只 prefill 一次，保存并恢复 KV、循环状态和 logits；保留每个结果与 token 序列比较，主成绩固定为首个 CPU4 配置。
- 单个配置完成后立即持久记录，后续配置失败不会抹掉已完成结果；保留历史失败、超时、未完成任务和原始坏行。
- 提供原生探针、补丁导出脚本、基准采集与汇总工具、回归测试和 CI 定义；固定上游来源与许可证，不虚构论文、上游 PR 或提交历史。

线程回放仍是探索性诊断：顺序固定，专家 LRU / page cache 未重置，非基准配置的 token 序列不同，不能当作品质等价或公平随机化实验。

### 7. 最终发布包真机成绩

**设备：**12GB RAM、骁龙 8+ Gen1 / SM8475、Adreno 730、Android 17。<br />
**模型：**MiniCPM-V 4.7 35B-A3B `mix_q3gud_im`，不是 Q4_K_M 权重。<br />
**协议：**最终 Release 包，4 轮；每轮实际输入 51 token、窗口 2048、实际输出 128 token，EOS 正常结束；请求输出上限为 256。

| 轮次 | 纯 Decode token/s | 排除前 8 token 后 token/s |
| --- | ---: | ---: |
| 1 | 3.8981 | 3.9567 |
| 2 | 3.5730 | 3.6113 |
| 3 | 3.4875 | 3.5269 |
| 4 | 3.7235 | 3.7641 |
| 中位数 | **3.6482** | **3.6877** |

- 四轮均达到该短输入协议下的 3 token/s 目标；不外推为其他手机、长上下文或视觉成绩。
- 派生缓存已存在时，重新加载模型约 1.72–1.99 秒，prefill 约 10.65–12.24 秒；不是物理冷磁盘测试。
- 四轮采样 RSS / PSS 均低于 decimal 5GB；所记录生命周期 RSS 高水位为 4,974,264,320 字节。采样可能漏掉瞬时峰值，**不提供永不超过 5GB 的保证**。
- 历史另一开发包五轮曾达到 4.24–4.82 token/s，但属于不同 APK / 测试阶段，保留在研究报告，不冒充当前发布包成绩。

**长输入失败也保留：**历史开发包完整处理 4,785 输入 token、8192 窗口、256 输出 token；56 / 96 专家窗口纯 Decode 仅 2.075 / 2.029 token/s，prefill 约 23.43 / 20.89 分钟。扩大缓存未带来目标收益。最终包未重新执行长文验收，不能把短输入达标写成 64K / 128K 达标。

### 8. 安装包与已完成检查

| 资产 | 大小 | 用途 |
| --- | ---: | --- |
| `app-release.apk` | 42,740,615 字节（约 40.76 MiB） | 推荐日常安装，优化构建 |
| `app-debug.apk` | 137,119,320 字节（约 130.77 MiB） | 开发与问题诊断 |
| `SHA256SUMS.txt` | 校验清单 | 核对下载完整性 |

- 两包均为 `com.psq.siqi`、`1.0.0-beta.4`、build `4300`，arm64-v8a，APK v2 签名验证通过。
- 最终 Debug / Release 均在基准机覆盖安装并冷启动成功；Activity 启动为 4546 / 777 ms，不是模型加载或首 token 时间。
- 静态分析无问题；普通和 LES 开关两套配置各 51 项自动测试通过；原生 ABI 生命周期自测 4 轮通过。
- 已验证亮屏策略、黑白主题、失败轨迹分享入口及模型释放等路径；**不等于所有设备和全部功能组合完成验收**。
- 覆盖安装后重新校验原始 35B GGUF，其 SHA 不变；未清空会话、配置或正式模型数据。
- 两包当前仍使用既有本地 **Android Debug 证书**，Release 指优化构建，不等于生产密钥签名。相同签名可覆盖安装；签名不一致时先导出数据，不建议直接卸载丢失本地资料。

SHA-256：

```text
31a1c69e4baa883debe2a9bb380fdf25728ae887c15723a697170e4f17b20f65  app-release.apk
9c865484d98e2e9b854535344f1aff3b510e28e798b7068fc960982fa7f1f935  app-debug.apk
```

### 9. 使用提示与已知限制

1. 首次运行 35B 会自动重排和校验，需额外约一份模型的磁盘空间；早期首次准备加加载约 71 秒，不代表所有设备耗时。
2. 普通用户无需输入命令；在模型市场安装兼容构件后，从对话中切换模型。文本路径不能接收图片或音频。
3. 长任务结束后可主动卸载模型；在日志与缓存页面清理 LES 派生缓存，下次需重建。
4. **64K / 128K 是配置能力，不是已填满且稳定运行的证明。** 真实长上下文、64K 连续输出与 128K / 5 token/s 尚未达标验收。
5. 35B 视觉、音频及 Q4_K_M 权重未验收；不能宣称 MiniCPM 全系全模态已经可用。
6. Vulkan / Adreno 实验路径能在量化矩阵乘回退 CPU 后结束，但仅约 0.637 token/s，不默认启用。没有已验证的 QNN / HTP delegate 或 NPU 加速成果。
7. MNN 生产运行时尚未打通；芯片检测、后端枚举和调度入口不等于实际 MNN / NPU 推理。
8. 文档 / 附件提取和工作区文件写入继续可用；不宣称百余种专有格式（如 PSD / CAD）均可原生生成或渲染，也不宣称 Harness 在所有本地及 API 后端实现全功能等价。
9. 没有 Root、ZRAM 写入或热保护修改；尚未完成物理 16KB 页设备、物理冷存储、持续热稳定性及量化品质的完整验证。

反馈请附设备、模型与量化、实际上下文、CPU / GPU 配置及脱敏日志，勿提交 API Key 或完整私人文件。

---

## English changelog

### Release focus

Beta.4 moves local-model work toward **MiniCPM, especially MiniCPM-V 4.7 35B-A3B**. The published APKs integrate a mixed-quantized, text-only LES runtime with expert repacking, file mappings, LRU windows and background prefetch, enabling app-integrated inference on the 12GB Snapdragon 8+ Gen1 reference phone. The release also brings a monochrome interface, safer cancellation / unloading, structured Agent traces and auditable benchmarks.

This Beta includes experimental large-model capabilities. **It is not final family-wide, multimodal or long-context acceptance.** Shipped behavior, measurements and remaining limits are separated below.

### 1. Interface and everyday use

- Preserved the logo, splash artwork and launcher icon.
- Reworked light / dark themes around white, black and restrained neutral colors.
- Introduced large rounded, softly highlighted top controls, roomier settings and lighter typography.
- Separated composer tools from the text field; model-card labels can wrap.
- Saved conversations open at their newest message; scroll upward to revisit the beginning.
- **Keep screen awake in foreground** is enabled by default and optional in Appearance. Backgrounding restores system behavior; no extra wake-lock permission is added.
- Onboarding saves the complete default System Prompt, including identity, workspace boundaries, privacy, tool approval and evidence-based reporting.
- Shell settings link to the built-in developer terminal with dangerous-command confirmation and no Root requirement. Normal workflows remain button-driven.

### 2. MiniCPM catalog and downloads

- Prioritized MiniCPM-V 4.7 35B-A3B and expanded artifact entries for MiniCPM3 / 4 / 4.1 / 5, MiniCPM-V 2.6 / 4.x and MiniCPM-o.
- Added ModelScope direct URLs, sizes, quantization, licenses and SHA-256 alongside resumable downloads and verification.
- Separated download availability from runtime compatibility; unsupported artifacts are not advertised as working models.
- The 35B entries include `mix_q3gud_im` and `Q4_K_M`: approximately 15.50 / 21.17 GB of weights, plus a separate 1.12 GB visual projector.
- **Only the mixed artifact's LES text path is enabled in these APKs.** Q4_K_M 35B remains unvalidated / blocked for execution.
- The dedicated text runtime does not load the projector and rejects image / audio inputs. MiniCPM-o text / vision entries do not imply full-duplex audio support.
- Model removal unloads its engine first. LES derivatives can be deleted separately without changing the source GGUF.

### 3. Android expert-streaming runtime

These APKs bundle `libsiqi_les.so` with `SIQI_LES_RUNTIME=true`. Existing models retain their llamadart / llama.cpp paths; the mixed 35B entry uses a dedicated text backend.

- Layer / expert-major repacking verifies base and expert tensor bytes without modifying original weights.
- Default per-layer LRU windows use 56 slots, with a shared 128-slot prefill bank and reduced duplicate anonymous buffering.
- Lookahead / background prefetch prepares likely experts; actual top-k routing still determines computation, including cold experts.
- Four persistent I/O workers use file mappings inside a reserved arena, non-aligned `preadv` fallback and actual system page sizes.
- Measured runs use Q4_0 K/V and Flash Attention. Held-out quality evaluation remains open.
- FP16 / DOTPROD / I8MM CPU kernels are guarded by instruction-set checks.
- Cooperative long-wait barriers sleep after a short spin while retaining participants, atomic operations and memory fences.
- An isolated opaque ABI v1 exposes nine `siqi_les_*` C entry points without public upstream llama / ggml names. Standard C++ weak RTTI / vtable symbols are also present.

LRU is best-effort mapping retention, **not `mlock` residency**; Android can reclaim pages. Ordinary chat defaults to adaptive CPU4, poll=0, E56, prefetch4 and micro-batch8, without forced big-core binding or a claim that enabling every core improves speed.

### 4. Stability, cancellation and unloading

- Android `SEVERE` throttling no longer prematurely cancels inference.
- Sustained low-memory decisions require consecutive samples; critical thermal and sustained kernel-pressure safety exits remain.
- Stream errors and user cancellation preserve visible partial replies and explicit termination reasons.
- Native terminal events wait for the worker to stop before another request or release proceeds.
- Callback / event-parsing failures cooperatively cancel and await shutdown instead of leaving a decoder running.
- Concurrent unloads are serialized; live native tensors are not immediately freed under a decoder.
- Explicit stop / unload and separate derivative-cache management are available.

These address identified paths. **Full elimination of the Beta.3 OSS-20B long-dialogue stall is not verified.** Native hangs, LMK and sustained pressure require further regression; resumable generation is not claimed.

### 5. Structured Agent traces

- SQLite v7 captures instructions, model requests, plans, ordered actions, step results and termination reasons, including failures before tool execution.
- Planning, approval and execution share a trace, with duplicate-action guards and workspace-change checks.
- Unfinished tasks become interrupted after restart rather than successful.
- Settings → Logs and cache → Agent task traces exports the latest 100 full traces or 100 failed / cancelled / interrupted tasks as JSON.
- Common credentials are masked, tool output is bounded, and file writes retain size / checksum instead of full code copies.
- Export requires a privacy review; sharing is user-triggered, with no automatic upload.

Redaction is not anonymity: instructions, paths and tool results still need manual review.

### 6. Performance lab and research infrastructure

- Durable started / sample / completed JSONL records device, model SHA, quantization, backend, effective context, throughput, RSS / PSS, faults and thermal state.
- Preparation / load, full prefill, whole Decode and Decode after eight warmup tokens are measured separately.
- Requested / effective context, pre/post-fit token counts, history reductions, full-input evaluation and output limits are explicit.
- Real-document inputs, context selection and model reuse are supported. Document trials allow 60 minutes; short trials allow 10.
- Memory acceptance is passed / failed / inconclusive. Unavailable readings stay unknown.
- Summary schema 2 groups by model / prompt hash, actual token counts, window, backend / mode and cold / reused state instead of mixing long and short workloads.
- Same-state CPU4 / 2 / 6 / 8 replay restores KV, recurrent state and logits after one prefill. Every result and token-sequence comparison is retained; CPU4 remains the primary score.
- Completed variants are journaled immediately. Subsequent failures do not erase them; historical timeouts, incomplete runs and malformed lines remain visible.
- Native probes, patch-export scripts, collection / summary tools, regression tests and CI definitions are included, with pinned sources and license attribution.

Replay remains exploratory: fixed order, unreinitialized LRU / page cache and differing non-reference token sequences prevent claims of quality equivalence or fair randomized comparison. No paper, upstream PR or fabricated commit chronology is claimed.

### 7. Measurements from the actual release APK

**Device:** 12GB RAM, Snapdragon 8+ Gen1 / SM8475, Adreno 730, Android 17.<br />
**Weights:** MiniCPM-V 4.7 35B-A3B `mix_q3gud_im`, not Q4_K_M.<br />
**Protocol:** four final-Release runs, each with 51 actual input tokens, a 2048 window and 128 actual output tokens, ending normally at EOS; requested output cap 256.

| Run | Whole Decode token/s | After eight warmup tokens |
| --- | ---: | ---: |
| 1 | 3.8981 | 3.9567 |
| 2 | 3.5730 | 3.6113 |
| 3 | 3.4875 | 3.5269 |
| 4 | 3.7235 | 3.7641 |
| Median | **3.6482** | **3.6877** |

- All four pass the short-input ≥3 token/s target, not acceptance for other phones, long contexts or vision.
- Loading from existing derivatives takes 1.72–1.99 seconds; prefill takes 10.65–12.24 seconds. These are not physically cold-storage trials.
- Sampled whole-app RSS / PSS stays below decimal 5GB in these four runs; recorded lifetime RSS high-water is 4,974,264,320 bytes. Sampling may miss transient peaks, so **no strict never-exceeded ceiling is guaranteed**.
- Five historical runs on another APK reached 4.24–4.82 token/s. They are retained as historical evidence, not presented as the current package's score.

Historical full-input trials with 4,785 tokens, an 8192 window and 256 outputs achieve only 2.075 / 2.029 token/s at E56 / E96, with 23.43 / 20.89-minute prefill. More cache did not meet the target. No new long-input acceptance run was performed on the final package; short-input success is not filled 64K / 128K acceptance.

### 8. Packages and verification

| Asset | Size | Purpose |
| --- | ---: | --- |
| `app-release.apk` | 42,740,615 bytes (~40.76 MiB) | Recommended optimized build |
| `app-debug.apk` | 137,119,320 bytes (~130.77 MiB) | Development and diagnostics |
| `SHA256SUMS.txt` | Checksum manifest | Download-integrity verification |

- Both are `com.psq.siqi`, `1.0.0-beta.4`, build 4300, arm64-v8a and pass APK v2 signature verification.
- Final Debug / Release overlay installation and cold Activity launch succeed on the reference phone: 4546 / 777 ms, not model-load or first-token time.
- Static analysis is clean; normal and LES-flag suites each pass 51 tests, plus four native ABI lifecycle iterations.
- Screen-awake behavior, themes, failure-trace sharing and model release have device checks. This is not exhaustive testing of all devices or feature combinations.
- Original 35B GGUF SHA was rechecked after overlay installation; sessions, configuration and official model data were not cleared.
- Both use the existing local **Android Debug certificate**, not a production release key. Optimized Release and production signing are different. Overlay upgrades require a matching signer; export data before resolving a signature mismatch.
- The SHA-256 values are listed above and supplied in `SHA256SUMS.txt`.

### 9. Usage notes and remaining limits

1. First use automatically repacks / verifies experts and needs roughly one additional model-sized storage copy. Historical first preparation plus load took about 71 seconds, not a universal guarantee.
2. Normal users do not enter commands. Install a runtime-compatible artifact in Lab, select it in Chat and use text-only input for this 35B path.
3. Unload the model after long tasks if desired. Deleting LES derivatives keeps original weights but requires repacking next time.
4. **64K / 128K settings are not proof of populated, stable context.** Real long-context performance, 64K continuous output and 128K / 5 token/s remain unaccepted.
5. 35B vision / audio and Q4_K_M are unvalidated; family-wide full multimodality is not claimed.
6. Experimental Vulkan / Adreno completes with quantized-matmul CPU fallback at only ~0.637 token/s and is not the default. No validated QNN / HTP delegate or NPU speedup is delivered.
7. Production MNN is not integrated; backend enums, chip detection and controls are not proof of inference support.
8. Existing document / attachment extraction and workspace writing remain. Native generation / rendering of every proprietary PSD / CAD-like format and full Harness parity across every backend are not claimed.
9. No Root, ZRAM writes or thermal-protection changes. Physical 16KB-page devices, physically cold storage, sustained thermal stability and quantization quality remain separate validation work.

Report device, model / quantization, effective context, CPU / GPU settings and sanitized logs. Never include API keys or private source files.

## 证据与许可证 / Evidence and licenses

- [真机与安装包验证 / Device and package verification](https://github.com/psq0421/SIQI/blob/v1.0.0.Beta.4/docs/verification-beta4.md)
- [LES 优化、历史结果与八项验收 / LES optimization and acceptance](https://github.com/psq0421/SIQI/blob/v1.0.0.Beta.4/docs/android-les-optimization.md)
- [研究与导出协议 / Research and export protocol](https://github.com/psq0421/SIQI/blob/v1.0.0.Beta.4/docs/research-beta4.md)
- [原始基准证据 / Raw benchmark evidence](https://github.com/psq0421/SIQI/tree/v1.0.0.Beta.4/docs/research/benchmarks/20261014-les)

司器源码采用 MIT License；OpenBMB、llama.cpp、KleidiAI、模型及其他第三方组件保留各自许可证与署名，关于页面补充运行时许可入口。<br />
SIQI source uses MIT. OpenBMB, llama.cpp, KleidiAI, models and other third-party components retain their own licenses and attribution; runtime notices are available from About.
