cmake_minimum_required(VERSION 3.22.1)
project(siqi_platform)

add_library(siqi_platform SHARED siqi_affinity.cpp)
find_library(log-lib log)
target_link_libraries(siqi_platform ${log-lib})
