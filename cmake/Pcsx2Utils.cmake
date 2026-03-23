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

# Setup file properties for targets (e.g., set correct file types for Xcode)
function(fixup_file_properties target)
    get_target_property(SOURCES ${target} SOURCES)
    if(APPLE)
        foreach(source IN LISTS SOURCES)
            # Set the right file types for .inl and .h files in Xcode
            if("${source}" MATCHES "\\.(inl|h)$")
                set_source_files_properties("${source}" PROPERTIES XCODE_EXPLICIT_FILE_TYPE sourcecode.cpp.h)
            endif()
            # Set file type for compiled Qt translation files
            if("${source}" MATCHES "\\.(qm)$")
                set_source_files_properties("${source}" PROPERTIES XCODE_EXPLICIT_FILE_TYPE compiled)
            endif()
            # CMake makefile and ninja generators will attempt to share one PCH for both cpp and mm files
            # That's not actually OK
            if("${source}" MATCHES "\\.mm$")
                set_source_files_properties("${source}" PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
            endif()
        endforeach()
    endif()
endfunction()

# Get recursive include directories from a target
function(get_recursive_include_directories output target inc_prop link_prop)
    set(dirs)
    get_target_property(inc_dirs ${target} ${inc_prop})
    if(inc_dirs)
        list(APPEND dirs ${inc_dirs})
    endif()
    
    get_target_property(link_libs ${target} ${link_prop})
    if(link_libs)
        foreach(lib IN LISTS link_libs)
            if(TARGET ${lib})
                get_target_property(lib_inc_dirs ${lib} ${inc_prop})
                if(lib_inc_dirs)
                    list(APPEND dirs ${lib_inc_dirs})
                endif()
            endif()
        endforeach()
    endif()
    
    list(REMOVE_DUPLICATES dirs)
    set(${output} "${dirs}" PARENT_SCOPE)
endfunction()

# Force an include directory to be processed last (to avoid conflicts)
function(force_include_last_impl target include inc_prop link_prop)
    get_recursive_include_directories(dirs ${target} ${inc_prop} ${link_prop})
    set(remove)
    foreach(dir IN LISTS dirs)
        if("${dir}" MATCHES "${include}")
            list(APPEND remove ${dir})
        endif()
    endforeach()
    
    if(NOT "${remove}" STREQUAL "")
        get_target_property(sysdirs ${target} INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
        if(NOT sysdirs)
            set(sysdirs)
        endif()
        
        # Move matching items to the end
        list(REMOVE_ITEM dirs ${remove})
        list(APPEND dirs ${remove})
        
        # Set them as system include directories
        list(APPEND sysdirs ${remove})
        list(REMOVE_DUPLICATES sysdirs)
        
        set_target_properties(${target} PROPERTIES
            ${inc_prop} "${dirs}"
            INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${sysdirs}")
    endif()
endfunction()

# Public wrapper for force_include_last_impl
function(force_include_last target include)
    force_include_last_impl(${target} "${include}" INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES)
endfunction()
