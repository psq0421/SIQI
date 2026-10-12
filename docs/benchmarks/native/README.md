# 原生基准探针

`siqi-bench.cpp` 是一个隐私安全的 Android 原生探针，用于核对 Dart 封装之外的 llama.cpp decode 计时。它使用固定 prompt，忽略 EOG，仅适合比较同一设备上的运行时参数，不代表真实聊天质量。

## 构建要点

1. 使用 Android NDK 29、arm64-v8a、Release 构建 llama.cpp b10333。
2. 应用使用的 CPU variant 应启用 `GGML_CPU_ALL_VARIANTS=ON` 和 `GGML_CPU_KLEIDIAI=ON`，SM8475 选择 `armv8.6_1`。
3. 将 `file-backed-repack.patch` 应用到同一上游源码的 `ggml/src/ggml-cpu/repack.cpp`；使用前执行 `git apply --check`。
4. 运行时设置 `SIQI_REPACK_CACHE_DIR` 才启用文件后备工作区，否则不要让大型匿名 repack 进入 12 GB Android 设备。

示例命令（设备路径按实际安装位置替换）：

```text
SIQI_REPACK_CACHE_DIR=/data/local/tmp/siqi-repack \
  siqi-bench MODEL.gguf /data/local/tmp/siqi-repack 4 0 256 q8 1 1
```

输出中的 `decodeWallTps` 是探针墙钟吞吐；应用内记录的 `decodeTokensPerSecond` 来自 llama.cpp performance context。两者应分开报告。
