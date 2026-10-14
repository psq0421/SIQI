// SIQI's independent, developer-only Android LES experiment.
// Runtime: OpenBMB/llama.cpp-omni, pinned and separately licensed (MIT).
// Never modifies downloaded weights. Shared code also serves the optional
// production text runtime through a separate opaque SIQI ABI.
#include "llama.h"
#include "gguf.h"
#include "ggml-backend.h"
#include "ggml-cpu.h"
#include <nlohmann/json.hpp>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <regex>
#include <stdexcept>
#include <thread>
#include <vector>
#include <fcntl.h>
#if defined(__ANDROID__) || defined(__linux__)
#include <sched.h>
#endif
#include <sys/stat.h>
#include <unistd.h>

using json = nlohmann::json;
namespace fs = std::filesystem;
static std::atomic<bool> cancelled{false};
static void on_signal(int) { cancelled.store(true); }
static thread_local std::function<void(const json &)> event_sink;
static void emit(const json & value) {
    if (event_sink) event_sink(value);
    else std::cout << value.dump() << std::endl;
}

static int env_int(const char * name, int fallback, int minimum, int maximum) {
    const char * value = std::getenv(name);
    if (!value || !*value) return fallback;
    char * end = nullptr;
    const long parsed = std::strtol(value, &end, 10);
    if (end == value || *end != '\0') return fallback;
    return static_cast<int>(std::clamp(parsed, static_cast<long>(minimum), static_cast<long>(maximum)));
}

static bool env_bool(const char * name, bool fallback) {
    const char * value = std::getenv(name);
    if (!value || !*value) return fallback;
    return std::strcmp(value, "1") == 0 || std::strcmp(value, "true") == 0 ||
           std::strcmp(value, "on") == 0 || std::strcmp(value, "yes") == 0;
}

static uint64_t env_u64(const char * name, uint64_t fallback) {
    const char * value = std::getenv(name);
    if (!value || !*value) return fallback;
    char * end = nullptr;
    const unsigned long long parsed = std::strtoull(value, &end, 10);
    return end == value || *end != '\0' ? fallback : static_cast<uint64_t>(parsed);
}

static uint64_t env_mask(const char * name, uint64_t fallback) {
    const char * value = std::getenv(name);
    if (!value || !*value) return fallback;
    char * end = nullptr;
    int base = 10;
    if (value[0] == '0' && (value[1] == 'x' || value[1] == 'X')) base = 16;
    const unsigned long long parsed = std::strtoull(value, &end, base);
    if (end == value || *end != '\0') return fallback;
    return static_cast<uint64_t>(parsed);
}

static bool apply_cpu_affinity(uint64_t mask) {
#if defined(__ANDROID__) || defined(__linux__)
    if (mask == 0) return true;
    cpu_set_t set;
    CPU_ZERO(&set);
    for (int cpu = 0; cpu < CPU_SETSIZE && cpu < 64; ++cpu) {
        if ((mask >> cpu) & 1ULL) CPU_SET(cpu, &set);
    }
    return sched_setaffinity(0, sizeof(set), &set) == 0;
#else
    (void) mask;
    return false;
#endif
}

static json allowed_cpu_cores() {
    json result = json::array();
#if defined(__ANDROID__) || defined(__linux__)
    cpu_set_t set;
    CPU_ZERO(&set);
    if (sched_getaffinity(0, sizeof(set), &set) == 0) {
        for (int cpu = 0; cpu < CPU_SETSIZE; ++cpu) if (CPU_ISSET(cpu, &set)) result.push_back(cpu);
    }
#endif
    return result;
}

static json mapping_stats() {
    auto cpu = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);
    if (!cpu) return {{"mappedRanges", 0}, {"mappedBytes", 0}};
    using stats_fn = void (*)(uint64_t *, uint64_t *);
    auto stats = reinterpret_cast<stats_fn>(ggml_backend_reg_get_proc_address(
        ggml_backend_dev_backend_reg(cpu), "siqi_expert_mapping_stats"));
    uint64_t ranges = 0, bytes = 0;
    if (stats) stats(&ranges, &bytes);
    return {{"mappedRanges", ranges}, {"mappedBytes", bytes}};
}

static std::string make_prompt() {
    const std::string prefix =
        "<|im_start|>system\nYou are a helpful assistant. Answer in English without reasoning.\n"
        "<|im_end|>\n<|im_start|>user\n";
    const std::string suffix =
        "\nSummarize the repeated context in one short sentence.\n"
        "<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n";
    return prefix + "Say hello and explain why the sky is blue in about 80 words." + suffix;
}

static std::vector<llama_token> tokenize(const llama_vocab * vocab,
        const std::string & text, bool add_special = false) {
    std::vector<llama_token> result(text.size() + 32);
    int n = llama_tokenize(vocab, text.data(), static_cast<int>(text.size()),
        result.data(), static_cast<int>(result.size()), add_special, true);
    if (n < 0) {
        result.resize(static_cast<size_t>(-n));
        n = llama_tokenize(vocab, text.data(), static_cast<int>(text.size()),
            result.data(), static_cast<int>(result.size()), add_special, true);
    }
    if (n <= 0) throw std::runtime_error("probe-tokenization-failed");
    result.resize(static_cast<size_t>(n));
    return result;
}

