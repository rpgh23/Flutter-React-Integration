#!/bin/bash
# ============================================================
# fix_simulator_frameworks.sh
#
# Run this AFTER copying updated xcframeworks from a Flutter
# build into the Frameworks/ folder.
#
# What it does:
#   1. Fixes ffmpeg_kit_flutter_new.xcframework — lipo's the
#      x86_64 real slice with an arm64 stub so Apple Silicon
#      simulators work.
#   2. Rebuilds libffmpegkit_stub.xcframework (device + simulator).
#
# Usage:
#   cd Flutter-React-Integration
#   ./fix_simulator_frameworks.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FW_NAME="ffmpeg_kit_flutter_new"
XCFW="$SCRIPT_DIR/Frameworks/$FW_NAME.xcframework"
# Stub for arm64 simulator slice — only FFmpegKitFlutterPlugin
PLUGIN_STUB_SRC="$SCRIPT_DIR/Sources/ffmpegkit_stub/ffmpegkit_flutter_plugin_stub.m"
# Full stub — all other ffmpegkit ObjC classes for libffmpegkit_stub
STUB_SRC="$SCRIPT_DIR/Sources/ffmpegkit_stub/ffmpegkit_stub.m"
STUB_XCFW="$SCRIPT_DIR/Libraries/libffmpegkit_stub.xcframework"

echo "========================================"
echo "  fix_simulator_frameworks.sh"
echo "========================================"
echo ""

# ---- Pre-flight checks ----
FAIL=0
if [ ! -d "$XCFW" ]; then
  echo "❌ [PRE-CHECK] Not found: $XCFW"
  FAIL=1
fi
if [ ! -f "$PLUGIN_STUB_SRC" ]; then
  echo "❌ [PRE-CHECK] Not found: $PLUGIN_STUB_SRC"
  FAIL=1
fi
if [ ! -f "$STUB_SRC" ]; then
  echo "❌ [PRE-CHECK] Not found: $STUB_SRC"
  FAIL=1
fi
if [ $FAIL -eq 1 ]; then
  echo "   Aborting. Run 'flutter build ios-framework' and copy frameworks first."
  exit 1
fi
echo "✅ [PRE-CHECK] Found $FW_NAME.xcframework"
echo "✅ [PRE-CHECK] Found stub sources"
echo ""

# ================================================================
# STEP 1/2: Fix ffmpeg_kit_flutter_new.xcframework simulator slice
# ================================================================
echo "▶ [STEP 1/2] Fixing $FW_NAME.xcframework simulator slice..."

if [ -d "$XCFW/ios-arm64_x86_64-simulator" ]; then
  echo "✅ [STEP 1/2] arm64+x86_64 simulator slice already present — skipping"
else
  # Find the existing x86_64-only simulator slice from Flutter build
  SIM_DIR=""
  for CANDIDATE in "$XCFW/ios-x86_64-simulator" "$XCFW/ios-arm64-simulator"; do
    [ -d "$CANDIDATE" ] && SIM_DIR="$CANDIDATE" && break
  done

  if [ -z "$SIM_DIR" ]; then
    echo "❌ [STEP 1/2] No simulator slice found in $XCFW"
    exit 1
  fi
  echo "  → Found simulator slice: $(basename "$SIM_DIR")"

  # Locate the binary inside the .framework wrapper
  SIM_FW_DIR="$SIM_DIR/$FW_NAME.framework"
  if [ -f "$SIM_FW_DIR/$FW_NAME" ]; then
    SIM_BIN="$SIM_FW_DIR/$FW_NAME"
  elif [ -f "$SIM_DIR/$FW_NAME" ]; then
    SIM_BIN="$SIM_DIR/$FW_NAME"
    SIM_FW_DIR="$SIM_DIR"
  else
    echo "❌ [STEP 1/2] Simulator binary not found inside $SIM_DIR"
    exit 1
  fi
  echo "  → Simulator binary: $SIM_BIN"

  TMPDIR_BUILD=$(mktemp -d /tmp/ffmpeg_fix_XXXX)

  # Need Flutter headers to compile the stub (FlutterPlugin protocol)
  FLUTTER_SIM_DIR="$XCFW/../Flutter.xcframework/ios-arm64_x86_64-simulator"
  FLUTTER_FW="$FLUTTER_SIM_DIR/Flutter.framework"
  FLUTTER_HEADERS=""
  if [ -d "$FLUTTER_FW/Headers" ]; then
    FLUTTER_HEADERS="-F$FLUTTER_SIM_DIR"
    echo "  → Found Flutter headers: $FLUTTER_FW/Headers"
  else
    echo "  ⚠️  Flutter headers not found — using fallback stub without protocol conformance"
    # Fallback: use a simpler stub that doesn't import Flutter headers
    PLUGIN_STUB_SRC_FALLBACK="$TMPDIR_BUILD/ffmpegkit_fallback.m"
    cat > "$PLUGIN_STUB_SRC_FALLBACK" << 'EOF'
