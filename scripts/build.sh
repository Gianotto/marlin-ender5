#!/usr/bin/env bash
# Build Marlin for Ender 5 + BTT SKR Mini E3 V1.2 + BL-Touch.
# Clones Marlin at the pinned tag, overlays our config, compiles, and
# copies the resulting firmware.bin to ./dist/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARLIN_TAG="$(tr -d '[:space:]' < "$REPO_ROOT/marlin.version")"
MARLIN_SRC="$REPO_ROOT/Marlin-src"
PIO_ENV="STM32F103RC_btt_USB"
FLASH_LIMIT=262144   # 256 KB

echo ">> Marlin tag: $MARLIN_TAG"

# 1. Fetch Marlin source at the pinned tag (shallow), if not already present.
if [ ! -d "$MARLIN_SRC/.git" ]; then
  rm -rf "$MARLIN_SRC"
  git clone --depth 1 --branch "$MARLIN_TAG" \
    https://github.com/MarlinFirmware/Marlin.git "$MARLIN_SRC"
fi

# 2. Overlay our configuration files.
cp "$REPO_ROOT/config/Configuration.h"     "$MARLIN_SRC/Marlin/Configuration.h"
cp "$REPO_ROOT/config/Configuration_adv.h" "$MARLIN_SRC/Marlin/Configuration_adv.h"

# Optional custom bootscreen (only overlaid when present).
if [ -f "$REPO_ROOT/config/_Bootscreen.h" ]; then
  cp "$REPO_ROOT/config/_Bootscreen.h" "$MARLIN_SRC/Marlin/_Bootscreen.h"
fi

# 3. Compile.
cd "$MARLIN_SRC"
platformio run -e "$PIO_ENV"

# 4. Collect the binary and check the flash budget.
BIN="$MARLIN_SRC/.pio/build/$PIO_ENV/firmware.bin"
SIZE="$(wc -c < "$BIN")"
echo ">> firmware.bin size: ${SIZE} bytes (limit ${FLASH_LIMIT})"
if [ "$SIZE" -gt "$FLASH_LIMIT" ]; then
  echo "!! firmware exceeds 256 KB flash budget" >&2
  exit 1
fi

mkdir -p "$REPO_ROOT/dist"
cp "$BIN" "$REPO_ROOT/dist/firmware.bin"
echo ">> wrote dist/firmware.bin"
