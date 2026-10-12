# SIQI Beta3 性能记录

这份记录描述 Beta3 在一台真实 Android 17 设备上的可复现实验，不是对所有手机的性能承诺。

## 设备与构建

- 设备：小米 2206122SC，Snapdragon 8+ Gen 1（SM8475），12 GB RAM，Android 17
- 模型：GPT-OSS-20B Q4_K_M GGUF，文件大小 11,624,759,488 bytes；GGUF 元数据为 20.91B 参数、32 个专家、每 token 选择 4 个专家
- 该 GGUF 的训练上下文为 131,072，且包含 SWA（128）；128K 已接近该产物的原生上限
- 推理栈：llama.cpp b10333、llamadart 0.8.19、Android arm64-v8a
- CPU 后端：armv8.6 `dotprod+fp16+i8mm`，启用 KleidiAI；CPU 线程 4
- 上下文：2048；KV cache：Q8_0；Flash Attention：启用；batch/ubatch：256/128
- 运行时：文件映射模型 + 可选的匿名 repack 文件后备映射；临时映射在进程退出或模型释放后由内核回收
- 本次 release APK SHA-256：`F1BC910B1549B5A64F1CF993A905D5028FDFA5D6F4555890E925A39F471AEFA1`

## 结果

应用内性能实验（英文固定 prompt，贪心采样，256 个输出 token）记录为：

| 指标 | 数值 |
| --- | ---: |
| 模型加载耗时 | 50,856 ms |
| prompt token / prompt eval | 106 / 8,973 ms |
| decode token / native eval | 256 / 44,216 ms |
| native decode throughput | **5.79 token/s** |
| 应用进程峰值 RSS（采样） | 约 7.3 GiB |
| 记录时最高电池温度 | 37.1 °C |
| LMK / 崩溃 | 未发生 |

这是一次冷加载实验，不等同于长时间稳定吞吐。尚未完成多轮、不同温度和不同系统后台负载下的置信区间测试，也没有把该数字外推到 GPU、NPU 或其他 SoC。

## 关于 128K 产品上限

Beta3 的用户可选上下文上限为 128K。当前设备和该 GGUF 仍不能诚实地宣称“真实 128K KV cache 下仍有 5 token/s”；大模型会根据可用内存将实际驻留上下文安全地降低，并在性能记录中写入 `requestedContext`、`effectiveContext` 和 `contextWasReduced`，避免把配置值冒充运行值。

原因是 GPT‑OSS 的混合注意力仍需要为非滑动窗口层保留完整 KV。按当前 Q8 KV 的约 96KiB/token 保守估计，128K 仅 KV 就约 12GiB，尚未计入 10.8GiB 模型映射、工作区和 Android 运行时；即便改用 Q4 KV，也无法在 12GB 设备上稳定驻留。该模型自身训练上下文也只有 131K。

要满足“真实 128K + 5 token/s”，下一阶段必须引入经过质量评测的分页/压缩 KV、非滑动层的磁盘分层或模型级长上下文方案；简单放开 `n_ctx` 会导致分配失败、重度换页或严重降低吞吐，因此没有作为 Beta3 的伪通过方案。

## 内存策略

Beta3 不再使用固定的 60%/80% RAM 拦截。准入依据是 Android `availMem`、系统低内存阈值、可用 ZRAM/swap、模型映射工作集、KV cache 和当前热状态。大模型默认 CPU 路径，避免把完整专家权重复制到 Vulkan 显存；在 SM8475 上，repack 工作区使用应用缓存目录的文件后备映射，并在生成后主动 `msync`/`madvise(DONTNEED)`。

这不是对 ZRAM 的系统级重配置，也不绕过 LMK。压力监视器在系统进入临界内存或热状态时取消生成并释放模型。

设计取舍参考了 *LLM in a Flash*（arXiv:2312.11514）的窗口化/文件映射思路，以及
*PowerInfer-2*（arXiv:2406.06282）的 CPU/NPU/存储协同调度讨论；Beta3 只落地了适合
Android 无 root 场景的文件后备 repack 和压力感知准入，尚未声称实现论文中的完整算法。

## 限制与下一步

1. 目前已验证 llama.cpp CPU + Vulkan 诊断路径；Qualcomm NPU/MNN 后端仅保留能力检测接口，未宣称已启用。
2. 文件后备 repack 会增加模型首次加载时间和存储写放大，适合实验机，不应默认用于低剩余空间设备。
3. 需要至少 3 个冷进程、3 个暖进程、三种 prompt 集合和热稳态曲线后，才适合发布论文级结论。
4. 质量评测必须同时报告固定 seed 的输出一致性、领域 prompt 成功率、PPL/KLD 与吞吐，不能只报告 token/s。

原始 JSONL 记录由应用保存在 `files/benchmarks/beta3.jsonl`；记录只包含计数、温度和内存采样，不包含用户对话或密令。

构建产物位于 `build/app/outputs/flutter-apk/app-debug.apk` 与
`build/app/outputs/flutter-apk/app-release.apk`。release 已在同一设备上以覆盖安装方式启动，未清除模型或应用数据。
