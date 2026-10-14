// Separate SIQI ABI: never pass llama.cpp-omni structs to llamadart b10333.
#define SIQI_LES_SHARED 1
#include "main.cpp"
#include <deque>
#include <mutex>
#include <cmath>
#include <sys/auxv.h>
#include <asm/hwcap.h>

#define SIQI_EXPORT extern "C" __attribute__((visibility("default")))
static std::atomic<bool> runtime_owned{false};

struct les_runtime {
    std::mutex mutex;
    std::deque<std::string> events;
    std::thread worker;
    std::atomic<bool> active{false};
    std::unique_ptr<ggml_threadpool, decltype(&ggml_threadpool_free)> pool{nullptr, ggml_threadpool_free};
    std::unique_ptr<llama_model, decltype(&llama_model_free)> model{nullptr, llama_model_free};
    std::unique_ptr<llama_context, decltype(&llama_free)> context{nullptr, llama_free};
    std::string source_path;
    int loaded_context = 0, loaded_threads = 0, loaded_window = 0;
    int loaded_prefetch = 0, loaded_microbatch = 0, loaded_pool_threads = 0;
    void publish(const json & event) {
        auto serialized = event.dump(-1, ' ', false, json::error_handler_t::replace);
        std::lock_guard<std::mutex> lock(mutex);
        // Cumulative text updates can be coalesced if UI polling is slow. Never
        // drop preparation errors/completion events or grow an unbounded queue.
        if (event.value("event", "") == "text" && !events.empty() &&
            events.back().find("\"event\":\"text\"") != std::string::npos) events.back() = std::move(serialized);
        else events.push_back(std::move(serialized));
    }
};

static std::string les_prompt(const json & messages) {
    std::string prompt;
    for (const auto & message : messages) {
        const auto role = message.at("role").get<std::string>();
        if (role != "system" && role != "user" && role != "assistant" && role != "tool") throw std::runtime_error("invalid-message-role");
        prompt += "<|im_start|>" + role + "\n" + message.at("content").get<std::string>() + "<|im_end|>\n";
    }
    return prompt + "<|im_start|>assistant\n<think>\n\n</think>\n\n";
}

static json cpu_frequencies() {
    json result = json::array();
    for (int policy : {0, 4, 7}) {
        json item = {{"policy", policy}};
        for (const char * name : {"scaling_cur_freq", "scaling_max_freq", "cpuinfo_max_freq"}) {
            std::ifstream input("/sys/devices/system/cpu/cpufreq/policy" + std::to_string(policy) + "/" + name);
            uint64_t frequency = 0;
            item[name] = input >> frequency ? json(frequency) : json(nullptr);
        }
        result.push_back(item);
    }
    return result;
}

static fs::path prepare_les(const fs::path & source, const fs::path & root) {
    if (!source.is_absolute() || !root.is_absolute()) throw std::runtime_error("les-paths-must-be-absolute");
    // root is a per-artifact app-private directory supplied by the trusted app.
    // Do not use a client-supplied path, reuse arbitrary files, or remove weights.
    fs::create_directories(root);
    const json identity = {{"schema", 2}, {"source", fs::canonical(source).string()},
        {"sourceBytes", fs::file_size(source)}, {"sourceModified", fs::last_write_time(source).time_since_epoch().count()}};
    const auto packed = root / "packed-v2";
    if (fs::exists(packed / "ready.json")) {
        std::ifstream input(packed / "ready.json"); json previous; input >> previous;
        if (previous != identity) throw std::runtime_error("les-cache-source-changed-clear-this-model-cache");
        if (!fs::exists(packed / "manifest.json") || !fs::exists(packed / "base.gguf")) throw std::runtime_error("les-cache-incomplete");
        return packed;
    }
    model_metadata metadata(source);
    if (architecture(metadata.info) != "qwen35moe") throw std::runtime_error("les-runtime-model-architecture-unsupported");
    // Packing temporarily needs a full derivative copy. Disk free space is not
    // RAM availability and must be checked independently before doing any work.
    if (fs::space(root).available < fs::file_size(source) + 256 * 1024 * 1024ULL) throw std::runtime_error("les-pack-insufficient-storage");
    const auto staging = root / ("staging-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    try {
        emit({{"event", "preparing"}, {"sourceBytes", fs::file_size(source)}});
        pack(source, staging);
        verify(source, staging);
        if (cancelled.load()) throw std::runtime_error("cancelled");
        std::ofstream ready(staging / "ready.json", std::ios::binary);
        ready << identity.dump(); ready.close();
        if (!ready) throw std::runtime_error("les-ready-marker-write-failed");
        fs::rename(staging, packed);
    } catch (...) {
        // Only this invocation's new, validated child is removed. The original
        // model and completed caches are never deletion targets.
        std::error_code ignored; fs::remove_all(staging, ignored);
        throw;
    }
    return packed;
}

