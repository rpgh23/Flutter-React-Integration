#!/bin/bash
# ============================================================
# fix_simulator_frameworks.sh
#
# Run this AFTER copying updated xcframeworks from a Flutter
# build into the Frameworks/ folder.
#
# What it does:
#   1. Ensures the 8 real, device-only FFmpegKit xcframeworks
#      (ffmpegkit, libavcodec, libavdevice, libavfilter,
#      libavformat, libavutil, libswresample, libswscale) exist
#      in Frameworks/. `flutter build ios-framework` can never
#      produce these itself (it only outputs each plugin's own
#      Dart-bridge code, never a plugin's vendored third-party
#      binaries) — without them FFmpegKitConfig has no real
#      implementation on device and the app crashes. Idempotent:
#      only downloads/rebuilds (~110MB) if any are missing.
#   2. Fixes ffmpeg_kit_flutter_new.xcframework — lipo's the
#      x86_64 real slice with an arm64 stub so Apple Silicon
#      simulators work.
#   3. Rebuilds libffmpegkit_stub.xcframework (device + simulator).
#      Device slice is always an EMPTY placeholder — real device
#      builds must get FFmpegKitConfig etc. from the real
#      ffmpegkit.xcframework in step 1, not from this stub. If
#      both defined those classes, the Objective-C runtime could
#      pick the incomplete stub one and crash (this has happened).
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
REAL_FW_NAMES="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"
REAL_IOS_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/7.1.1-full-gpl/ffmpeg-kit-ios-full-gpl-7.1.1.zip"

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
# STEP 1/3: Ensure the 8 real device-only FFmpegKit xcframeworks
# exist. Idempotent — skips the ~110MB download if all are present.
# ================================================================
echo "▶ [STEP 1/3] Checking real FFmpegKit device frameworks..."

MISSING=""
for name in $REAL_FW_NAMES; do
  if [ ! -f "$SCRIPT_DIR/Frameworks/$name.xcframework/ios-arm64/$name.framework/$name" ]; then
    MISSING="$MISSING $name"
  fi
done

if [ -z "$MISSING" ]; then
  echo "✅ [STEP 1/3] All 8 real device frameworks already present — skipping download"
