cmake_minimum_required(VERSION 3.22.1)
project(siqi_platform)

add_library(siqi_platform SHARED siqi_affinity.cpp)
find_library(log-lib log)
target_link_libraries(siqi_platform ${log-lib})

# Optional, separately versioned text runtime. Default builds do not claim LES
# support without the pinned source, validated patches and explicit Dart flag.
if(SIQI_LES_SOURCE AND ANDROID_ABI STREQUAL "arm64-v8a")
    set(SIQI_OMNI_SOURCE "${SIQI_LES_SOURCE}" CACHE PATH "" FORCE)
    set(SIQI_BUILD_LES_LIBRARY ON CACHE BOOL "" FORCE)
    set(SIQI_ENABLE_VULKAN OFF CACHE BOOL "" FORCE)
    add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../../../../../tools/native/minicpm_cpu_probe"
        "${CMAKE_CURRENT_BINARY_DIR}/siqi-les")
endif()