static void les_generate(les_runtime & runtime, json request) {
    const auto started = std::chrono::steady_clock::now();
    const auto source = request.at("modelPath").get<std::string>();
    const int requested_context = request.at("context").get<int>();
    const int threads = request.value("threads", 4);
    const int expert_window = request.value("expertWindow", 56);
    const int prefetch_depth = request.value("prefetchDepth", 4);
    const int microbatch = request.value("microBatchSize", 8);
    const bool thread_sweep = request.value("decodeThreadSweep", false);
    const int pool_threads = thread_sweep ? 8 : threads;
    const int maximum_output = request.at("maxTokens").get<int>();
    const float temperature = request.value("temperature", 0.7f);
    const float top_p = request.value("topP", 0.9f);
    if (requested_context < 2048 || requested_context > 131072 || threads < 1 || threads > 8 ||
        expert_window < 16 || expert_window > 128 ||
        prefetch_depth < 0 || prefetch_depth > 4 || microbatch < 1 || microbatch > 16 ||
        maximum_output < 1 || maximum_output >= requested_context || !std::isfinite(temperature) ||
        !std::isfinite(top_p) || temperature < 0 || temperature > 2 || top_p <= 0 || top_p > 1) throw std::runtime_error("les-invalid-generation-settings");
    if (thread_sweep && (temperature > 0 || maximum_output > 64)) throw std::runtime_error("les-sweep-requires-greedy-output-at-most64");
    auto messages = request.at("messages");
    if (!messages.is_array() || messages.empty() || messages.size() > 10000) throw std::runtime_error("les-invalid-messages");
    const bool reused = runtime.model && runtime.context && runtime.source_path == source &&
        runtime.loaded_context == requested_context && runtime.loaded_threads == threads && runtime.loaded_window == expert_window &&
        runtime.loaded_prefetch == prefetch_depth && runtime.loaded_microbatch == microbatch &&
        runtime.loaded_pool_threads == pool_threads;
    if (!reused) {
        runtime.context.reset(); runtime.model.reset();
        runtime.pool.reset();
        const auto directory = prepare_les(source, request.at("cacheDirectory").get<std::string>());
        if (cancelled.load()) throw std::runtime_error("cancelled");
        // Isolated runtime-specific settings. No skip-read or dummy weights.
        setenv("SIQI_MOE_MMAP_SLOTS", "1", 1);
        setenv("LLAMA_MOE_DECODE_WINDOW", std::to_string(expert_window).c_str(), 1);
        setenv("LLAMA_MOE_IO_THREADS", "4", 1);
        setenv("LLAMA_MOE_LOOKAHEAD_PREFETCH", prefetch_depth ? "1" : "0", 1);
        setenv("LLAMA_MOE_LOOKAHEAD_PREFETCH_DEPTH", std::to_string(std::max(1, prefetch_depth)).c_str(), 1);
        setenv("LLAMA_MOE_F_NOCACHE", "0", 1);
        unsetenv("LLAMA_MOE_SKIP_READ"); unsetenv("LLAMA_MOE_DUMMY_READ");
        unsetenv("LLAMA_MOE_READ_DELAY_US");
        llama_backend_init();
        const auto manifest = (directory / "manifest.json").string();
        auto params = llama_model_default_params();
        params.n_gpu_layers = 0; params.use_mmap = true;
        params.moe_experts_path = manifest.c_str(); params.moe_slot_bank = 128;
        params.progress_callback = [](float, void *) { return !cancelled.load(); };
        emit({{"event", "loading"}});
        runtime.model.reset(llama_model_load_from_file((directory / "base.gguf").c_str(), params));
        if (!runtime.model) throw std::runtime_error("les-model-load-failed");
        auto context_params = llama_context_default_params();
        context_params.n_ctx = requested_context; context_params.n_batch = 64; context_params.n_ubatch = microbatch;
        context_params.n_threads = threads; context_params.n_threads_batch = threads;
        context_params.type_k = GGML_TYPE_Q4_0; context_params.type_v = GGML_TYPE_Q4_0;
        context_params.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_ENABLED;
        context_params.op_offload = false; context_params.offload_kqv = false; context_params.no_perf = false;
        runtime.context.reset(llama_init_from_model(runtime.model.get(), context_params));
        if (!runtime.context) throw std::runtime_error("les-context-load-failed");
        auto pool_params = ggml_threadpool_params_default(pool_threads);
        pool_params.poll = 0; // sleep instead of burning scarce/removed cpuset cores
        runtime.pool.reset(ggml_threadpool_new(&pool_params));
        if (!runtime.pool) throw std::runtime_error("les-threadpool-create-failed");
        llama_attach_threadpool(runtime.context.get(), runtime.pool.get(), runtime.pool.get());
        llama_set_abort_callback(runtime.context.get(), abort_generation, nullptr);
        runtime.source_path = source; runtime.loaded_context = requested_context; runtime.loaded_threads = threads;
        runtime.loaded_window = expert_window;
        runtime.loaded_prefetch = prefetch_depth; runtime.loaded_microbatch = microbatch;
        runtime.loaded_pool_threads = pool_threads;
    } else llama_memory_clear(llama_get_memory(runtime.context.get()), true);
    const auto loaded = std::chrono::steady_clock::now();
    const auto * vocab = llama_model_get_vocab(runtime.model.get());
    auto tokens = tokenize(vocab, les_prompt(messages), true);
    const size_t original_input_tokens = tokens.size();
    const int message_count = (int) messages.size();
    // Fit by removing complete oldest turns. Keep the system message and final
    // user input; never pretend a truncated history populated 128K.
    while ((int) tokens.size() + maximum_output + 32 > requested_context && messages.size() > 2) {
        const int first = messages[0].value("role", "") == "system" ? 1 : 0;
        messages.erase(messages.begin() + first);
        if (messages.size() > 2 && messages[first].value("role", "") == "assistant") messages.erase(messages.begin() + first);
        tokens = tokenize(vocab, les_prompt(messages), true);
    }
    if ((int) tokens.size() + maximum_output + 32 > requested_context) throw std::runtime_error("les-input-and-output-exceed-context");
    llama_perf_context_reset(runtime.context.get());
    const auto prefill_started = std::chrono::steady_clock::now();
    for (size_t pos = 0; pos < tokens.size();) {
        if (cancelled.load()) throw std::runtime_error("cancelled");
        const int available_threads = std::max<int>(1, (int) allowed_cpu_cores().size());
        llama_set_n_threads(runtime.context.get(), std::min(threads, available_threads), std::min(threads, available_threads));
        const int count = (int) std::min<size_t>(64, tokens.size() - pos);
        if (llama_decode(runtime.context.get(), llama_batch_get_one(tokens.data() + pos, count))) throw std::runtime_error("les-prefill-failed");
        pos += count;
        emit({{"event", "prefill-progress"}, {"evaluatedTokens", pos}, {"totalTokens", tokens.size()}});
    }
    llama_synchronize(runtime.context.get());
    const auto prefill_finished = std::chrono::steady_clock::now();
    if (thread_sweep) {
        // Diagnostic only: replay identical complete KV/recurrent/logit state.
        // No synthetic filling, skipped prefill or context pruning. File-cache
        // residency/order is NOT reset, so this is exploratory, not fair A/B.
        const size_t state_size = llama_state_get_size(runtime.context.get());
        if (!state_size || state_size > 256 * 1024 * 1024ULL) throw std::runtime_error("les-sweep-state-too-large");
        std::vector<uint8_t> state(state_size);
        const size_t saved = llama_state_get_data(runtime.context.get(), state.data(), state.size());
        if (!saved || saved > state.size()) throw std::runtime_error("les-sweep-state-save-failed");
        state.resize(saved);
        json variants = json::array();
        std::vector<llama_token> baseline_tokens;
        std::string baseline_text;
        for (int candidate : {4, 2, 6, 8}) {
            if (cancelled.load()) throw std::runtime_error("cancelled");
            if (llama_state_set_data(runtime.context.get(), state.data(), state.size()) != saved)
                throw std::runtime_error("les-sweep-state-restore-failed");
            std::unique_ptr<llama_sampler, decltype(&llama_sampler_free)> sampler(llama_sampler_init_greedy(), llama_sampler_free);
            std::vector<double> times;
            std::vector<llama_token> generated_tokens;
            std::string generated_text;
            int minimum_threads = candidate, maximum_threads = 0;
            const auto frequencies_before = cpu_frequencies();
            const auto mapping_before = mapping_stats();
            const auto started_decode = std::chrono::steady_clock::now();
            for (int i = 0; i < maximum_output; ++i) {
                if (cancelled.load()) throw std::runtime_error("cancelled");
                const int effective = std::min<int>(candidate, std::max<int>(1, (int) allowed_cpu_cores().size()));
                minimum_threads = std::min(minimum_threads, effective);
                maximum_threads = std::max(maximum_threads, effective);
                llama_set_n_threads(runtime.context.get(), effective, effective);
                const auto tick = std::chrono::steady_clock::now();
                auto token = llama_sampler_sample(sampler.get(), runtime.context.get(), -1);
                if (llama_vocab_is_eog(vocab, token)) break;
                llama_sampler_accept(sampler.get(), token);
                std::vector<char> piece(256);
                int n = llama_token_to_piece(vocab, token, piece.data(), (int) piece.size(), 0, false);
                if (n < 0) { piece.resize((size_t) -n); n = llama_token_to_piece(vocab, token, piece.data(), (int) piece.size(), 0, false); }
                if (n > 0) generated_text.append(piece.data(), (size_t) n);
                if (llama_decode(runtime.context.get(), llama_batch_get_one(&token, 1))) throw std::runtime_error("les-sweep-decode-failed");
                llama_synchronize(runtime.context.get());
                times.push_back(std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - tick).count());
                generated_tokens.push_back(token);
            }
            if (generated_tokens.empty()) throw std::runtime_error("les-sweep-empty-output");
            const double duration = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - started_decode).count();
            const size_t warmup = std::min<size_t>(8, times.size());
            double hot_ms = 0;
            for (size_t i = warmup; i < times.size(); ++i) hot_ms += times[i];
            if (variants.empty()) { baseline_tokens = generated_tokens; baseline_text = generated_text; }
            const auto mapping_after = mapping_stats();
            variants.push_back({{"requestedThreads", candidate}, {"minimumComputeThreads", minimum_threads},
                {"maximumComputeThreads", maximum_threads}, {"allowedCpuCores", allowed_cpu_cores()},
                {"evalTokens", times.size()}, {"evalMs", duration},
                {"decodeTokensPerSecond", times.size() * 1000.0 / duration},
                {"warmupDecodedTokens", warmup}, {"hotDecodeTokens", times.size() - warmup}, {"hotDecodeMs", hot_ms},
                {"hotDecodeTokensPerSecond", hot_ms > 0 ? (times.size() - warmup) * 1000.0 / hot_ms : 0},
                {"tokenSequenceMatchesBaseline", generated_tokens == baseline_tokens}, {"tokenLatenciesMs", times},
                {"cpuFrequenciesBeforeKHz", frequencies_before}, {"cpuFrequenciesAfterKHz", cpu_frequencies()},
                {"mappedRangesDelta", mapping_after["mappedRanges"].get<uint64_t>() - mapping_before["mappedRanges"].get<uint64_t>()},
                {"mappedBytesDelta", mapping_after["mappedBytes"].get<uint64_t>() - mapping_before["mappedBytes"].get<uint64_t>()},
                {"memoryAfterDecode", process_snapshot()}});
            emit({{"event", "decode-sweep-progress"}, {"completedVariants", variants.size()}, {"totalVariants", 4},
                {"variant", variants.back()}});
        }
        auto performance = variants[0]; // Report baseline, never select the fastest variant.
        performance["runtime"] = "siqi-les-abi1";
        performance["runtimeRevision"] = "0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2";
        performance["effectiveContext"] = requested_context;
        performance["effectiveBackend"] = "CPU-LES-file-mapped";
        performance["effectiveGpuLayers"] = 0;
        performance["requestedMode"] = "text_only";
        performance["visionProjectorLoaded"] = false;
        performance["cacheType"] = "q4_0";
        performance["expertWindow"] = expert_window;
        performance["expertSlotBank"] = 128;
        performance["prefetchDepth"] = prefetch_depth;
        performance["batchSize"] = 64;
        performance["microBatchSize"] = microbatch;
        performance["adaptiveThreads"] = true;
        performance["threadPoll"] = 0;
        performance["coldLoad"] = !reused;
        performance["inputTokensBeforeFitting"] = original_input_tokens;
        performance["inputTokensAfterFitting"] = tokens.size();
        performance["fullPromptEvaluated"] = true;
        performance["historyWasReduced"] = (int) messages.size() != message_count;
        performance["loadWallMs"] = std::chrono::duration<double, std::milli>(loaded - started).count();
        performance["promptEvalMs"] = std::chrono::duration<double, std::milli>(prefill_finished - prefill_started).count();
        performance["decodeThreadSweep"] = {{"schema", 1}, {"stateBytes", saved}, {"order", {4,2,6,8}},
            {"samePrefilledState", true}, {"cacheOrderControlled", false}, {"variants", variants}};
        emit({{"event", "text"}, {"text", baseline_text}});
        emit({{"event", "completed"}, {"text", baseline_text}, {"inputTokens", tokens.size()},
            {"outputTokens", baseline_tokens.size()}, {"performance", performance}});
        return;
    }
    std::unique_ptr<llama_sampler, decltype(&llama_sampler_free)> sampler(nullptr, llama_sampler_free);
    if (temperature <= 0) sampler.reset(llama_sampler_init_greedy());
    else {
        sampler.reset(llama_sampler_chain_init(llama_sampler_chain_default_params()));
        llama_sampler_chain_add(sampler.get(), llama_sampler_init_top_k(40));
        llama_sampler_chain_add(sampler.get(), llama_sampler_init_top_p(top_p, 1));
        llama_sampler_chain_add(sampler.get(), llama_sampler_init_temp(temperature));
        llama_sampler_chain_add(sampler.get(), llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    }
    std::string text;
    std::vector<double> latencies;
    int decoded = 0;
    for (; decoded < maximum_output; ++decoded) {
        if (cancelled.load()) throw std::runtime_error("cancelled");
        const int available_threads = std::max<int>(1, (int) allowed_cpu_cores().size());
        llama_set_n_threads(runtime.context.get(), std::min(threads, available_threads), std::min(threads, available_threads));
        const auto tick = std::chrono::steady_clock::now();
        auto token = llama_sampler_sample(sampler.get(), runtime.context.get(), -1);
        if (llama_vocab_is_eog(vocab, token)) break;
        llama_sampler_accept(sampler.get(), token);
        std::vector<char> piece(256);
        int length = llama_token_to_piece(vocab, token, piece.data(), (int) piece.size(), 0, false);
        if (length < 0) { piece.resize((size_t) -length); length = llama_token_to_piece(vocab, token, piece.data(), (int) piece.size(), 0, false); }
        if (length > 0) text.append(piece.data(), (size_t) length);
        if (llama_decode(runtime.context.get(), llama_batch_get_one(&token, 1))) throw std::runtime_error("les-decode-failed");
        llama_synchronize(runtime.context.get());
        latencies.push_back(std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - tick).count());
        try { (void) json(text).dump(); emit({{"event", "text"}, {"text", text}}); }
        catch (const json::type_error &) { /* wait for a complete UTF-8 codepoint */ }
    }
    if (text.empty()) throw std::runtime_error("les-empty-output");
    const auto finished = std::chrono::steady_clock::now();
    const double decode_ms = std::chrono::duration<double, std::milli>(finished - prefill_finished).count();
    const size_t warm_tokens = std::min<size_t>(8, latencies.size());
    double hot_decode_ms = 0;
    for (size_t i = warm_tokens; i < latencies.size(); ++i) hot_decode_ms += latencies[i];
    const size_t hot_tokens = latencies.size() - warm_tokens;
    emit({{"event", "completed"}, {"text", text}, {"inputTokens", tokens.size()}, {"outputTokens", decoded},
        {"performance", {{"runtime", "siqi-les-abi1"}, {"runtimeRevision", "0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2"},
        {"effectiveContext", requested_context}, {"effectiveBackend", "CPU-LES-file-mapped"}, {"effectiveGpuLayers", 0},
        {"requestedMode", "text_only"}, {"visionProjectorLoaded", false}, {"cacheType", "q4_0"},
        {"requestedThreads", threads}, {"threads", llama_n_threads(runtime.context.get())},
        {"expertWindow", expert_window}, {"expertSlotBank", 128}, {"prefetchDepth", prefetch_depth},
        {"batchSize", 64}, {"microBatchSize", microbatch},
        {"adaptiveThreads", true}, {"threadPoll", 0}, {"coldLoad", !reused}, {"inputTokensAfterFitting", tokens.size()},
        {"inputTokensBeforeFitting", original_input_tokens}, {"fullPromptEvaluated", true},
        {"historyWasReduced", (int) messages.size() != message_count},
        {"historyMessagesBeforeFitting", message_count}, {"historyMessagesAfterFitting", messages.size()},
        {"loadWallMs", std::chrono::duration<double, std::milli>(loaded - started).count()},
        {"promptEvalMs", std::chrono::duration<double, std::milli>(prefill_finished - prefill_started).count()},
        {"evalTokens", decoded}, {"evalMs", decode_ms}, {"decodeTokensPerSecond", decode_ms > 0 ? decoded * 1000.0 / decode_ms : 0},
        {"warmupDecodedTokens", warm_tokens}, {"hotDecodeTokens", hot_tokens}, {"hotDecodeMs", hot_decode_ms},
        {"hotDecodeTokensPerSecond", hot_decode_ms > 0 ? hot_tokens * 1000.0 / hot_decode_ms : 0},
        {"tokenLatenciesMs", latencies}, {"expertMappingStats", mapping_stats()}, {"memoryAfterDecode", process_snapshot()}}}});
}