static std::vector<llama_token> prompt_tokens(const llama_vocab * vocab, int target) {
    const char * filename = std::getenv("SIQI_PROBE_PROMPT_FILE");
    if (target == 0 && !filename) return tokenize(vocab, make_prompt(), true);
    const std::string prefix = "<|im_start|>system\nYou are a helpful assistant. Answer concisely.\n"
        "<|im_end|>\n<|im_start|>user\n";
    const std::string suffix = "\nSummarize the record briefly.\n<|im_end|>\n"
        "<|im_start|>assistant\n<think>\n\n</think>\n\n";
    auto begin = tokenize(vocab, prefix, true);
    auto end = tokenize(vocab, suffix);
    const int content_count = target - static_cast<int>(begin.size() + end.size());
    if (target && content_count < 1) throw std::runtime_error("prompt-target-too-small");
    if (filename) {
        std::ifstream file(filename, std::ios::binary | std::ios::ate);
        if (!file || file.tellg() > 8 * 1024 * 1024) throw std::runtime_error("prompt-file-missing-or-too-large");
        const size_t length = static_cast<size_t>(file.tellg());
        std::string document(length, '\0'); file.seekg(0);
        if (!file.read(document.data(), static_cast<std::streamsize>(length))) throw std::runtime_error("prompt-file-read-failed");
        // Public, non-repeated document workload; never pad it by repetition.
        auto content = tokenize(vocab, document);
        if (target && content.size() < static_cast<size_t>(content_count)) throw std::runtime_error("real-document-too-short-for-target");
        const size_t count = target ? static_cast<size_t>(content_count) : content.size();
        begin.insert(begin.end(), content.begin(), content.begin() + count);
        begin.insert(begin.end(), end.begin(), end.end());
        return begin;
    }
    const std::string unit = "这是长上下文的工作区操作记录：读取文件，验证工具调用结果，输出结构化摘要。\n";
    auto content = tokenize(vocab, unit);
    begin.reserve(static_cast<size_t>(target));
    for (int i = 0; i < content_count; ++i) begin.push_back(content[static_cast<size_t>(i) % content.size()]);
    begin.insert(begin.end(), end.begin(), end.end());
    return begin;
}

static ggml_type kv_type_from_env(const char * name, ggml_type fallback) {
    const char * value = std::getenv(name);
    if (!value || !*value) return fallback;
    if (std::strcmp(value, "q4_0") == 0 || std::strcmp(value, "q4") == 0) return GGML_TYPE_Q4_0;
    if (std::strcmp(value, "q8_0") == 0 || std::strcmp(value, "q8") == 0) return GGML_TYPE_Q8_0;
    if (std::strcmp(value, "f16") == 0 || std::strcmp(value, "fp16") == 0) return GGML_TYPE_F16;
    return fallback;
}

static const char * kv_type_name(ggml_type type) {
    return ggml_type_name(type);
}

static const auto process_started = std::chrono::steady_clock::now();

struct fd_handle {
    int value;
    explicit fd_handle(const fs::path & path, int flags) : value(open(path.c_str(), flags, 0600)) {
        if (value < 0) throw std::runtime_error("file-open-failed");
    }
    ~fd_handle() { close(value); }
    fd_handle(const fd_handle &) = delete;
};

struct model_metadata {
    ggml_context * tensors = nullptr;
    gguf_context * info = nullptr;
    explicit model_metadata(const fs::path & path) {
        info = gguf_init_from_file(path.c_str(), {true, &tensors});
        if (!info) throw std::runtime_error("invalid-gguf-metadata");
    }
    ~model_metadata() { gguf_free(info); if (tensors) ggml_free(tensors); }
};

static uint32_t integer_key(gguf_context * info, const std::string & key) {
    const auto id = gguf_find_key(info, key.c_str());
    if (id < 0 || gguf_get_kv_type(info, id) != GGUF_TYPE_UINT32) {
        throw std::runtime_error("missing-uint32-model-key:" + key);
    }
    return gguf_get_val_u32(info, id);
}

static std::string architecture(gguf_context * info) {
    const auto id = gguf_find_key(info, "general.architecture");
    if (id < 0 || gguf_get_kv_type(info, id) != GGUF_TYPE_STRING) {
        throw std::runtime_error("missing-model-architecture");
    }
    return gguf_get_val_str(info, id);
}

struct expert_tensor {
    int layer;
    int family_order;
    std::string name;
    std::string family;
    std::string quant;
    uint64_t source_offset;
    uint64_t bytes;
    uint64_t bytes_per_expert;
    std::vector<int64_t> shape;
};

static std::vector<expert_tensor> routed_tensors(model_metadata & model, uint64_t source_size) {
    const std::string arch = architecture(model.info);
    const uint32_t experts = integer_key(model.info, arch + ".expert_count");
    if (experts == 0) throw std::runtime_error("model-has-no-experts");
    const std::regex pattern(R"(^blk\.([0-9]+)\.(ffn_(gate|up|down|gate_up)_exps)\.weight$)");
    const std::map<std::string, int> order = {{"ffn_gate_exps", 0}, {"ffn_up_exps", 1},
        {"ffn_down_exps", 2}, {"ffn_gate_up_exps", 3}};
    std::vector<expert_tensor> result;
    for (int64_t i = 0; i < gguf_get_n_tensors(model.info); ++i) {
        const std::string name = gguf_get_tensor_name(model.info, i);
        std::smatch match;
        if (!std::regex_match(name, match, pattern)) continue;
        const auto * t = ggml_get_tensor(model.tensors, name.c_str());
        const uint64_t bytes = gguf_get_tensor_size(model.info, i);
        const uint64_t offset = gguf_get_data_offset(model.info) + gguf_get_tensor_offset(model.info, i);
        if (!t || t->ne[2] != experts || t->ne[3] != 1 || bytes % experts != 0 ||
            offset > source_size || bytes > source_size - offset) {
            throw std::runtime_error("invalid-expert-tensor:" + name);
        }
        const std::string family = match[2];
        result.push_back({std::stoi(match[1]), order.at(family), name, family,
            ggml_type_name(t->type), offset, bytes, bytes / experts,
            {t->ne[0], t->ne[1], t->ne[2]}});
    }
    std::sort(result.begin(), result.end(), [](const auto & a, const auto & b) {
        return a.layer != b.layer ? a.layer < b.layer : a.family_order < b.family_order;
    });
    if (result.empty()) throw std::runtime_error("no-supported-routed-tensors");
    return result;
}

static void read_exact(int fd, char * data, size_t count, uint64_t offset) {
    while (count) {
        const ssize_t n = pread(fd, data, count, static_cast<off_t>(offset));
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) throw std::runtime_error("source-read-failed");
        data += n; count -= n; offset += n;
    }
}

static void copy_range(int source, int target, uint64_t from, uint64_t to, uint64_t bytes) {
    // No full-model mmap or full-tensor allocation. The copy buffer is 1 MiB.
    std::vector<char> buffer(1 << 20);
    while (bytes) {
        if (cancelled.load()) throw std::runtime_error("cancelled");
        const size_t count = std::min<uint64_t>(bytes, buffer.size());
        read_exact(source, buffer.data(), count, from);
        size_t written = 0;
        while (written < count) {
            const ssize_t n = pwrite(target, buffer.data() + written, count - written,
                static_cast<off_t>(to + written));
            if (n < 0 && errno == EINTR) continue;
            if (n <= 0) throw std::runtime_error("target-write-failed");
            written += n;
        }
        from += count; to += count; bytes -= count;
    }
}