else
  echo "  → Missing:$MISSING — downloading and rebuilding all 8..."
  TMPDIR_REAL=$(mktemp -d /tmp/real_ffmpeg_build_XXXX)

  curl -L "$REAL_IOS_URL" -o "$TMPDIR_REAL/frameworks.zip"
  mkdir -p "$TMPDIR_REAL/download"
  unzip -q -o "$TMPDIR_REAL/frameworks.zip" -d "$TMPDIR_REAL/download"
  DL_FRAMEWORKS="$TMPDIR_REAL/download/Frameworks"
  if [ ! -d "$DL_FRAMEWORKS" ]; then
    echo "❌ [STEP 1/3] Expected Frameworks/ folder not found after unzip"
    rm -rf "$TMPDIR_REAL"; exit 1
  fi

  echo "// intentionally empty placeholder" > "$TMPDIR_REAL/empty.c"
  SIMSDK=$(xcrun --sdk iphonesimulator --show-sdk-path)

  for name in $REAL_FW_NAMES; do
    echo "  → Building $name.xcframework..."
    SRC_FW="$DL_FRAMEWORKS/$name.framework"
    if [ ! -d "$SRC_FW" ]; then
      echo "❌ [STEP 1/3] $SRC_FW not found in downloaded release"
      rm -rf "$TMPDIR_REAL"; exit 1
    fi

    # Device slice: thin the real fat binary down to arm64.
    # NOTE: xcodebuild -create-xcframework requires the binary inside a
    # .framework bundle to match the bundle's folder name exactly — so this
    # must live under a devfw_$name/ subdirectory, not be named "${name}_device",
    # or xcodebuild fails with "unable to read the file at ...".
    DEVICE_FW_DIR="$TMPDIR_REAL/devfw_$name"
    rm -rf "$DEVICE_FW_DIR"
    mkdir -p "$DEVICE_FW_DIR"
    DEVICE_FW="$DEVICE_FW_DIR/$name.framework"
    cp -R "$SRC_FW" "$DEVICE_FW"
    lipo -thin arm64 "$SRC_FW/$name" -output "$DEVICE_FW/$name"

    # Simulator slice: empty placeholder, same bundle id — nothing calls
    # into these on simulator (the stub in libffmpegkit_stub covers that).
    SIM_FW_DIR="$TMPDIR_REAL/simfw_$name"
    rm -rf "$SIM_FW_DIR"
    mkdir -p "$SIM_FW_DIR/$name.framework"
    cp "$SRC_FW/Info.plist" "$SIM_FW_DIR/$name.framework/Info.plist"
    clang -arch arm64 -target arm64-apple-ios14.0-simulator -isysroot "$SIMSDK" -dynamiclib \
      -install_name "@rpath/$name.framework/$name" \
      "$TMPDIR_REAL/empty.c" -o "$TMPDIR_REAL/${name}_arm64_sim.dylib"
    clang -arch x86_64 -target x86_64-apple-ios14.0-simulator -isysroot "$SIMSDK" -dynamiclib \
      -install_name "@rpath/$name.framework/$name" \
      "$TMPDIR_REAL/empty.c" -o "$TMPDIR_REAL/${name}_x86_64_sim.dylib"
    lipo -create "$TMPDIR_REAL/${name}_arm64_sim.dylib" "$TMPDIR_REAL/${name}_x86_64_sim.dylib" \
      -output "$SIM_FW_DIR/$name.framework/$name"

    rm -rf "$TMPDIR_REAL/${name}.xcframework"
    xcodebuild -create-xcframework \
      -framework "$DEVICE_FW" \
      -framework "$SIM_FW_DIR/$name.framework" \
      -output "$TMPDIR_REAL/${name}.xcframework" > /dev/null
    if [ $? -ne 0 ]; then
      echo "❌ [STEP 1/3] xcodebuild -create-xcframework failed for $name"
      rm -rf "$TMPDIR_REAL"; exit 1
    fi

    rm -rf "$SCRIPT_DIR/Frameworks/$name.xcframework"
    cp -R "$TMPDIR_REAL/${name}.xcframework" "$SCRIPT_DIR/Frameworks/$name.xcframework"
  done

  rm -rf "$TMPDIR_REAL"
  echo "✅ [STEP 1/3] All 8 real device frameworks rebuilt"
fi

echo ""

# ================================================================
# STEP 2/3: Fix ffmpeg_kit_flutter_new.xcframework simulator slice
# ================================================================
echo "▶ [STEP 2/3] Fixing $FW_NAME.xcframework simulator slice..."

if [ -d "$XCFW/ios-arm64_x86_64-simulator" ]; then
  echo "✅ [STEP 2/3] arm64+x86_64 simulator slice already present — skipping"
else
  # Find the existing x86_64-only simulator slice from Flutter build
  SIM_DIR=""
  for CANDIDATE in "$XCFW/ios-x86_64-simulator" "$XCFW/ios-arm64-simulator"; do
    [ -d "$CANDIDATE" ] && SIM_DIR="$CANDIDATE" && break
  done

  if [ -z "$SIM_DIR" ]; then
    echo "❌ [STEP 2/3] No simulator slice found in $XCFW"
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
    echo "❌ [STEP 2/3] Simulator binary not found inside $SIM_DIR"
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
    echo "❌ [STEP 2/3] Failed to compile arm64 stub"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi

  libtool -static "$TMPDIR_BUILD/stub_arm64.o" -o "$TMPDIR_BUILD/libstub_arm64.a"
  if [ $? -ne 0 ]; then
    echo "❌ [STEP 2/3] libtool failed"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi
  echo "  ✓ arm64 stub compiled"

  # Lipo x86_64 real archive + arm64 stub → fat static archive
  echo "  → Combining x86_64 + arm64 with lipo..."
  mkdir -p "$TMPDIR_BUILD/fat_sim"
  lipo -create "$SIM_BIN" "$TMPDIR_BUILD/libstub_arm64.a" \
    -output "$TMPDIR_BUILD/fat_sim/$FW_NAME"

  if [ $? -ne 0 ]; then
    echo "❌ [STEP 2/3] lipo failed"
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
    echo "❌ [STEP 2/3] Device framework not found: $DEVICE_FW"
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
    echo "❌ [STEP 2/3] xcodebuild -create-xcframework failed"
    rm -rf "$TMPDIR_BUILD"; exit 1
  fi

  # Only replace original after successful build
  rm -rf "$XCFW"
  cp -r "$XCFW_TMP" "$XCFW"
  rm -rf "$TMPDIR_BUILD"
  echo "✅ [STEP 2/3] $FW_NAME.xcframework rebuilt with arm64+x86_64 simulator slice"
