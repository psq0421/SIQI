#include <jni.h>
#include <sched.h>
#include <stdint.h>

extern "C" JNIEXPORT jboolean JNICALL
Java_com_psq_siqi_MainActivity_setCpuAffinityNative(
        JNIEnv *, jobject, jlong mask) {
    cpu_set_t set;
    CPU_ZERO(&set);
    for (int cpu = 0; cpu < CPU_SETSIZE && cpu < 63; ++cpu) {
        if ((static_cast<uint64_t>(mask) >> cpu) & 1ULL) CPU_SET(cpu, &set);
    }
    return sched_setaffinity(0, sizeof(set), &set) == 0 ? JNI_TRUE : JNI_FALSE;
}