static void pack(const fs::path & source, const fs::path & directory) {
    if (fs::exists(directory)) throw std::runtime_error("refusing-existing-output-directory");
    model_metadata model(source);
    const auto source_size = fs::file_size(source);
    const auto arch = architecture(model.info);
    const auto expert_count = integer_key(model.info, arch + ".expert_count");
    const auto expert_used = integer_key(model.info, arch + ".expert_used_count");
    if (!expert_used || expert_used > expert_count) throw std::runtime_error("invalid-topk");
    // This probe only prepares the single-file artifacts listed in SIQI's catalog.
    if (gguf_find_key(model.info, "split.count") >= 0) throw std::runtime_error("sharded-gguf-not-supported-by-probe");
    auto tensors = routed_tensors(model, source_size);
    const auto space = fs::space(directory.parent_path());
    if (space.available < source_size + (256ULL << 20)) throw std::runtime_error("insufficient-scratch-storage");
    fs::create_directory(directory);
    // A crash/cancel leaves a clearly incomplete directory, never a ready manifest.
    std::ofstream(directory / "packing.incomplete") << "Source was preserved. Packing is not complete.\n";
    fd_handle input(source, O_RDONLY);
    std::map<int, std::vector<expert_tensor>> layers;
    std::map<std::string, bool> expert_names;
    for (const auto & t : tensors) { layers[t.layer].push_back(t); expert_names[t.name] = true; }
    json entries = json::array();
    for (const auto & pair : layers) {
        const int layer = pair.first;
        const auto & group = pair.second;
        const std::string name = "layer_" + std::to_string(layer) + ".bin";
        uint64_t stride = 0;
        for (const auto & t : group) stride += t.bytes_per_expert;
        fd_handle output(directory / name, O_CREAT | O_EXCL | O_WRONLY);
        uint64_t family_offset = 0;
        for (const auto & t : group) {
            entries.push_back({{"layer", layer}, {"tensor_family", t.family}, {"tensor_name", t.name},
                {"original_gguf_tensor_name", t.name}, {"quant_type", t.quant}, {"shape", t.shape},
                {"exact_byte_length", t.bytes}, {"bytes_per_expert", t.bytes_per_expert},
                {"expert_count", expert_count}, {"repacked_file", name}, {"repacked_offset", family_offset},
                {"expert_stride", stride}, {"source_offset", t.source_offset}});
            family_offset += t.bytes_per_expert;
        }
        for (uint32_t expert = 0; expert < expert_count; ++expert) {
            family_offset = 0;
            for (const auto & t : group) {
                copy_range(input.value, output.value, t.source_offset + expert * t.bytes_per_expert,
                    expert * stride + family_offset, t.bytes_per_expert);
                family_offset += t.bytes_per_expert;
            }
        }
        if (fsync(output.value)) throw std::runtime_error("experts-fsync-failed");
        emit({{"event", "packed-layer"}, {"layer", layer}, {"bytes", stride * expert_count}});
    }
    const auto base_path = directory / "base.gguf";
    std::unique_ptr<gguf_context, decltype(&gguf_free)> base(gguf_init_empty(), gguf_free);
    gguf_set_kv(base.get(), model.info);
    for (int64_t i = 0; i < gguf_get_n_tensors(model.info); ++i) {
        const auto name = gguf_get_tensor_name(model.info, i);
        if (!expert_names.count(name)) gguf_add_tensor(base.get(), ggml_get_tensor(model.tensors, name));
    }
    if (!gguf_write_to_file(base.get(), base_path.c_str(), true)) throw std::runtime_error("base-metadata-write-failed");
    fd_handle output(base_path, O_WRONLY);
    const uint64_t base_offset = gguf_get_meta_size(base.get());
    for (int64_t i = 0; i < gguf_get_n_tensors(base.get()); ++i) {
        const auto name = gguf_get_tensor_name(base.get(), i);
        const auto original = gguf_find_tensor(model.info, name);
        copy_range(input.value, output.value,
            gguf_get_data_offset(model.info) + gguf_get_tensor_offset(model.info, original),
            base_offset + gguf_get_tensor_offset(base.get(), i), gguf_get_tensor_size(base.get(), i));
    }
    if (fsync(output.value)) throw std::runtime_error("base-fsync-failed");
    json manifest = {{"schema_version", 1}, {"experts_kind", "omni_moe_gguf"},
        {"layout", "layer_major_expert"}, {"model", {{"arch", arch}, {"expert_count", expert_count},
        {"expert_used_count", expert_used}}}, {"entries", entries},
        {"source", {{"model_bytes", source_size}}}, {"producer", "siqi-cpu-probe-v1"}};
    const auto temp_manifest = directory / "manifest.json.part";
    std::ofstream stream(temp_manifest);
    stream << manifest.dump(2) << '\n'; stream.close();
    if (!stream) throw std::runtime_error("manifest-write-failed");
    fd_handle manifest_fd(temp_manifest, O_RDONLY);
    if (fsync(manifest_fd.value)) throw std::runtime_error("manifest-fsync-failed");
    fs::rename(temp_manifest, directory / "manifest.json");
    fs::remove(directory / "packing.incomplete");
    emit({{"event", "pack-completed"}, {"baseBytes", fs::file_size(base_path)},
        {"layers", layers.size()}, {"originalPreserved", true}});
}