fi

echo ""

# ================================================================
# STEP 3/3: Rebuild libffmpegkit_stub.xcframework
# ================================================================
echo "▶ [STEP 3/3] Rebuilding libffmpegkit_stub.xcframework..."

TMPDIR_STUB=$(mktemp -d /tmp/ffmpegkit_stub_XXXX)
mkdir -p "$TMPDIR_STUB/dev" "$TMPDIR_STUB/sim"

# Device slice (arm64) — MUST be an empty placeholder, not the real stub classes.
# Real device builds link the genuine ffmpegkit/libav* xcframeworks (see
# Frameworks/ffmpegkit.xcframework etc.) for FFmpegKitConfig and friends. If this
# slice also defines those classes, the Objective-C runtime has two candidates
# for the same class name and can pick the incomplete stub one — that's caused
# real device crashes (e.g. unrecognized selector on MediaInformationSession).
# Keep this slice symbol-free so there's no ambiguity.
echo "  → Compiling device slice (arm64, empty placeholder — real impl is in Frameworks/ffmpegkit.xcframework)..."
EMPTY_STUB_SRC="$TMPDIR_STUB/empty.c"
echo "// intentionally empty placeholder — see comment above" > "$EMPTY_STUB_SRC"
xcrun -sdk iphoneos clang \
  -arch arm64 \
  -mios-version-min=13.0 \
  -c "$EMPTY_STUB_SRC" -o "$TMPDIR_STUB/dev/stub.o"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 3/3] Failed to compile device placeholder"
  rm -rf "$TMPDIR_STUB"; exit 1
fi
libtool -static "$TMPDIR_STUB/dev/stub.o" -o "$TMPDIR_STUB/dev/libffmpegkit_stub.a"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 3/3] libtool failed for device slice"
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
  echo "❌ [STEP 3/3] Failed to compile arm64 simulator slice"
  rm -rf "$TMPDIR_STUB"; exit 1
fi

xcrun -sdk iphonesimulator clang \
  -arch x86_64 \
  -mios-simulator-version-min=13.0 \
  -fobjc-arc \
  -c "$STUB_SRC" -o "$TMPDIR_STUB/sim/stub_x86.o"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 3/3] Failed to compile x86_64 simulator slice"
  rm -rf "$TMPDIR_STUB"; exit 1
fi

libtool -static \
  "$TMPDIR_STUB/sim/stub_arm64.o" \
  "$TMPDIR_STUB/sim/stub_x86.o" \
  -o "$TMPDIR_STUB/sim/libffmpegkit_stub.a"
if [ $? -ne 0 ]; then
  echo "❌ [STEP 3/3] libtool failed for simulator slices"
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
  echo "❌ [STEP 3/3] Failed to create libffmpegkit_stub.xcframework"
  rm -rf "$TMPDIR_STUB"; exit 1
fi

rm -rf "$TMPDIR_STUB"
echo "✅ [STEP 3/3] libffmpegkit_stub.xcframework rebuilt (device + simulator)"

echo ""
echo "========================================"
echo "✅ Done! All simulator fixes applied."
echo "   Commit Frameworks/ and Libraries/ before tagging a new release."
echo "========================================"
