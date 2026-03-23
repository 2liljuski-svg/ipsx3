# Pcsx2Utils.cmake - Utility functions for PCSX2/iPSX2 build

# Check that the path doesn't contain parentheses (which can break some tools)
function(check_no_parenthesis_in_path)
    if(CMAKE_CURRENT_SOURCE_DIR MATCHES "\\(|\\)")
        message(FATAL_ERROR "PCSX2 does not support parentheses in the source path: ${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
endfunction()

# Detect the operating system (basic detection, most is handled by CMake)
function(detect_operating_system)
    if(CMAKE_SYSTEM_NAME MATCHES "iOS")
        message(STATUS "Detected iOS/tvOS")
    elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
        message(STATUS "Detected macOS")
    elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
        message(STATUS "Detected Linux")
    elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
        message(STATUS "Detected Windows")
    elseif(CMAKE_SYSTEM_NAME MATCHES "Android")
        message(STATUS "Detected Android")
    else()
        message(STATUS "Detected ${CMAKE_SYSTEM_NAME}")
    endif()
endfunction()

# Detect the C/C++ compiler being used
function(detect_compiler)
    if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang")
        message(STATUS "Detected Apple Clang ${CMAKE_CXX_COMPILER_VERSION}")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        message(STATUS "Detected Clang ${CMAKE_CXX_COMPILER_VERSION}")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        message(STATUS "Detected GCC ${CMAKE_CXX_COMPILER_VERSION}")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
        message(STATUS "Detected MSVC ${CMAKE_CXX_COMPILER_VERSION}")
    else()
        message(STATUS "Detected ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
    endif()
endfunction()

# Get git version information
function(get_git_version_info)
    find_package(Git QUIET)
    if(GIT_FOUND)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_SHORT_HASH
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        set(GIT_SHORT_HASH "${GIT_SHORT_HASH}" CACHE STRING "Git short hash" FORCE)
    endif()
endfunction()

# Write SVN revision header file (stub - not applicable for git)
function(write_svnrev_h)
    # This is a stub for PCSX2 compatibility
    # In PCSX2, this writes SVN revision info; we'll use git instead
    set(SVN_REV "0" PARENT_SCOPE)
endfunction()