static void verify(const fs::path & source, const fs::path & directory) {
    model_metadata model(source);
    const auto expected = routed_tensors(model, fs::file_size(source));
    std::ifstream stream(directory / "manifest.json"); json manifest; stream >> manifest;
    const auto & entries = manifest.at("entries");
    if (entries.size() != expected.size()) throw std::runtime_error("manifest-entry-count-mismatch");
    fd_handle input(source, O_RDONLY);
    std::vector<char> original(1 << 20), packed(1 << 20);
    for (size_t index = 0; index < expected.size(); ++index) {
        const auto & t = expected[index]; const auto & entry = entries[index];
        if (entry.at("tensor_name") != t.name || entry.at("quant_type") != t.quant ||
            entry.at("shape") != t.shape || entry.at("bytes_per_expert") != t.bytes_per_expert) {
            throw std::runtime_error("manifest-metadata-mismatch");
        }
        const std::string relative = entry.at("repacked_file");
        if (fs::path(relative).filename() != relative) throw std::runtime_error("unsafe-expert-path");
        fd_handle output(directory / relative, O_RDONLY);
        for (uint32_t expert = 0; expert < entry.at("expert_count").get<uint32_t>(); ++expert) {
            uint64_t remaining = t.bytes_per_expert, done = 0;
            while (remaining) {
                if (cancelled.load()) throw std::runtime_error("cancelled");
                const size_t count = std::min<uint64_t>(remaining, original.size());
                read_exact(input.value, original.data(), count, t.source_offset + expert * t.bytes_per_expert + done);
                read_exact(output.value, packed.data(), count,
                    entry.at("repacked_offset").get<uint64_t>() + expert * entry.at("expert_stride").get<uint64_t>() + done);
                if (std::memcmp(original.data(), packed.data(), count)) throw std::runtime_error("expert-byte-mismatch");
                done += count; remaining -= count;
            }
        }
        emit({{"event", "verify-progress"}, {"verifiedExpertTensors", index + 1},
            {"totalExpertTensors", expected.size()}});
    }
    model_metadata base(directory / "base.gguf");
    if (gguf_get_n_tensors(base.info) + static_cast<int64_t>(expected.size()) != gguf_get_n_tensors(model.info) ||
        gguf_get_n_kv(base.info) != gguf_get_n_kv(model.info)) {
        throw std::runtime_error("base-metadata-count-mismatch");
    }
    fd_handle base_input(directory / "base.gguf", O_RDONLY);
    for (int64_t i = 0; i < gguf_get_n_tensors(base.info); ++i) {
        const auto name = gguf_get_tensor_name(base.info, i);
        const auto from = gguf_find_tensor(model.info, name);
        if (from < 0 || gguf_get_tensor_type(model.info, from) != gguf_get_tensor_type(base.info, i) ||
            gguf_get_tensor_size(model.info, from) != gguf_get_tensor_size(base.info, i)) {
            throw std::runtime_error("base-tensor-metadata-mismatch");
        }
        const auto * source_tensor = ggml_get_tensor(model.tensors, name);
        const auto * base_tensor = ggml_get_tensor(base.tensors, name);
        if (!source_tensor || !base_tensor) throw std::runtime_error("base-tensor-missing");
        for (int dim = 0; dim < GGML_MAX_DIMS; ++dim) {
            if (source_tensor->ne[dim] != base_tensor->ne[dim]) {
                throw std::runtime_error("base-tensor-shape-mismatch");
            }
        }
        uint64_t remaining = gguf_get_tensor_size(base.info, i), done = 0;
        while (remaining) {
            const size_t count = std::min<uint64_t>(remaining, original.size());
            read_exact(input.value, original.data(), count,
                gguf_get_data_offset(model.info) + gguf_get_tensor_offset(model.info, from) + done);
            read_exact(base_input.value, packed.data(), count,
                gguf_get_data_offset(base.info) + gguf_get_tensor_offset(base.info, i) + done);
            if (std::memcmp(original.data(), packed.data(), count)) throw std::runtime_error("base-byte-mismatch");
            done += count; remaining -= count;
        }
    }
    emit({{"event", "verify-completed"}, {"expertTensors", expected.size()},
        {"baseTensors", gguf_get_n_tensors(base.info)}, {"byteExact", true}});
}

static uint64_t process_rss() {
    std::ifstream stream("/proc/self/status"); std::string line;
    while (std::getline(stream, line)) {
        if (line.rfind("VmRSS:", 0) == 0) return std::stoull(line.substr(6)) * 1024;
    }
    return 0;
}

static json process_snapshot() {
    json result = {{"rssBytes", 0}, {"swapBytes", 0}, {"anonymousBytes", 0},
        {"fileResidentBytes", 0}, {"highWaterRssBytes", 0}, {"readBytes", nullptr}};
    std::ifstream status("/proc/self/status");
    std::string line;
    const std::map<std::string, std::string> keys = {{"VmRSS:", "rssBytes"}, {"VmSwap:", "swapBytes"},
        {"RssAnon:", "anonymousBytes"}, {"RssFile:", "fileResidentBytes"}, {"VmHWM:", "highWaterRssBytes"}};
    while (std::getline(status, line)) {
        for (const auto & key : keys) if (line.rfind(key.first, 0) == 0) {
            result[key.second] = std::stoull(line.substr(key.first.size())) * 1024;
        }
    }
    std::ifstream io("/proc/self/io");
    while (std::getline(io, line)) if (line.rfind("read_bytes:", 0) == 0) {
        result["readBytes"] = std::stoull(line.substr(11));
    }
    return result;
}

static bool abort_generation(void *) { return cancelled.load(); }

struct rss_watchdog {
    const uint64_t limit;
    std::atomic<bool> running{true};
    std::atomic<uint64_t> peak{0};
    std::atomic<uint64_t> peak_swap{0};
    std::atomic<bool> exceeded{false};
    std::thread worker;
    explicit rss_watchdog(uint64_t limit_bytes) : limit(limit_bytes), worker([this] {
        while (running.load()) {
            const auto rss = process_rss();
            peak.store(std::max(peak.load(), rss));
            const auto snapshot = process_snapshot();
            peak_swap.store(std::max(peak_swap.load(), snapshot["swapBytes"].get<uint64_t>()));
            if (limit != 0 && rss > limit) { exceeded.store(true); cancelled.store(true); }
            std::this_thread::sleep_for(std::chrono::milliseconds(200));
        }
    }) {}
    ~rss_watchdog() { running.store(false); worker.join(); }
};