SIQI_EXPORT int32_t siqi_les_abi_version() { return 1; }
SIQI_EXPORT int32_t siqi_les_supported_cpu() {
    // ggml is built for this ISA, but this entry point is built for baseline
    // arm64. Reject devices without the instructions before initializing it.
    return (getauxval(AT_HWCAP) & HWCAP_ASIMDDP) && (getauxval(AT_HWCAP) & HWCAP_ASIMDHP) &&
        (getauxval(AT_HWCAP2) & HWCAP2_I8MM);
}
SIQI_EXPORT void * siqi_les_create() {
    if (!siqi_les_supported_cpu() || runtime_owned.exchange(true)) return nullptr;
    auto * result = new (std::nothrow) les_runtime;
    if (!result) runtime_owned.store(false);
    return result;
}
SIQI_EXPORT int32_t siqi_les_start(void * handle, const char * serialized) {
    auto * runtime = static_cast<les_runtime *>(handle);
    if (!runtime || !serialized || runtime->active.exchange(true)) return 0;
    try {
        if (runtime->worker.joinable()) runtime->worker.join();
        { std::lock_guard<std::mutex> lock(runtime->mutex); runtime->events.clear(); }
        if (strlen(serialized) > 8 * 1024 * 1024) throw std::runtime_error("les-request-too-large");
        auto request = json::parse(serialized);
        cancelled.store(false);
        runtime->worker = std::thread([runtime, request = std::move(request)]() mutable {
            event_sink = [runtime](const json & event) { runtime->publish(event); };
            try { les_generate(*runtime, std::move(request)); }
            catch (const std::exception & error) {
                runtime->context.reset(); runtime->model.reset();
                runtime->publish({{"event", "failed"}, {"reason", error.what()}, {"cancelled", cancelled.load()}});
            }
            event_sink = {}; runtime->active.store(false);
        });
        return 1;
    } catch (const std::exception & error) {
        runtime->publish({{"event", "failed"}, {"reason", error.what()}});
        runtime->active.store(false); return 0;
    }
}
SIQI_EXPORT char * siqi_les_next_event(void * handle) {
    auto * runtime = static_cast<les_runtime *>(handle);
    if (!runtime) return nullptr;
    std::lock_guard<std::mutex> lock(runtime->mutex);
    if (runtime->events.empty()) return nullptr;
    char * result = strdup(runtime->events.front().c_str());
    if (result) runtime->events.pop_front();
    return result;
}
SIQI_EXPORT void siqi_les_string_free(char * value) { free(value); }
SIQI_EXPORT void siqi_les_cancel(void * handle) { if (handle) cancelled.store(true); }
SIQI_EXPORT int32_t siqi_les_active(void * handle) {
    return handle && static_cast<les_runtime *>(handle)->active.load();
}
SIQI_EXPORT void siqi_les_destroy(void * handle) {
    auto * runtime = static_cast<les_runtime *>(handle);
    if (!runtime) return;
    cancelled.store(true);
    if (runtime->worker.joinable()) runtime->worker.join();
    delete runtime; runtime_owned.store(false);
}
