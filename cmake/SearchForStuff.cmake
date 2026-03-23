# SearchForStuff.cmake - Find and configure required dependencies for PCSX2/iPSX2

# Find required packages
find_package(Threads REQUIRED)

# Try to find optional packages silently
# These may not be available on all platforms
find_package(SDL3 QUIET)
find_package(Qt6 QUIET COMPONENTS Core Gui Widgets)
find_package(ZLIB QUIET)
find_package(BZip2 QUIET)
find_package(CURL QUIET)
find_package(Freetype QUIET)
find_package(Harfbuzz QUIET)

message(STATUS "Dependencies found:")
message(STATUS "  Threads: YES")
if(SDL3_FOUND)
    message(STATUS "  SDL3: YES")
else()
    message(STATUS "  SDL3: NO (bundled version will be used)")
endif()

if(Qt6_FOUND)
    message(STATUS "  Qt6: YES")
else()
    message(STATUS "  Qt6: NO")
endif()

if(Freetype_FOUND)
    message(STATUS "  Freetype: YES")
else()
    message(STATUS "  Freetype: NO (bundled version will be used)")
endif()

message(STATUS "Dependency search completed")