static void selftest(const fs::path & directory) {
    if (fs::exists(directory)) throw std::runtime_error("refusing-existing-selftest-directory");
    fs::create_directory(directory);
    std::unique_ptr<ggml_context, decltype(&ggml_free)> tensors(
        ggml_init({4 << 20, nullptr, false}), ggml_free);
    std::unique_ptr<gguf_context, decltype(&gguf_free)> info(gguf_init_empty(), gguf_free);
    gguf_set_val_str(info.get(), "general.architecture", "qwen3moe");
    gguf_set_val_u32(info.get(), "qwen3moe.expert_count", 2);
    gguf_set_val_u32(info.get(), "qwen3moe.expert_used_count", 1);
    int seed = 1;
    for (const char * name : {"blk.0.ffn_gate_exps.weight", "blk.0.ffn_up_exps.weight", "blk.0.ffn_down_exps.weight"}) {
        auto * tensor = ggml_new_tensor_3d(tensors.get(), GGML_TYPE_F32, 32, 4, 2);
        ggml_set_name(tensor, name);
        for (int i = 0; i < 256; ++i) static_cast<float *>(tensor->data)[i] = float(seed++);
        gguf_add_tensor(info.get(), tensor);
    }
    auto * retained = ggml_new_tensor_2d(tensors.get(), GGML_TYPE_F32, 32, 8);
    ggml_set_name(retained, "token_embd.weight");
    for (int i = 0; i < 256; ++i) static_cast<float *>(retained->data)[i] = float(seed++);
    gguf_add_tensor(info.get(), retained);
    const auto source = directory / "synthetic.gguf";
    if (!gguf_write_to_file(info.get(), source.c_str(), false)) throw std::runtime_error("fixture-write-failed");
    pack(source, directory / "packed");
    verify(source, directory / "packed");
    // Prove that byte verification rejects a corrupted expert payload.
    fd_handle expert_file(directory / "packed" / "layer_0.bin", O_RDWR);
    char original; read_exact(expert_file.value, &original, 1, 0);
    const char corrupt = original ^ 0x1;
    if (pwrite(expert_file.value, &corrupt, 1, 0) != 1) throw std::runtime_error("fixture-corruption-failed");
    bool rejected = false;
    try { verify(source, directory / "packed"); }
    catch (const std::exception & error) { rejected = std::string(error.what()) == "expert-byte-mismatch"; }
    if (pwrite(expert_file.value, &original, 1, 0) != 1 || !rejected) throw std::runtime_error("corruption-not-rejected");
    verify(source, directory / "packed");
#ifdef __ANDROID__
    // Exercise the exact allocator/remap API used by LES, with synthetic data.
    // Check repeated remaps, wrong alignment, arena boundaries and short files.
    setenv("SIQI_MOE_MMAP_SLOTS", "1", 1);
    llama_backend_init();
    auto cpu = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);
    auto reg = ggml_backend_dev_backend_reg(cpu);
    using alloc_fn = ggml_backend_buffer_type_t (*)(size_t);
    using map_fn = bool (*)(ggml_backend_buffer_t, void *, size_t, int, uint64_t, bool);
    auto alloc = reinterpret_cast<alloc_fn>(ggml_backend_reg_get_proc_address(reg, "ggml_backend_dev_buffer_type_alloc_only"));
    auto remap = reinterpret_cast<map_fn>(ggml_backend_reg_get_proc_address(reg, "siqi_expert_map_readonly"));
    if (!alloc || !remap) throw std::runtime_error("mapped-slot-test-api-unavailable");
    const size_t page = static_cast<size_t>(sysconf(_SC_PAGESIZE));
    std::vector<uint8_t> fixture(3 * page);
    for (size_t i = 0; i < fixture.size(); ++i) fixture[i] = uint8_t((i * 11 + i / page * 37) % 251);
    fd_handle fixture_file(directory / "mapping.bin", O_CREAT | O_EXCL | O_RDWR);
    if (pwrite(fixture_file.value, fixture.data(), fixture.size(), 0) != (ssize_t) fixture.size()) {
        throw std::runtime_error("mapping-fixture-write-failed");
    }
    std::unique_ptr<ggml_backend_buffer, decltype(&ggml_backend_buffer_free)> arena(
        ggml_backend_buft_alloc_buffer(alloc(0), 2 * page), ggml_backend_buffer_free);
    if (!arena) throw std::runtime_error("mapping-arena-allocation-failed");
    auto * start = static_cast<uint8_t *>(ggml_backend_buffer_get_base(arena.get()));
    std::unique_ptr<ggml_backend_buffer, decltype(&ggml_backend_buffer_free)> ordinary(
        ggml_backend_buft_alloc_buffer(ggml_backend_cpu_buffer_type(), 2 * page), ggml_backend_buffer_free);
    if (remap(ordinary.get(), ggml_backend_buffer_get_base(ordinary.get()), page, fixture_file.value, 0, true)) {
        throw std::runtime_error("mapping-malloc-arena-accepted");
    }
    if (remap(arena.get(), start + 1, page, fixture_file.value, 0, true) ||
        remap(arena.get(), start, page - 1, fixture_file.value, 0, true) ||
        remap(arena.get(), start, page, fixture_file.value, 1, true) ||
        remap(arena.get(), start + page, 2 * page, fixture_file.value, 0, true) ||
        remap(arena.get(), start, page, fixture_file.value, 3 * page, true)) {
        throw std::runtime_error("mapping-invalid-range-accepted");
    }
    if (!remap(arena.get(), start, page, fixture_file.value, 0, false) ||
        memcmp(start, fixture.data(), page) ||
        !remap(arena.get(), start + page, page, fixture_file.value, page, false) ||
        memcmp(start + page, fixture.data() + page, page) ||
        !remap(arena.get(), start, page, fixture_file.value, 2 * page, false) ||
        memcmp(start, fixture.data() + 2 * page, page)) {
        throw std::runtime_error("mapping-byte-mismatch");
    }
    std::vector<uint8_t> after(fixture.size());
    read_exact(fixture_file.value, reinterpret_cast<char *>(after.data()), after.size(), 0);
    if (fixture != after) throw std::runtime_error("mapping-source-modified");
    ggml_backend_buffer_clear(arena.get(), 0);
    for (size_t i = 0; i < 2 * page; ++i) if (start[i]) throw std::runtime_error("mapping-reset-failed");
    emit({{"event", "mapped-slots-selftest-completed"}, {"pageBytes", page},
        {"rangeChecksPassed", true}, {"sourcePreserved", true}});
#endif
    emit({{"event", "selftest-completed"}, {"syntheticOnly", true}, {"corruptionRejected", true}});
}

