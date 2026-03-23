#!/bin/bash
# P46: Build iPSX2 → sign → install on device
# Usage: ./scripts/build_device.sh [--ipa-only] [--clean]
#   --ipa-only: Build unsigned IPA for Sideloadly (skip device install)
#   --clean:    Clean before build
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_ROOT/src/cpp"
BUILD_DIR="$REPO_ROOT/build/ios_device"
SDK=iphoneos
CONFIG=Release
APP_PATH="$BUILD_DIR/$CONFIG-$SDK/iPSX2.app"
DEVICE_NAME="iPhone13mini"
TEAM_ID="GZUV3UMV3B"
BUNDLE_ID="com.otti83.iPSX2"
BIOS_SRC="/Users/mba/Downloads/PS2/SCPH-70000_JP.BIN"

IPA_ONLY=0
DO_CLEAN=0
for arg in "$@"; do
    case "$arg" in
        --ipa-only) IPA_ONLY=1 ;;
        --clean)    DO_CLEAN=1 ;;
    esac
done

GIT_HASH=$(cd "$REPO_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TS=$(date '+%Y%m%d_%H%M%S')
BUILD_HASH="${GIT_HASH}_${BUILD_TS}"
NCPU=$(sysctl -n hw.ncpu)

echo "=========================================="
echo " iPSX2 Device Build"
echo " BUILD_HASH: $BUILD_HASH"
echo " SDK: $SDK  CONFIG: $CONFIG"
echo "=========================================="

# CMake configure (always reconfigure to pick up version/source changes)
echo "[0] CMake configure..."
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=$SDK \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DiPSX2_REAL_DEVICE=ON 2>&1 | tail -3

# Clean (if requested)
if [ "$DO_CLEAN" -eq 1 ]; then
    echo "[0] Cleaning..."
    xcodebuild clean \
        -project "$BUILD_DIR/iPSX2.xcodeproj" \
        -target iPSX2 -configuration "$CONFIG" -sdk "$SDK" \
        2>&1 | tail -2
fi

if [ "$IPA_ONLY" -eq 1 ]; then
    # Unsigned build for Sideloadly
    echo "[1/3] Building unsigned ($CONFIG, $SDK, $NCPU cores)..."
    xcodebuild \
        -project "$BUILD_DIR/iPSX2.xcodeproj" \
        -target iPSX2 -configuration "$CONFIG" -sdk "$SDK" \
        CODE_SIGNING_ALLOWED=NO \
        2>&1 | grep -E "BUILD|error:|warning:.*error" | tail -5

    if [ ! -d "$APP_PATH" ]; then
        echo "ERROR: Build failed — $APP_PATH not found"; exit 1
    fi

    echo "[2/3] Creating IPA..."
    IPA_DIR="$REPO_ROOT/release"
    IPA_PATH="$IPA_DIR/iPSX2.ipa"
    mkdir -p "$IPA_DIR"
    STAGING=$(mktemp -d)
    mkdir -p "$STAGING/Payload"
    cp -R "$APP_PATH" "$STAGING/Payload/"
    (cd "$STAGING" && zip -qr "$IPA_PATH" Payload/ -x "*.DS_Store")
    rm -rf "$STAGING"
    IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)

    echo "[3/3] Done!"
    echo ""
    echo " IPA: $IPA_PATH ($IPA_SIZE)"
    echo " Next: Sideloadly → StikDebug → ./scripts/pull_log.sh"
else
    # Signed build + direct device install
    echo "[1/2] Building + Signing ($CONFIG, $SDK, $NCPU cores)..."
    xcodebuild \
        -project "$BUILD_DIR/iPSX2.xcodeproj" \
        -target iPSX2 -configuration "$CONFIG" -sdk "$SDK" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_STYLE=Automatic \
        CODE_SIGN_IDENTITY="Apple Development" \
        CODE_SIGNING_ALLOWED=YES \
        -allowProvisioningUpdates \
        2>&1 | grep -E "BUILD|error:|warning:.*error" | tail -5

    if [ ! -d "$APP_PATH" ]; then
        echo "ERROR: Build failed — $APP_PATH not found"; exit 1
    fi

    echo "[2/2] Installing on $DEVICE_NAME..."
    xcrun devicectl device install app \
        --device "$DEVICE_NAME" \
        "$APP_PATH" 2>&1

    # Ensure BIOS is in the app container
    echo ""
    echo "[+] Checking BIOS in app container..."

    TMPCHK=$(mktemp -d)
    if ! xcrun devicectl device copy from \
        --device "$DEVICE_NAME" \
        --domain-type appDataContainer \
        --domain-identifier "$BUNDLE_ID" \
        --source Documents/bios/SCPH-70000_JP.BIN \
        --destination "$TMPCHK/check.bin" 2>/dev/null; then
        if [ -f "$BIOS_SRC" ]; then
            echo "    Copying BIOS..."
            mkdir -p "$TMPCHK/bios"
            cp "$BIOS_SRC" "$TMPCHK/bios/"
            xcrun devicectl device copy to \
                --device "$DEVICE_NAME" \
                --domain-type appDataContainer \
                --domain-identifier "$BUNDLE_ID" \
                --source "$TMPCHK/bios" \
                --destination Documents/bios 2>&1 | grep -v "^$"
            echo "    BIOS copied."
        else
            echo "    WARNING: BIOS not found at $BIOS_SRC"
        fi
    else
        echo "    BIOS already on device."
    fi
    rm -rf "$TMPCHK"

    echo ""
    echo "=========================================="
    echo " Installed! BUILD_HASH: $BUILD_HASH"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. StikDebug or LLDB で JIT 付与+起動"
    echo "  2. テスト"
    echo "  3. ./scripts/pull_log.sh"
fi
