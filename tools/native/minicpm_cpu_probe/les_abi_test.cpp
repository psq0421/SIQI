// No weights, network, user data, or file changes: opaque ABI lifecycle test.
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <thread>

extern "C" {
int32_t siqi_les_abi_version();
int32_t siqi_les_supported_cpu();
void * siqi_les_create();
int32_t siqi_les_start(void *, const char *);
char * siqi_les_next_event(void *);
void siqi_les_string_free(char *);
void siqi_les_cancel(void *);
int32_t siqi_les_active(void *);
void siqi_les_destroy(void *);
}

static void require(bool result, const char * message) {
    if (!result) { std::cerr << message << '\n'; std::exit(1); }
}

int main() {
    require(siqi_les_abi_version() == 1, "invalid-abi");
    require(siqi_les_supported_cpu(), "unsupported-device");
    siqi_les_cancel(nullptr);
    siqi_les_destroy(nullptr);
    require(!siqi_les_active(nullptr), "null-active");
    require(!siqi_les_next_event(nullptr), "null-event");
    require(!siqi_les_start(nullptr, "{}"), "null-start");
    for (int run = 0; run < 4; ++run) {
        auto * handle = siqi_les_create();
        require(handle, "create-failed");
        require(!siqi_les_create(), "duplicate-owner-admitted");
        require(!siqi_les_start(handle, "not-json"), "invalid-json-admitted");
        auto * event = siqi_les_next_event(handle);
        require(event && std::strstr(event, "failed"), "missing-parse-error");
        siqi_les_string_free(event);
        require(siqi_les_start(handle,
            "{\"modelPath\":\"/unused\",\"context\":1,\"maxTokens\":32}"), "worker-start-failed");
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(10);
        while (siqi_les_active(handle) && std::chrono::steady_clock::now() < deadline)
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        require(!siqi_les_active(handle), "worker-did-not-finish");
        event = siqi_les_next_event(handle);
        require(event && std::strstr(event, "les-invalid-generation-settings"), "missing-validation-error");
        siqi_les_string_free(event);
        require(!siqi_les_next_event(handle), "queue-not-drained");
        siqi_les_destroy(handle);
    }
    std::cout << "{\"event\":\"les-abi-selftest-completed\",\"iterations\":4,"
        "\"modelLoaded\":false,\"sourcePreserved\":true}" << std::endl;
}