static void benchmark(const fs::path & base, const fs::path & manifest_path) {
    const int output_limit = env_int("SIQI_PROBE_OUTPUT_TOKENS", 32, 1, 256);
    const int context = env_int("SIQI_PROBE_CONTEXT", 2048, 256, 131072);
    const int batch = env_int("SIQI_PROBE_BATCH", 64, 1, 4096);
    const int ubatch = env_int("SIQI_PROBE_UBATCH", std::min(batch, 8), 1, 1024);
    const int threads = env_int("SIQI_PROBE_THREADS", 4, 1, 64);
    const int threads_batch = env_int("SIQI_PROBE_THREADS_BATCH", threads, 1, 64);
    const int thread_poll = env_int("SIQI_PROBE_THREAD_POLL", -1, 0, 100);
    const bool adaptive_threads = env_bool("SIQI_PROBE_ADAPTIVE_THREADS", false);
    const int decode_window = env_int("SIQI_PROBE_DECODE_WINDOW", 12, 1, 256);
    const int prefetch_depth = env_int("SIQI_PROBE_PREFETCH_DEPTH", 0, 0, 16);
    const int io_threads = env_int("SIQI_PROBE_IO_THREADS", 2, 1, 32);
    const int slot_bank = env_int("SIQI_PROBE_SLOT_BANK", 64, 1, 4096);
    const int gpu_layers = env_int("SIQI_PROBE_GPU_LAYERS", 0, 0, 4096);
    const int requested_prefill_tokens = env_int("SIQI_PROBE_PREFILL_TOKENS", 0, 0, 131072);
    const int requested_prompt_tokens = env_int(
        "SIQI_PROBE_PROMPT_TOKENS", 0, 0, std::max(0, context - 32));
    const uint64_t cpu_mask = env_mask("SIQI_PROBE_CPU_MASK", 0);
    const bool cpu_affinity_applied = cpu_mask != 0 && apply_cpu_affinity(cpu_mask);
    const bool use_mmap = env_bool("SIQI_PROBE_USE_MMAP", true);
    const std::string mode = std::getenv("SIQI_PROBE_MODE") ? std::getenv("SIQI_PROBE_MODE") : "text_only";
    // This executable does not link mtmd. A flag cannot stand in for an image
    // encoder: reject vision explicitly instead of mislabelling text results.
    if (mode != "text_only") throw std::runtime_error("vision-runtime-not-linked-in-text-probe");
    const bool vision_projector_loaded = false;
    const int warmup_tokens = env_int("SIQI_PROBE_WARMUP_TOKENS", 0, 0, 128);
    const bool real_document = std::getenv("SIQI_PROBE_PROMPT_FILE") != nullptr;
    const std::string prompt_id = real_document ? "public-local-document-token-prefix-v1" : requested_prompt_tokens > 0
        ? "synthetic-repeated-zh-tools-exact-tokens-v1" : "synthetic-chatml-no-think-v2";
    const std::string phase = std::getenv("SIQI_PROBE_PHASE") ? std::getenv("SIQI_PROBE_PHASE") : "cold_start";
    const ggml_type kv_type = kv_type_from_env("SIQI_PROBE_KV_TYPE", GGML_TYPE_Q4_0);
    // Quantized V-cache is only valid with Flash Attention in the pinned runtime.
    const bool flash_attn = env_bool("SIQI_PROBE_FLASH_ATTN", kv_type != GGML_TYPE_F16);
    const uint64_t rss_limit = env_u64("SIQI_PROBE_RSS_LIMIT_BYTES", 0);
    emit({{"event", "benchmark-started"}, {"scope", "standalone-android-les-probe-not-whole-app"},
        {"runtimeRevision", "0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2"},
        {"runtimePatches", {"android-les-io", "cpu-expert-slots"}},
        {"promptId", prompt_id}, {"phase", phase}, {"mode", mode},
        {"context", context}, {"outputLimit", output_limit}, {"decodeWindow", decode_window},
        {"prefetchDepth", prefetch_depth}, {"ioThreads", io_threads}, {"slotBank", slot_bank},
        {"threads", threads}, {"threadsBatch", threads_batch}, {"batch", batch},
        {"threadPoll", thread_poll}, {"adaptiveThreads", adaptive_threads},
        {"ubatch", ubatch}, {"gpuLayers", gpu_layers}, {"kvType", kv_type_name(kv_type)},
        {"flashAttention", flash_attn}, {"useMmap", use_mmap}, {"rssLimitBytes", rss_limit},
        {"fileMappedExpertSlots", env_bool("SIQI_MOE_MMAP_SLOTS", false)},
        {"persistentIoWorkers", env_bool("SIQI_MOE_PERSISTENT_IO", true)},
        {"requestedPromptTokens", requested_prompt_tokens}, {"cpuAffinityMask", cpu_mask},
        {"cpuAffinityApplied", cpu_affinity_applied}, {"warmupRequestedTokens", warmup_tokens},
        {"visionProjectorLoaded", vision_projector_loaded}});
    std::ifstream stream(manifest_path); json manifest; stream >> manifest;
    const int topk = manifest.at("model").at("expert_used_count");
    std::map<int, bool> layers;
    for (const auto & entry : manifest.at("entries")) layers[entry.at("layer").get<int>()] = true;
    // Exact routes in every backend: no diagnostic skip/dummy-read.
    setenv("LLAMA_MOE_DECODE_WINDOW", std::to_string(decode_window).c_str(), 1);
    setenv("LLAMA_MOE_LOOKAHEAD_PREFETCH", prefetch_depth > 0 ? "1" : "0", 1);
    setenv("LLAMA_MOE_LOOKAHEAD_PREFETCH_DEPTH", std::to_string(prefetch_depth).c_str(), 1);
    setenv("LLAMA_MOE_IO_THREADS", std::to_string(io_threads).c_str(), 1);
    setenv("LLAMA_MOE_F_NOCACHE", "0", 1);
    unsetenv("LLAMA_MOE_SKIP_READ"); unsetenv("LLAMA_MOE_DUMMY_READ");
    unsetenv("LLAMA_MOE_READ_DELAY_US");
    if (topk > 12) throw std::runtime_error("topk-exceeds-probe-window");
    rss_watchdog watchdog(rss_limit);
    llama_backend_init();
    json devices = json::array();
    for (size_t i = 0; i < ggml_backend_dev_count(); ++i) {
        const auto device = ggml_backend_dev_get(i);
        devices.push_back({{"name", ggml_backend_dev_name(device)},
            {"description", ggml_backend_dev_description(device)}, {"type", ggml_backend_dev_type(device)}});
    }
    emit({{"event", "backend-capabilities"}, {"devices", devices},
        {"allowedCpuCores", allowed_cpu_cores()}, {"gpuOffloadSupported", llama_supports_gpu_offload()}});
    if (gpu_layers > 0 && !llama_supports_gpu_offload()) throw std::runtime_error("gpu-backend-not-available");
    llama_model_params mp = llama_model_default_params();
    const std::string path = manifest_path.string();
    // Keep routed experts in writable host slots in hybrid mode. Offload
    // eligible attention/shared tensors, not the whole 35B file, to Vulkan.
    llama_model_tensor_buft_override overrides[2]{};
    if (gpu_layers > 0) {
        auto cpu = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);
        auto reg = ggml_backend_dev_backend_reg(cpu);
        using alloc_only_fn = ggml_backend_buffer_type_t (*)(size_t);
        auto alloc_only = reinterpret_cast<alloc_only_fn>(ggml_backend_reg_get_proc_address(
            reg, "ggml_backend_dev_buffer_type_alloc_only"));
        if (!alloc_only) throw std::runtime_error("cpu-expert-slot-buffer-unavailable");
        overrides[0] = {"ffn_(gate|up|down|gate_up)_exps", alloc_only(0)};
        mp.tensor_buft_overrides = overrides;
    }
    // Shared prefill bank plus private per-layer decode LRU windows.
    mp.moe_experts_path = path.c_str(); mp.moe_slot_bank = slot_bank;
    mp.progress_callback = [](float, void *) { return !cancelled.load(); };
    mp.n_gpu_layers = gpu_layers; mp.use_mmap = use_mmap; mp.use_mlock = false;
    const auto load_start = std::chrono::steady_clock::now();
    std::unique_ptr<llama_model, decltype(&llama_model_free)> model(
        llama_model_load_from_file(base.c_str(), mp), llama_model_free);
    if (!model) throw std::runtime_error("les-model-load-failed");
    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = context; cp.n_batch = batch; cp.n_ubatch = ubatch;
    cp.n_threads = threads; cp.n_threads_batch = threads_batch;
    cp.no_perf = false;
    cp.op_offload = gpu_layers > 0;
    cp.offload_kqv = gpu_layers > 0;
    cp.type_k = kv_type; cp.type_v = kv_type;
    cp.flash_attn_type = flash_attn ? LLAMA_FLASH_ATTN_TYPE_ENABLED : LLAMA_FLASH_ATTN_TYPE_DISABLED;
    std::unique_ptr<ggml_threadpool, decltype(&ggml_threadpool_free)> pool(nullptr, ggml_threadpool_free);
    if (thread_poll >= 0) {
        auto pool_params = ggml_threadpool_params_default(std::max(threads, threads_batch));
        pool_params.poll = thread_poll;
        pool.reset(ggml_threadpool_new(&pool_params));
        if (!pool) throw std::runtime_error("probe-threadpool-create-failed");
    }
    std::unique_ptr<llama_context, decltype(&llama_free)> ctx(llama_init_from_model(model.get(), cp), llama_free);
    if (!ctx) throw std::runtime_error("les-context-load-failed");
    if (pool) llama_attach_threadpool(ctx.get(), pool.get(), pool.get());
    int minimum_threads = threads, maximum_threads = 0;
    auto adjust_threads = [&] {
        const int allowed = std::max<int>(1, (int) allowed_cpu_cores().size());
        const int effective = adaptive_threads ? std::min(threads, allowed) : threads;
        minimum_threads = std::min(minimum_threads, effective);
        maximum_threads = std::max(maximum_threads, effective);
        if (adaptive_threads) llama_set_n_threads(ctx.get(), effective, std::min(threads_batch, allowed));
    };
    llama_set_abort_callback(ctx.get(), abort_generation, nullptr);
    const auto context_ready = std::chrono::steady_clock::now();
    const auto loaded_snapshot = process_snapshot();
    const auto * vocab = llama_model_get_vocab(model.get());
    auto tokens = prompt_tokens(vocab, requested_prompt_tokens);
    const int n = static_cast<int>(tokens.size());
    const int prefill_tokens = requested_prefill_tokens > 0 ? std::min(requested_prefill_tokens, n) : n;
    if (prefill_tokens + warmup_tokens + output_limit > static_cast<int>(llama_n_ctx(ctx.get()))) {
        throw std::runtime_error("prompt-and-output-exceed-context");
    }
    emit({{"event", "prompt-ready"}, {"promptTokenCount", n}, {"prefillTokenCount", prefill_tokens},
        {"syntheticRepeatedContent", requested_prompt_tokens > 0 && !real_document}, {"realDocument", real_document}});
    llama_perf_context_reset(ctx.get());
    const auto prefill_start = std::chrono::steady_clock::now();
    for (int pos = 0; pos < prefill_tokens;) {
        const int count = std::min(std::min(64, batch), prefill_tokens - pos);
        if (cancelled.load()) throw std::runtime_error("cancelled-during-prefill");
        adjust_threads();
        if (llama_decode(ctx.get(), llama_batch_get_one(tokens.data() + pos, count))) {
            throw std::runtime_error("les-prefill-failed");
        }
        pos += count;
        if (requested_prompt_tokens > 0) {
            emit({{"event", "prefill-progress"}, {"evaluatedTokens", pos}, {"totalTokens", prefill_tokens},
                {"elapsedMs", std::chrono::duration<double, std::milli>(
                    std::chrono::steady_clock::now() - prefill_start).count()}});
        }
    }
    const auto prefill_end = std::chrono::steady_clock::now();
    const auto prefill_snapshot = process_snapshot();
    std::unique_ptr<llama_sampler, decltype(&llama_sampler_free)> sampler(llama_sampler_init_greedy(), llama_sampler_free);
    std::string generated;
    int decoded = 0;
    uint64_t peak_rss = process_rss();
    int warmup_decoded = 0;
    auto decode_start = std::chrono::steady_clock::now();
    const auto all_decode_start = decode_start;
    std::vector<double> token_latencies_ms;
    for (int i = 0; i < output_limit + warmup_tokens; ++i) {
        if (i == warmup_tokens) decode_start = std::chrono::steady_clock::now();
        const auto token_start = std::chrono::steady_clock::now();
        if (cancelled.load()) throw std::runtime_error("cancelled");
        adjust_threads();
        peak_rss = std::max(peak_rss, process_rss());
        // Optional diagnostic budget; zero disables it. Android thermal/LMK
        // policies still apply. This is not an allocator/whole-app guarantee.
        if (rss_limit != 0 && peak_rss > rss_limit) throw std::runtime_error("probe-rss-budget-exceeded");
        llama_token token = llama_sampler_sample(sampler.get(), ctx.get(), -1);
        if (llama_vocab_is_eog(vocab, token)) break;
        char piece[256]; const int length = llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, true);
        if (length > 0) generated.append(piece, length);
        if (llama_decode(ctx.get(), llama_batch_get_one(&token, 1))) throw std::runtime_error("les-decode-failed");
        // Count completed work, including the final token's GPU fence. Timing
        // only submission or the next logits fetch under-counts the last step.
        llama_synchronize(ctx.get());
        if (i < warmup_tokens) ++warmup_decoded;
        else {
            ++decoded;
            token_latencies_ms.push_back(std::chrono::duration<double, std::milli>(
                std::chrono::steady_clock::now() - token_start).count());
        }
    }
    const auto perf = llama_perf_context(ctx.get());
    const auto decode_end = std::chrono::steady_clock::now();
    const auto all_decode_us = std::chrono::duration_cast<std::chrono::microseconds>(decode_end - all_decode_start).count();
    const auto decode_us = std::chrono::duration_cast<std::chrono::microseconds>(decode_end - decode_start).count();
    const auto prefill_us = std::chrono::duration_cast<std::chrono::microseconds>(prefill_end - prefill_start).count();
    const auto load_us = std::chrono::duration_cast<std::chrono::microseconds>(context_ready - load_start).count();
    const auto process_us = std::chrono::duration_cast<std::chrono::microseconds>(decode_end - process_started).count();
    const auto decode_ms = decode_us / 1000.0;
    const auto prefill_ms = prefill_us / 1000.0;
    const auto load_ms = load_us / 1000.0;
    emit({{"event", "benchmark-completed"}, {"scope", "standalone-android-les-probe-not-whole-app"},
        {"runtimeRevision", "0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2"},
        {"runtimePatches", {"android-les-io", "cpu-expert-slots"}},
        {"promptId", prompt_id}, {"phase", phase}, {"mode", mode},
        {"prefillSlots", batch}, {"prefillRequestedTokens", prefill_tokens}, {"decodeWindow", decode_window},
        {"context", llama_n_ctx(ctx.get())}, {"threads", threads}, {"threadsBatch", threads_batch},
        {"batch", batch}, {"ubatch", ubatch}, {"decoded", decoded},
        {"threadPoll", thread_poll}, {"adaptiveThreads", adaptive_threads},
        {"minimumComputeThreads", minimum_threads}, {"maximumComputeThreads", maximum_threads},
        {"evalTokens", perf.n_eval}, {"evalMs", perf.t_eval_ms}, {"decodeWallMs", decode_ms},
        {"decodeTokensPerSecond", decode_us > 0 ? decoded * 1000000.0 / decode_us : 0},
        {"allDecodeWallMs", all_decode_us / 1000.0},
        {"allDecodeTokensPerSecond", all_decode_us > 0 ? (decoded + warmup_decoded) * 1000000.0 / all_decode_us : 0},
        {"prefillTokens", perf.n_p_eval}, {"prefillMs", prefill_ms},
        {"loadMs", load_ms}, {"processToResultMs", process_us / 1000.0},
        {"kvType", kv_type_name(kv_type)}, {"flashAttention", flash_attn}, {"gpuLayers", gpu_layers},
        {"fileMappedExpertSlots", env_bool("SIQI_MOE_MMAP_SLOTS", false)},
        {"persistentIoWorkers", env_bool("SIQI_MOE_PERSISTENT_IO", true)},
        {"requestedPromptTokens", requested_prompt_tokens}, {"promptTokenCount", n},
        {"cpuAffinityMask", cpu_mask}, {"cpuAffinityApplied", cpu_affinity_applied},
        {"allowedCpuCores", allowed_cpu_cores()}, {"backendDevices", devices},
        {"warmupRequestedTokens", warmup_tokens}, {"warmupDecodedTokens", warmup_decoded},
        {"tokenLatenciesMs", token_latencies_ms}, {"fullPromptEvaluated", prefill_tokens == n},
        {"visionProjectorLoaded", vision_projector_loaded},
        {"sampledDecodePeakRss", peak_rss}, {"sampledRunPeakRss", watchdog.peak.load()},
        {"sampledRunPeakSwapBytes", watchdog.peak_swap.load()},
        {"memoryAfterLoad", loaded_snapshot}, {"memoryAfterPrefill", prefill_snapshot},
        {"memoryAfterDecode", process_snapshot()},
        {"expertMappingStats", mapping_stats()},
        {"syntheticOutput", generated}});
}

