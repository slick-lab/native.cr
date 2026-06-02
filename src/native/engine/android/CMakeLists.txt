cmake_minimum_required(VERSION 3.10.2)

project(native_cr_android)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(native_cr_engine SHARED
    ../src/native/engine/android/native.c
    ../src/native/engine/android/android_native_app_glue.c
)

target_include_directories(native_cr_engine PRIVATE
    ${ANDROID_NDK}/sources/android/native_app_glue
)

target_link_libraries(native_cr_engine
    android
    log
    EGL
    GLESv2
    c
)

find_program(CRYSTAL_COMPILER crystal)
if(NOT CRYSTAL_COMPILER)
    message(FATAL_ERROR "Crystal compiler not found")
endif()

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/libcrystal_app.so
    COMMAND ${CRYSTAL_COMPILER} build
        ${CMAKE_CURRENT_SOURCE_DIR}/../src/native/engine/android/android_main.cr
        --target aarch64-linux-android
        --link-flags="-shared"
        -o ${CMAKE_CURRENT_BINARY_DIR}/libcrystal_app.so
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../src/native/engine/android/android_main.cr
    COMMENT "Building Crystal library for Android"
)

add_custom_target(crystal_build ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/libcrystal_app.so
)

add_library(crystal_app SHARED IMPORTED)
set_target_properties(crystal_app PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/libcrystal_app.so
)
add_dependencies(crystal_app crystal_build)

target_link_libraries(native_cr_engine crystal_app)
