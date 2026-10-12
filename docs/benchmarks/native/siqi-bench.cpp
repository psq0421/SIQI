// MIT. Reproducible synthetic decode probe against the packaged b10333 ABI.
// This measures native token evaluation, not chat quality or UI latency.
#include "llama.h"
#include "ggml-backend.h"
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <sys/resource.h>
#include <unistd.h>

using clock_type = std::chrono::steady_clock;
static double milliseconds(clock_type::time_point start) {
    return std::chrono::duration<double, std::milli>(clock_type::now() - start).count();
}
static clock_type::time_point deadline;
static bool abort_expired(void *) { return clock_type::now() > deadline; }
int main(int argc, char ** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "Usage: siqi-bench MODEL BACKEND_DIR [threads=4] [gpu_layers=0] [tokens=128] [kv=q8] [flash=1]\n");
        return 2;
    }
    const int threads = argc > 3 ? std::atoi(argv[3]) : 4;
    const int gpu = argc > 4 ? std::atoi(argv[4]) : 0;
    const int count = argc > 5 ? std::atoi(argv[5]) : 128;
    const bool f16 = argc > 6 && std::strcmp(argv[6], "f16") == 0;
    const bool flash = argc <= 7 || std::atoi(argv[7]) != 0;
    if (threads < 1 || threads > 12 || count < 1 || count > 512 || gpu < 0 || gpu > 24) return 2;
    ggml_backend_load_all_from_path(argv[2]);
    llama_backend_init();
    auto mp = llama_model_default_params();
    mp.n_gpu_layers = gpu;
    mp.load_mode = LLAMA_LOAD_MODE_MMAP;
    // The packaged CPU backend otherwise repacks every MXFP4 expert into a
    // second ~9.46 GiB anonymous buffer. mmap alone cannot prevent that copy.
    mp.use_extra_bufts = argc > 8 && std::atoi(argv[8]) != 0;
    auto start = clock_type::now();
    auto * model = llama_model_load_from_file(argv[1], mp);
    if (!model) { std::fprintf(stderr, "SIQI_BENCH_ERROR model-load\n"); return 3; }
    auto cp = llama_context_default_params();
    cp.n_ctx = 2048;
    cp.n_batch = 128;
    cp.n_ubatch = 64;
    cp.n_threads = threads;
    cp.n_threads_batch = threads;
    cp.type_k = f16 ? GGML_TYPE_F16 : GGML_TYPE_Q8_0;
    cp.type_v = f16 ? GGML_TYPE_F16 : GGML_TYPE_Q8_0;
    cp.flash_attn_type = flash ? LLAMA_FLASH_ATTN_TYPE_ENABLED : LLAMA_FLASH_ATTN_TYPE_DISABLED;
    cp.no_perf = false;
    cp.op_offload = gpu > 0;
    cp.abort_callback = abort_expired;
    deadline = clock_type::now() + std::chrono::minutes(5);
    auto * ctx = llama_init_from_model(model, cp);
    if (!ctx) { llama_model_free(model); return 4; }
    const double load_ms = milliseconds(start);
    const auto * vocab = llama_model_get_vocab(model);
    const char * prompt = "Write a short story about a robot planting a tree. The story begins on a quiet morning in a small garden.";
    std::vector<llama_token> tokens(128);
    const int prompt_tokens = llama_tokenize(vocab, prompt, std::strlen(prompt), tokens.data(), tokens.size(), true, true);
    if (prompt_tokens <= 0 || prompt_tokens > 128) return 5;
    auto prompt_start = clock_type::now();
    auto batch = llama_batch_get_one(tokens.data(), prompt_tokens);
    if (llama_decode(ctx, batch) != 0) return 6;
    const double prompt_ms = milliseconds(prompt_start);
    auto * sampler = llama_sampler_init_greedy();
    struct rusage before{}, after{};
    getrusage(RUSAGE_SELF, &before);
    std::fprintf(stderr, "SIQI_BENCH_STAGE decode threads=%d gpu=%d load_ms=%.3f prompt_ms=%.3f\n", threads, gpu, load_ms, prompt_ms);
    auto decode_start = clock_type::now();
    int completed = 0;
    for (int i = 0; i < count; ++i) {
        auto token = llama_sampler_sample(sampler, ctx, -1);
        auto one = llama_batch_get_one(&token, 1);
        if (llama_decode(ctx, one) != 0) break;
        ++completed;
        if (completed % 16 == 0) std::fprintf(stderr, "SIQI_BENCH_PROGRESS %d %.3fms\n", completed, milliseconds(decode_start));
    }
    const double decode_ms = milliseconds(decode_start);
    getrusage(RUSAGE_SELF, &after);
    char description[256]{};
    llama_model_desc(model, description, sizeof(description));
    std::printf("{\"schema\":1,\"runtime\":\"b10333-packaged\",\"mode\":\"synthetic-autoregressive-ignore-eog\",\"threads\":%d,\"gpuLayers\":%d,\"context\":2048,\"batch\":128,\"microBatch\":64,\"kv\":\"%s\",\"flash\":%s,\"loadMs\":%.3f,\"promptTokens\":%d,\"promptMs\":%.3f,\"tokens\":%d,\"decodeWallMs\":%.3f,\"decodeWallTps\":%.4f,\"maxRssKiB\":%ld,\"minorFaultDelta\":%ld,\"majorFaultDelta\":%ld}\n",
        threads, gpu, f16 ? "f16" : "q8_0", flash ? "true" : "false", load_ms, prompt_tokens, prompt_ms, completed, decode_ms, completed * 1000.0 / decode_ms, after.ru_maxrss, after.ru_minflt - before.ru_minflt, after.ru_majflt - before.ru_majflt);
    std::fflush(stdout);
    llama_sampler_free(sampler);
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();
    return completed == count ? 0 : 7;
}