#import <Foundation/Foundation.h>
@interface FFmpegKitFlutterPlugin : NSObject @end
@implementation FFmpegKitFlutterPlugin
+ (void)registerWithRegistrar:(id)registrar {}
@end
EOF
    PLUGIN_STUB_SRC="$PLUGIN_STUB_SRC_FALLBACK"
  fi

  # Compile arm64 simulator static stub
  echo "  → Compiling arm64 simulator stub (static)..."
  xcrun -sdk iphonesimulator clang \
    -arch arm64 \
    -mios-simulator-version-min=13.0 \
    -fobjc-arc \
    $FLUTTER_HEADERS \
    -c "$PLUGIN_STUB_SRC" -o "$TMPDIR_BUILD/stub_arm64.o"

  if [ $? -ne 0 ]; then
    echo "❌ [STEP 1/2] Failed to compile arm64 stub"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi

  libtool -static "$TMPDIR_BUILD/stub_arm64.o" -o "$TMPDIR_BUILD/libstub_arm64.a"
  if [ $? -ne 0 ]; then
    echo "❌ [STEP 1/2] libtool failed"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi
  echo "  ✓ arm64 stub compiled"

  # Lipo x86_64 real archive + arm64 stub → fat static archive
  echo "  → Combining x86_64 + arm64 with lipo..."
  mkdir -p "$TMPDIR_BUILD/fat_sim"
  lipo -create "$SIM_BIN" "$TMPDIR_BUILD/libstub_arm64.a" \
    -output "$TMPDIR_BUILD/fat_sim/$FW_NAME"

  if [ $? -ne 0 ]; then
    echo "❌ [STEP 1/2] lipo failed"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi

  ARCHS=$(lipo -archs "$TMPDIR_BUILD/fat_sim/$FW_NAME" 2>/dev/null || echo "unknown")
  echo "  ✓ Fat binary created — architectures: $ARCHS"

  # Build .framework wrapper for fat simulator binary
  FAT_FW="$TMPDIR_BUILD/fat_fw/$FW_NAME.framework"
  mkdir -p "$FAT_FW"
  cp "$TMPDIR_BUILD/fat_sim/$FW_NAME" "$FAT_FW/$FW_NAME"
  [ -d "$SIM_FW_DIR/Headers" ]    && cp -r "$SIM_FW_DIR/Headers"    "$FAT_FW/"
  [ -d "$SIM_FW_DIR/Modules" ]    && cp -r "$SIM_FW_DIR/Modules"    "$FAT_FW/"
  [ -f "$SIM_FW_DIR/Info.plist" ] && cp    "$SIM_FW_DIR/Info.plist" "$FAT_FW/"

  # Copy device framework
  DEVICE_FW="$XCFW/ios-arm64/$FW_NAME.framework"
  if [ ! -d "$DEVICE_FW" ]; then
    echo "❌ [STEP 1/2] Device framework not found: $DEVICE_FW"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi
  DEVICE_FW_COPY="$TMPDIR_BUILD/device/$FW_NAME.framework"
  mkdir -p "$TMPDIR_BUILD/device"
  cp -r "$DEVICE_FW" "$DEVICE_FW_COPY"

  # Build new xcframework in temp location first, then replace original
  XCFW_TMP="$TMPDIR_BUILD/$FW_NAME.xcframework"
  echo "  → Rebuilding xcframework..."
  xcodebuild -create-xcframework \
    -framework "$DEVICE_FW_COPY" \
    -framework "$FAT_FW" \
    -output "$XCFW_TMP"

  if [ $? -ne 0 ]; then
    echo "❌ [STEP 1/2] xcodebuild -create-xcframework failed"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi

  # Only replace original after successful build
  rm -rf "$XCFW"
  cp -r "$XCFW_TMP" "$XCFW"
  rm -rf "$TMPDIR_BUILD"
  echo "✅ [STEP 1/2] $FW_NAME.xcframework rebuilt with arm64+x86_64 simulator slice"
