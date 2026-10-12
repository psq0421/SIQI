# SIQI 1.0.0.Beta.3 / Beta.3 更新日志

版本 / Version: `v1.0.0.Beta.3` · build `4200`  
平台 / Platform: Android 10–17 · arm64-v8a  
应用 ID / Application ID: `com.psq.siqi`

## 中文

Beta.3 是一次面向真实设备的性能与可观测性升级。它没有把“配置上限”包装成“硬件必然能力”，而是把上下文、内存、CPU 核心、后端和 NPU 候选状态明确呈现出来。

### 上下文与资源调度

- 产品上下文窗口上限从 256K 统一调整为 128K。
- 旧版本保存的超限配置会自动迁移到 128K，不影响会话和模型文件。
- 资源规划器根据可用内存、Swap/ZRAM、模型映射、KV 估算和当前压力动态收缩实际上下文。
- 性能记录新增 `requestedContext`、`effectiveContext`、`contextWasReduced`、实际后端与 GPU 层数，避免虚报。
- LAN Gateway 的 `context_window` 上限同步为 131072。

### CPU / GPU / NPU

- 新增“CPU 与加速器调度”设置页。
- 读取 `/proc/cpuinfo` 与 Android cpufreq sysfs，显示每个核心的架构、Part ID 和最高频率。
- 支持选择进程 CPU affinity，并持久化用户选择；本地推理启动前应用该选择，推理工作线程继承进程亲和性。
- 对 A5xx 能效小核增加提示，不建议仅使用小核运行大模型。
- 增加 Arm v9 候选、Hexagon 设备、QNN/Hexagon runtime 和 Snapdragon 系列能力分层检测。
- 只有检测到可验证 delegate 且模型为兼容 `.litertlm` 格式时才尝试 NPU；GGUF 仍由 llama.cpp CPU/Vulkan 执行。

### Android 17 真机验证

- 在 Snapdragon 8+ Gen 1、12GB RAM、Android 17 设备上完成覆盖安装测试。
- 实测核心信息：A510 @ 2.02GHz、A710 @ 2.75GHz、X2 @ 3.19GHz。
- Release APK 启动、设置页、CPU 核心选择和亲和性应用验证通过。
- Debug 与 Release 构建均成功；Release 包约 39.3MB。

### 文档与发布

- 重写中英文 README：加入产品定位、四层工作机制、安装升级、隐私边界、开发构建、反馈方式和已知问题。
- 增加 Beta.3 独立中英双语更新日志。
- 补充性能实验和 Android 原生基准文档。

### 已知问题

- GPT‑OSS‑20B 在长对话生成途中偶发暂停输出。
- 该问题计划在下个版本处理：流式 watchdog、KV/分页压力、线程唤醒与断点续生成将一并回归测试。
- 在修复前建议使用较短会话，或降低上下文和批大小。

## English

Beta.3 is a real-device performance and observability release. It does not turn a configuration ceiling into a hardware promise; context, memory pressure, CPU cores, backend selection, and NPU eligibility are now reported explicitly.

### Context and resource scheduling

- Unified the product context ceiling at 128K, down from 256K.
- Migrates persisted values above the new cap to 128K without deleting sessions or models.
- Dynamically plans resident context from available memory, Swap/ZRAM, mapped model pages, KV estimates, and current pressure.
- Performance records now include `requestedContext`, `effectiveContext`, `contextWasReduced`, the effective backend, and resolved GPU layers.
- LAN Gateway `context_window` is capped at 131072 as well.

### CPU / GPU / NPU

- Added a CPU and accelerator scheduling page.
- Reads `/proc/cpuinfo` and Android cpufreq sysfs to show architecture, Part ID, and maximum frequency for every core.
- Users can select process CPU affinity. The choice is persisted and applied before local inference so worker threads inherit it.
- Warns against using only A5xx efficiency cores for large models.
- Added layered detection for Arm v9 candidates, Hexagon devices, QNN/Hexagon runtimes, and Snapdragon capability profiles.
- NPU selection is attempted only for a verified delegate with a compatible `.litertlm` model. GGUF remains on llama.cpp CPU/Vulkan.

### Android 17 device verification

- Overlay installation verified on a Snapdragon 8+ Gen 1, 12GB RAM, Android 17 device.
- Verified core data: A510 @ 2.02GHz, A710 @ 2.75GHz, X2 @ 3.19GHz.
- Release startup, settings, core selection, and affinity application passed.
- Both Debug and Release builds succeeded; the Release package is approximately 39.3MB.

### Documentation and release

- Reworked both READMEs with product positioning, the four-layer mechanism, installation, privacy boundaries, development, feedback, and known issues.
- Added this standalone bilingual Beta.3 changelog.
- Added performance-lab and Android native benchmark documentation.

### Known issue

- GPT‑OSS‑20B may pause unexpectedly during long-form generation.
- The next version will address the streaming watchdog, KV/paging pressure, thread wake-up, and resumable generation with regression tests.
- Until then, use shorter sessions or lower context and batch sizes.
