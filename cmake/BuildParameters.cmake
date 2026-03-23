# BuildParameters.cmake - Build configuration parameters for PCSX2/iPSX2

# Build type defaults
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# General compiler flags
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard" FORCE)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Platform-specific settings
if(CMAKE_SYSTEM_NAME MATCHES "iOS")
    set(CMAKE_MACOSX_RPATH ON)
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")
    message(STATUS "iOS build configuration applied")
endif()

# Compiler warning levels
if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang|Clang|GNU")
    add_compile_options(-Wall -Wextra -Wno-unknown-pragmas)
endif()

# Optimization flags
if(CMAKE_BUILD_TYPE MATCHES "Release")
    if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang|Clang|GNU")
        add_compile_options(-O3)
    endif()
endif()

message(STATUS "Build parameters configured")