fi

echo ""

# ================================================================
# STEP 2/2: Rebuild libffmpegkit_stub.xcframework
# ================================================================
echo "▶ [STEP 2/2] Rebuilding libffmpegkit_stub.xcframework..."

TMPDIR_STUB=$(mktemp -d /tmp/ffmpegkit_stub_XXXX)
mkdir -p "$TMPDIR_STUB/dev" "$TMPDIR_STUB/sim"

# Device slice (arm64)
echo "  → Compiling device slice (arm64)..."
xcrun -sdk iphoneos clang \
  -arch arm64 \
  -mios-version-min=13.0 \
  -fobjc-arc \
  -c "$STUB_SRC" -o "$TMPDIR_STUB/dev/stub.o"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 2/2] Failed to compile device stub"
  rm -rf "$TMPDIR_STUB"; exit 1
fi
libtool -static "$TMPDIR_STUB/dev/stub.o" -o "$TMPDIR_STUB/dev/libffmpegkit_stub.a"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 2/2] libtool failed for device slice"
  rm -rf "$TMPDIR_STUB"; exit 1
fi
echo "  ✓ Device slice compiled"

# Simulator slices (arm64 + x86_64)
echo "  → Compiling simulator slices (arm64 + x86_64)..."
xcrun -sdk iphonesimulator clang \
  -arch arm64 \
  -mios-simulator-version-min=13.0 \
  -fobjc-arc \
  -c "$STUB_SRC" -o "$TMPDIR_STUB/sim/stub_arm64.o"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 2/2] Failed to compile arm64 simulator slice"
  rm -rf "$TMPDIR_STUB"; exit 1
fi

xcrun -sdk iphonesimulator clang \
  -arch x86_64 \
  -mios-simulator-version-min=13.0 \
  -fobjc-arc \
  -c "$STUB_SRC" -o "$TMPDIR_STUB/sim/stub_x86.o"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 2/2] Failed to compile x86_64 simulator slice"
  rm -rf "$TMPDIR_STUB"; exit 1
fi

libtool -static \
  "$TMPDIR_STUB/sim/stub_arm64.o" \
  "$TMPDIR_STUB/sim/stub_x86.o" \
  -o "$TMPDIR_STUB/sim/libffmpegkit_stub.a"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 2/2] libtool failed for simulator slices"
  rm -rf "$TMPDIR_STUB"; exit 1
fi
echo "  ✓ Simulator slices compiled"

echo "  → Creating xcframework..."
rm -rf "$STUB_XCFW"
mkdir -p "$SCRIPT_DIR/Libraries"
xcodebuild -create-xcframework \
  -library "$TMPDIR_STUB/dev/libffmpegkit_stub.a" \
  -library "$TMPDIR_STUB/sim/libffmpegkit_stub.a" \
  -output "$STUB_XCFW"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 2/2] Failed to create libffmpegkit_stub.xcframework"
  rm -rf "$TMPDIR_STUB"; exit 1
fi

rm -rf "$TMPDIR_STUB"
echo "✅ [STEP 2/2] libffmpegkit_stub.xcframework rebuilt (device + simulator)"

echo ""
echo "========================================"
echo "✅ Done! All simulator fixes applied."
echo "   Commit Frameworks/ and Libraries/ before tagging a new release."
echo "========================================"
