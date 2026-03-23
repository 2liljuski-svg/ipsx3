# Pcsx2Utils.cmake - Utility functions for PCSX2 build

# Check that the path doesn't contain parentheses (which can break some tools)
function(check_no_parenthesis_in_path)
	if ("${CMAKE_BINARY_DIR}" MATCHES "[()]" OR "${CMAKE_SOURCE_DIR}" MATCHES "[()]")
		message(FATAL_ERROR "Your path contains some parenthesis. Unfortunately Cmake doesn't support them correctly.\nPlease rename your directory to avoid '(' and ')' characters\n")
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
	else()
		set(GIT_SHORT_HASH "Unknown" CACHE STRING "Git short hash" FORCE)
	endif()

	if(GIT_FOUND)
		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} describe --tags
			OUTPUT_VARIABLE PCSX2_GIT_REV
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)

		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} tag --points-at HEAD --sort=version:refname
			OUTPUT_VARIABLE PCSX2_GIT_TAG_LIST
			RESULT_VARIABLE TAG_RESULT
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)

		# CAUTION: There is a race here, this solves the problem of a commit being tagged multiple times (take the last tag)
		# however, if simultaneous builds are pushing tags to the same commit you might get inconsistent results (it's a race)
		#
		# The easy solution is, don't do that, but just something to be aware of.
		if(PCSX2_GIT_TAG_LIST AND TAG_RESULT EQUAL 0)
			string(REPLACE "\n" ";" PCSX2_GIT_TAG_LIST "${PCSX2_GIT_TAG_LIST}")
			if (PCSX2_GIT_TAG_LIST)
				list(GET PCSX2_GIT_TAG_LIST -1 PCSX2_GIT_TAG)
				message("Using tag: ${PCSX2_GIT_TAG}")
			endif()
		endif()

		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
			OUTPUT_VARIABLE PCSX2_GIT_HASH
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)

		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} log -1 --format=%cd --date=local
			OUTPUT_VARIABLE PCSX2_GIT_DATE
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)
	else()
		set(PCSX2_GIT_REV "Unknown")
		set(PCSX2_GIT_TAG "Unknown")
		set(PCSX2_GIT_HASH "Unknown")
		set(PCSX2_GIT_DATE "Unknown")
	endif()

	set(PCSX2_GIT_REV "${PCSX2_GIT_REV}" PARENT_SCOPE)
	set(PCSX2_GIT_TAG "${PCSX2_GIT_TAG}" PARENT_SCOPE)
	set(PCSX2_GIT_HASH "${PCSX2_GIT_HASH}" PARENT_SCOPE)
	set(PCSX2_GIT_DATE "${PCSX2_GIT_DATE}" PARENT_SCOPE)
endfunction()

# Write SVN revision header file (stub - not applicable for git)
function(write_svnrev_h)
	if ("${PCSX2_GIT_TAG}" MATCHES "^v([0-9]+)\\.([0-9]+)\\.([0-9]+)$")
		file(WRITE ${CMAKE_BINARY_DIR}/common/include/svnrev.h
			"#define GIT_TAG \"${PCSX2_GIT_TAG}\"\n"
			"#define GIT_TAGGED_COMMIT 1\n"
			"#define GIT_TAG_HI  ${CMAKE_MATCH_1}\n"
			"#define GIT_TAG_MID ${CMAKE_MATCH_2}\n"
			"#define GIT_TAG_LO ${CMAKE_MATCH_3}\n"
			"#define GIT_REV \"${PCSX2_GIT_REV}\"\n"
			"#define GIT_HASH \"${PCSX2_GIT_HASH}\"\n"
			"#define GIT_DATE \"${PCSX2_GIT_DATE}\"\n"
		)
	else()
		file(WRITE ${CMAKE_BINARY_DIR}/common/include/svnrev.h
			"#define GIT_TAG \"${PCSX2_GIT_TAG}\"\n"
			"#define GIT_TAGGED_COMMIT 0\n"
			"#define GIT_TAG_HI 0\n"
			"#define GIT_TAG_MID 0\n"
			"#define GIT_TAG_LO 0\n"
			"#define GIT_REV \"${PCSX2_GIT_REV}\"\n"
			"#define GIT_HASH \"${PCSX2_GIT_HASH}\"\n"
			"#define GIT_DATE \"${PCSX2_GIT_DATE}\"\n"
		)
	endif()
endfunction()