#ifndef SIQI_LES_SHARED
int main(int argc, char ** argv) {
    signal(SIGINT, on_signal); signal(SIGTERM, on_signal);
    try {
        if (argc == 3 && std::string(argv[1]) == "selftest") {
            selftest(fs::absolute(argv[2]));
        } else if (argc == 3 && std::string(argv[1]) == "inspect") {
            model_metadata model(argv[2]);
            const auto tensors = routed_tensors(model, fs::file_size(argv[2]));
            uint64_t bytes = 0; for (const auto & t : tensors) bytes += t.bytes;
            emit({{"event", "inspected"}, {"architecture", architecture(model.info)},
                {"sourceBytes", fs::file_size(argv[2])}, {"expertBytes", bytes}, {"expertTensors", tensors.size()}});
        } else if (argc == 4 && std::string(argv[1]) == "pack") {
            pack(fs::canonical(argv[2]), fs::absolute(argv[3]));
        } else if (argc == 4 && std::string(argv[1]) == "verify") {
            verify(argv[2], argv[3]);
        } else if (argc == 4 && std::string(argv[1]) == "bench") {
            benchmark(argv[2], argv[3]);
        } else { throw std::runtime_error("usage: selftest <new-directory> | inspect <gguf> | pack/verify <gguf> <new-directory> | bench <base.gguf> <manifest.json>"); }
        return 0;
    } catch (const std::exception & error) {
        emit({{"event", "failed"}, {"reason", error.what()}, {"rssBytes", process_rss()}});
        return 1;
    }
}
#endif
