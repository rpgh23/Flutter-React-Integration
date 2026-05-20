#!/bin/bash
set -e

# ============================================================
# fix_simulator_frameworks.sh
#
# Run this script ONCE after you copy updated xcframeworks
# into the Frameworks/ folder.
#
# What it does:
#   1. Fixes ffmpeg_kit_flutter_new_min.xcframework so it has
#      a proper arm64+x86_64 simulator slice registered.
#   2. Recompiles libffmpegkit_stub.a from source (if Xcode
#      command line tools are available).
#
# Usage:
#   cd Flutter-React-Integration
#   ./fix_simulator_frameworks.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCFW="$SCRIPT_DIR/Frameworks/ffmpeg_kit_flutter_new_min.xcframework"

echo "▶ Fixing ffmpeg_kit_flutter_new_min.xcframework for simulator..."

# ----------------------------------------------------------
# Step 1: Create the .framework structure inside
#         ios-arm64_x86_64-simulator/ if it's a raw binary
# ----------------------------------------------------------
SIM_DIR="$XCFW/ios-arm64_x86_64-simulator"
FW_DIR="$SIM_DIR/ffmpeg_kit_flutter_new_min.framework"
RAW_BINARY="$SIM_DIR/ffmpeg_kit_flutter_new_min"

if [ -f "$RAW_BINARY" ] && [ ! -d "$FW_DIR" ]; then
  echo "  → Creating .framework structure in ios-arm64_x86_64-simulator/"

  # Find a reference slice to copy Headers/Modules/Info.plist from
  REF_FW=""
  if [ -d "$XCFW/ios-x86_64-simulator/ffmpeg_kit_flutter_new_min.framework" ]; then
    REF_FW="$XCFW/ios-x86_64-simulator/ffmpeg_kit_flutter_new_min.framework"
  elif [ -d "$XCFW/ios-arm64/ffmpeg_kit_flutter_new_min.framework" ]; then
    REF_FW="$XCFW/ios-arm64/ffmpeg_kit_flutter_new_min.framework"
  fi

  mkdir -p "$FW_DIR"
  mv "$RAW_BINARY" "$FW_DIR/ffmpeg_kit_flutter_new_min"

  if [ -n "$REF_FW" ]; then
    [ -d "$REF_FW/Headers" ] && cp -r "$REF_FW/Headers" "$FW_DIR/"
    [ -d "$REF_FW/Modules" ]  && cp -r "$REF_FW/Modules"  "$FW_DIR/"
    [ -f "$REF_FW/Info.plist" ] && cp "$REF_FW/Info.plist" "$FW_DIR/"
  fi
  echo "  ✓ .framework structure created"
else
  echo "  ✓ .framework structure already exists, skipping"
fi

# ----------------------------------------------------------
# Step 2: Update the xcframework Info.plist to register
#         ios-arm64_x86_64-simulator slice
# ----------------------------------------------------------
INFO_PLIST="$XCFW/Info.plist"

# Check if ios-arm64_x86_64-simulator is already registered
if plutil -p "$INFO_PLIST" | grep -q "ios-arm64_x86_64-simulator"; then
  echo "  ✓ Info.plist already has ios-arm64_x86_64-simulator, skipping"
else
  echo "  → Updating Info.plist to register ios-arm64_x86_64-simulator..."

  # Build new Info.plist with ios-arm64_x86_64-simulator replacing any x86_64-only simulator entry
  python3 - "$INFO_PLIST" <<'PYEOF'
import plistlib, sys, copy

path = sys.argv[1]
with open(path, 'rb') as f:
    plist = plistlib.load(f)

libs = plist.get('AvailableLibraries', [])

# Remove any existing simulator-only entry
libs = [l for l in libs if l.get('SupportedPlatformVariant') != 'simulator']

# Add unified arm64+x86_64 simulator entry
libs.insert(0, {
    'BinaryPath': 'ffmpeg_kit_flutter_new_min.framework/ffmpeg_kit_flutter_new_min',
    'LibraryIdentifier': 'ios-arm64_x86_64-simulator',
    'LibraryPath': 'ffmpeg_kit_flutter_new_min.framework',
    'SupportedArchitectures': ['arm64', 'x86_64'],
    'SupportedPlatform': 'ios',
    'SupportedPlatformVariant': 'simulator',
})

plist['AvailableLibraries'] = libs
with open(path, 'wb') as f:
    plistlib.dump(plist, f)
print("  ✓ Info.plist updated")
PYEOF
fi

# ----------------------------------------------------------
# Step 3: Recompile libffmpegkit_stub.a from source
# ----------------------------------------------------------
STUB_SRC="$SCRIPT_DIR/Sources/ffmpegkit_stub/ffmpegkit_stub.m"
STUB_LIB="$SCRIPT_DIR/Libraries/libffmpegkit_stub.a"

if [ -f "$STUB_SRC" ]; then
  echo "▶ Recompiling libffmpegkit_stub.a..."
  TMP_OBJ=$(mktemp /tmp/ffmpegkit_stub_XXXX.o)
  xcrun -sdk iphonesimulator clang \
    -arch arm64 -arch x86_64 \
    -mios-simulator-version-min=14.0 \
    -fobjc-arc \
    -c "$STUB_SRC" -o "$TMP_OBJ"
  mkdir -p "$SCRIPT_DIR/Libraries"
  libtool -static "$TMP_OBJ" -o "$STUB_LIB"
  rm -f "$TMP_OBJ"
  echo "  ✓ libffmpegkit_stub.a recompiled"
else
  echo "  ⚠ Stub source not found at $STUB_SRC, skipping recompile"
fi

echo ""
echo "✅ Done. Simulator framework fixes applied."
echo "   Commit the updated Frameworks/ and Libraries/ before tagging a new release."