# like add_library(new ALIAS old) but avoids add_library cannot create ALIAS target "new" because target "old" is imported but not globally visible. on older cmake
function(alias_library new old)
	string(REPLACE "::" "" library_no_namespace ${old})
	if (NOT TARGET _alias_${library_no_namespace})
		add_library(_alias_${library_no_namespace} INTERFACE)
		target_link_libraries(_alias_${library_no_namespace} INTERFACE ${old})
	endif()
	add_library(${new} ALIAS _alias_${library_no_namespace})
endfunction()

function(source_groups_from_vcxproj_filters file)
	file(READ "${file}" filecontent)
	get_filename_component(parent "${file}" DIRECTORY)
	if (parent STREQUAL "")
		set(parent ".")
	endif()
	set(regex "<[^ ]+ Include=\"([^\"]+)\">[ \t\r\n]+<Filter>([^<]+)<\\/Filter>[ \t\r\n]+<\\/[^ >]+>")
	string(REGEX MATCHALL "${regex}" filterstrings "${filecontent}")
	foreach(filterstring IN LISTS filterstrings)
		string(REGEX REPLACE "${regex}" "\\1" source "${filterstring}")
		string(REGEX REPLACE "${regex}" "\\2" filter "${filterstring}")
		string(REPLACE "${parent}/" "" source "${source}")
		string(REPLACE "\\" "/" source "${source}")
		source_group("${filter}" FILES "${source}")
	endforeach()
endfunction()

function(fixup_file_properties target)
	get_target_property(SOURCES ${target} SOURCES)
	if(APPLE)
		foreach(source IN LISTS SOURCES)
			# Set the right file types for .inl files in Xcode
			if("${source}" MATCHES "\\.(inl|h)$")
				set_source_files_properties("${source}" PROPERTIES XCODE_EXPLICIT_FILE_TYPE sourcecode.cpp.h)
			endif()
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

function(disable_compiler_warnings_for_target target)
	if(MSVC)
		target_compile_options(${target} PRIVATE "/W0")
	else()
		target_compile_options(${target} PRIVATE "-w")
	endif()
endfunction()

function(detect_page_size)
	message(STATUS "Determining host page size")
	set(detect_page_size_file ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.c)
	file(WRITE ${detect_page_size_file} "
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main() {
	int res = sysconf(_SC_PAGESIZE);
	printf(\"%d\", res);
	return (res > 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}")
	try_run(
		detect_page_size_run_result
		detect_page_size_compile_result
		${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}
		${detect_page_size_file}
		RUN_OUTPUT_VARIABLE detect_page_size_output)
	if(NOT detect_page_size_compile_result OR NOT detect_page_size_run_result EQUAL 0 OR CMAKE_CROSSCOMPILING)
		message(FATAL_ERROR "Could not determine host page size.")
	else()
		message(STATUS "Host page size: ${detect_page_size_output}")
		set(HOST_PAGE_SIZE ${detect_page_size_output} CACHE STRING "Reported host page size")
	endif()
endfunction()

function(detect_cache_line_size)
	message(STATUS "Determining host cache line size")
	set(detect_cache_line_size_file ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.c)
	file(WRITE ${detect_cache_line_size_file} "
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main() {
	int l1i = sysconf(_SC_LEVEL1_DCACHE_LINESIZE);
	if (l1i <= 0) {
		return EXIT_FAILURE;
	}
	printf(\"%d\", l1i);
	return EXIT_SUCCESS;
}")
	try_run(
		detect_cache_line_size_run_result
		detect_cache_line_size_compile_result
		${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}
		${detect_cache_line_size_file}
		RUN_OUTPUT_VARIABLE detect_cache_line_size_output)
	if(NOT detect_cache_line_size_compile_result OR NOT detect_cache_line_size_run_result EQUAL 0 OR CMAKE_CROSSCOMPILING)
		message(FATAL_ERROR "Could not determine host cache line size.")
	else()
		message(STATUS "Host cache line size: ${detect_cache_line_size_output}")
		set(HOST_CACHE_LINE_SIZE ${detect_cache_line_size_output} CACHE STRING "Reported host cache line size")
	endif()
endfunction()

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
		list(REMOVE_DUPLICATES dirs)
	endif()
	set(${output} "${dirs}" PARENT_SCOPE)
endfunction()

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

function(force_include_last target include)
	force_include_last_impl(${target} "${include}" INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES)
	force_include_last_impl(${target} "${include}" INCLUDE_DIRECTORIES LINK_LIBRARIES)
endfunction()
