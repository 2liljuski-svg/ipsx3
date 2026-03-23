# iPSX2 iOS Build Instructions

## Prerequisites

- **macOS** with Xcode installed
- **CMake** 3.16+ (`brew install cmake`)

## Directory Structure

```
iPSX2/
├── src/
│   ├── cpp/          ← C++/ObjC source (CMakeLists.txt here)
│   ├── swift/        ← Swift UI source
│   └── assets/       ← Fonts, shaders, resources
├── cmake/            ← CMake modules
├── build/
│   ├── ios_sim/      ← Simulator build output
│   └── ios_device/   ← Device build output
├── scripts/          ← Build/debug scripts
├── release/          ← IPA output
├── docs/             ← Reports, plans
├── CLAUDE.md
└── BUILD_IOS.md      ← This file
```

## Simulator Build

### 1. Configure

```bash
cmake -S src/cpp -B build/ios_sim -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0
```

### 2. Build

```bash
cmake --build build/ios_sim --target iPSX2 --config Debug -j$(sysctl -n hw.ncpu)
```

### 3. Install & Launch

```bash
UDID="<simulator-udid>"
xcrun simctl install "$UDID" build/ios_sim/Debug-iphonesimulator/iPSX2.app
xcrun simctl launch "$UDID" com.otti83.iPSX2
```

## Device Build (IPA)

### Unsigned IPA (for Sideloadly)

```bash
./scripts/build_device.sh --ipa-only
# Output: release/iPSX2.ipa
```

### Signed + Direct Install

```bash
./scripts/build_device.sh
```

Device build requires CMake configuration for iphoneos SDK first:

```bash
cmake -S src/cpp -B build/ios_device -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DiPSX2_REAL_DEVICE=ON
```

## Clean Rebuild

```bash
rm -rf build/ios_sim
# Then run Configure + Build steps above
```

## Log Collection

### Simulator
```bash
DATA=$(xcrun simctl get_app_container "$UDID" com.otti83.iPSX2 data)
cat "$DATA/Documents/pcsx2_log.txt"
```

### Device
```bash
./scripts/pull_log.sh
```
