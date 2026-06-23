# Marlin Ender 5 + SKR Mini E3 V1.2 + BL-Touch — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a config-overlay repository that compiles Marlin 2.1.2.7 for a Creality Ender 5 with a BigTreeTech SKR Mini E3 V1.2 and BL-Touch, producing a flashable `firmware.bin` via GitHub Actions CI.

**Architecture:** The repo stores only the customizations (`config/Configuration.h`, `config/Configuration_adv.h`), a build script, a CI workflow, and docs. The build script clones Marlin at the pinned tag, overlays our config files, and compiles the `STM32F103RC_btt_USB` PlatformIO environment. CI runs the same script and publishes the binary.

**Tech Stack:** Marlin 2.1.2.7, PlatformIO, STM32F103RC (256 KB flash), GitHub Actions, Bash.

**Base config:** Official example `config/examples/Creality/Ender-5/BigTreeTech SKR Mini E3 1.2/` from `MarlinFirmware/Configurations` @ `release-2.1.2.7`. It already sets `BOARD_BTT_SKR_MINI_E3_V1_2` and TMC2209 drivers; we add BL-Touch, ABL, USB serial, and correct the build volume.

---

## File Structure

```
marlin-ender5/
├─ README.md                       # Create (Task 8)
├─ marlin.version                  # Create (Task 1) — pins Marlin tag
├─ .gitignore                      # Create (Task 1)
├─ .gitattributes                  # Create (Task 1) — LF for *.sh/*.h
├─ config/
│  ├─ Configuration.h              # Create (Task 3) → edit (Task 4)
│  └─ Configuration_adv.h          # Create (Task 3) → edit (Task 5)
├─ scripts/
│  └─ build.sh                     # Create (Task 2) — overlay + compile
├─ .github/workflows/build.yml     # Create (Task 7)
└─ docs/
   ├─ flashing.md                  # Create (Task 8)
   └─ calibration.md               # Create (Task 8)
```

Repo is already a git repo on branch `master` with the design spec committed.

---

## Task 1: Repo scaffolding

**Files:**
- Create: `marlin.version`
- Create: `.gitignore`
- Create: `.gitattributes`

- [ ] **Step 1: Pin the Marlin version**

Create `marlin.version` with a single line (no trailing content):

```
2.1.2.7
```

- [ ] **Step 2: Create `.gitignore`**

```
# PlatformIO / build artifacts
.pio/
build/
*.bin
*.hex
*.elf

# Cloned Marlin source (fetched by build script, never committed)
/Marlin-src/

# Python
__pycache__/
*.pyc
.venv/
venv/

# Editor / OS
.vscode/
.idea/
.DS_Store
Thumbs.db
```

- [ ] **Step 3: Create `.gitattributes`** (avoids the LF→CRLF churn on Windows for files the toolchain reads)

```
*.sh   text eol=lf
*.h    text eol=lf
*.yml  text eol=lf
*.md   text eol=lf
```

- [ ] **Step 4: Verify the files exist with expected content**

Run:
```bash
cat marlin.version && echo "---" && head -1 .gitignore && head -1 .gitattributes
```
Expected: prints `2.1.2.7`, then `---`, then the first lines of each file.

- [ ] **Step 5: Commit**

```bash
git add marlin.version .gitignore .gitattributes
git commit -m "chore: scaffold repo (version pin, gitignore, gitattributes)"
```

---

## Task 2: Build/overlay script

This script is the single source of truth for building — used both locally and by CI (DRY).

**Files:**
- Create: `scripts/build.sh`

- [ ] **Step 1: Write the build script**

Create `scripts/build.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable and syntax-check it**

Run:
```bash
chmod +x scripts/build.sh && bash -n scripts/build.sh && echo "syntax ok"
```
Expected: prints `syntax ok` (no syntax errors). This does NOT run a full build yet.

- [ ] **Step 3: Commit**

```bash
git add scripts/build.sh
git commit -m "build: add Marlin overlay/compile script"
```

---

## Task 3: Import the base configuration files

Download the official Ender-5 + SKR Mini E3 1.2 example configs verbatim, so the first commit captures the unmodified baseline and later diffs show exactly our changes.

**Files:**
- Create: `config/Configuration.h`
- Create: `config/Configuration_adv.h`

- [ ] **Step 1: Download both files into `config/`**

The folder name contains spaces — URL-encode them as `%20`.

Run:
```bash
mkdir -p config
BASE="https://raw.githubusercontent.com/MarlinFirmware/Configurations/release-2.1.2.7/config/examples/Creality/Ender-5/BigTreeTech%20SKR%20Mini%20E3%201.2"
curl -fsSL "$BASE/Configuration.h"     -o config/Configuration.h
curl -fsSL "$BASE/Configuration_adv.h" -o config/Configuration_adv.h
```

- [ ] **Step 2: Verify the baseline is the right board**

Run:
```bash
grep -n "define MOTHERBOARD" config/Configuration.h
grep -n "X_DRIVER_TYPE" config/Configuration.h
```
Expected: `MOTHERBOARD BOARD_BTT_SKR_MINI_E3_V1_2` and `X_DRIVER_TYPE TMC2209`.

- [ ] **Step 3: Commit the unmodified baseline**

```bash
git add config/Configuration.h config/Configuration_adv.h
git commit -m "config: import Ender-5 + SKR Mini E3 1.2 baseline (unmodified)"
```

---

## Task 4: Customize `Configuration.h`

Apply our changes on top of the baseline. After each edit, a `grep` confirms the new state. Use the Edit tool against the real downloaded file (exact original lines are in the file from Task 3).

**Files:**
- Modify: `config/Configuration.h`

- [ ] **Step 1: Serial — use native USB-C (host/OctoPrint over the board's USB)**

Set `SERIAL_PORT` from `2` to `-1`. Leave `SERIAL_PORT_2` at `-1`.

Resulting line:
```cpp
#define SERIAL_PORT -1
```

- [ ] **Step 2: Set the correct stock Ender 5 build volume**

Set these defines to the stock Ender 5 values (baseline ships larger/shorter values):
```cpp
#define X_BED_SIZE 220
#define Y_BED_SIZE 220
#define Z_MAX_POS 300
```
Leave `X_MIN_POS`/`Y_MIN_POS` at `0`.

- [ ] **Step 3: Enable the BL-Touch**

Uncomment `BLTOUCH`:
```cpp
#define BLTOUCH
```

- [ ] **Step 4: Route Z homing through the probe, not the Z endstop**

- Comment out the Z-min-endstop-as-probe line:
```cpp
//#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN
```
- Enable probe-based Z homing:
```cpp
#define USE_PROBE_FOR_Z_HOMING
```
- Enable safe homing (home XY to center before probing Z):
```cpp
#define Z_SAFE_HOMING
```

- [ ] **Step 5: Keep the probe offset placeholder (calibrate later)**

Leave the baseline value as the starting point and treat it as a placeholder to calibrate:
```cpp
#define NOZZLE_TO_PROBE_OFFSET { -48, -24, 0 }
```
(No change needed — this step just confirms the value is present.)

- [ ] **Step 6: Switch bed leveling from mesh to bilinear ABL**

- Comment out the manual mesh leveling line:
```cpp
//#define MESH_BED_LEVELING
```
- Enable bilinear auto bed leveling:
```cpp
#define AUTO_BED_LEVELING_BILINEAR
```
- Enable fade height and a finer grid (just below the leveling block / in the ABL options):
```cpp
#define ENABLE_LEVELING_FADE_HEIGHT
#define GRID_MAX_POINTS_X 5
#define GRID_MAX_POINTS_Y GRID_MAX_POINTS_X
```
- Enable re-applying leveling after G28:
```cpp
#define RESTORE_LEVELING_AFTER_G28
```

- [ ] **Step 7: Confirm the stock display is enabled**

Ensure the Creality stock 12864 display is enabled (works via the SKR Mini E3 EXP header):
```cpp
#define CR10_STOCKDISPLAY
```
If the baseline already has it uncommented, leave it; otherwise uncomment it.

- [ ] **Step 8: Verify all changes with grep**

Run:
```bash
grep -nE "define SERIAL_PORT( |_)|X_BED_SIZE|Y_BED_SIZE|Z_MAX_POS" config/Configuration.h
grep -nE "^#define (BLTOUCH|USE_PROBE_FOR_Z_HOMING|Z_SAFE_HOMING|AUTO_BED_LEVELING_BILINEAR|ENABLE_LEVELING_FADE_HEIGHT|RESTORE_LEVELING_AFTER_G28|CR10_STOCKDISPLAY|GRID_MAX_POINTS_X)" config/Configuration.h
grep -nE "Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN|MESH_BED_LEVELING" config/Configuration.h
```
Expected:
- `SERIAL_PORT -1`, `X_BED_SIZE 220`, `Y_BED_SIZE 220`, `Z_MAX_POS 300`
- All listed defines appear **uncommented** (start with `#define`)
- `Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN` and `MESH_BED_LEVELING` appear **commented** (`//#define`)

- [ ] **Step 9: Commit**

```bash
git add config/Configuration.h
git commit -m "config: enable BL-Touch + bilinear ABL, USB serial, Ender 5 volume"
```

---

## Task 5: Customize `Configuration_adv.h`

Minimal, targeted tuning. The baseline already carries the TMC2209 UART scaffolding for this board; we make it quiet and set sane currents for stock Creality motors.

**Files:**
- Modify: `config/Configuration_adv.h`

- [ ] **Step 1: Enable StealthChop for quiet motion**

Uncomment these (they are commented in the baseline). XY stealthChop is safe here because we home with mechanical endstops, not sensorless:
```cpp
#define STEALTHCHOP_XY
#define STEALTHCHOP_Z
#define STEALTHCHOP_E
```

- [ ] **Step 2: Set motor currents for stock Creality 42-series steppers**

Locate the `*_CURRENT` defines in the TMC2209 section and set them to 580 mA:
```cpp
#define X_CURRENT 580
#define Y_CURRENT 580
#define Z_CURRENT 580
#define E0_CURRENT 580
```
(If the baseline already has 580, this is a no-op — confirm the values.)

- [ ] **Step 3: Leave BL-Touch high-speed mode OFF for reliability**

Confirm `BLTOUCH_HS_MODE` stays commented:
```cpp
//#define BLTOUCH_HS_MODE true
```
(No change — documented as a later opt-in in calibration docs.)

- [ ] **Step 4: Verify with grep**

Run:
```bash
grep -nE "^#define STEALTHCHOP_(XY|Z|E)" config/Configuration_adv.h
grep -nE "^#define (X|Y|Z|E0)_CURRENT" config/Configuration_adv.h
grep -nE "BLTOUCH_HS_MODE" config/Configuration_adv.h
```
Expected:
- The three `STEALTHCHOP_*` defines are uncommented
- The four `*_CURRENT` defines read `580`
- `BLTOUCH_HS_MODE` is commented (`//#define`)

- [ ] **Step 5: Commit**

```bash
git add config/Configuration_adv.h
git commit -m "config(adv): stealthChop on, 580mA TMC currents"
```

---

## Task 6: First build (verification gate)

Compile the firmware end-to-end. This is the real test of the configuration.

**Files:** none (uses `scripts/build.sh`)

- [ ] **Step 1: Ensure PlatformIO is available**

Run:
```bash
platformio --version || pip install -U platformio
```
Expected: prints a PlatformIO version (installs it if missing). Requires Python 3.

- [ ] **Step 2: Run the build**

Run:
```bash
bash scripts/build.sh
```
Expected: clones Marlin 2.1.2.7, compiles env `STM32F103RC_btt_USB`, prints `firmware.bin size: <N> bytes (limit 262144)` with `N < 262144`, and writes `dist/firmware.bin`.

> If the build fails on a `#error` from Marlin's sanity checks, read the message — it names the exact conflicting option to fix in `config/`. Re-run after fixing.
> If it overflows 256 KB, fall back (in order): set `GRID_MAX_POINTS_X 3`; if still over, switch `SERIAL_PORT` to `2` and the env to `STM32F103RC_btt` (drops USB CDC — host then via the TFT/UART header or SD-only). Document whichever fallback is used.

- [ ] **Step 3: Confirm the artifact**

Run:
```bash
ls -la dist/firmware.bin
```
Expected: the file exists and is non-empty.

- [ ] **Step 4: Commit (no source artifacts — only confirm clean tree)**

`dist/` and `Marlin-src/` are gitignored. Verify nothing unintended is staged:
```bash
git status --porcelain
```
Expected: empty output (clean tree). No commit needed for this task.

---

## Task 7: GitHub Actions CI

Reuse `scripts/build.sh` so CI and local builds are identical.

**Files:**
- Create: `.github/workflows/build.yml`

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/build.yml`:

```yaml
name: Build firmware

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Cache PlatformIO
        uses: actions/cache@v4
        with:
          path: |
            ~/.platformio
            ~/.cache/pip
          key: pio-${{ runner.os }}-${{ hashFiles('marlin.version') }}

      - name: Install PlatformIO
        run: pip install -U platformio

      - name: Build
        run: bash scripts/build.sh

      - name: Name the artifact
        id: name
        run: echo "bin=firmware-ender5-skr-mini-e3-v1.2-${GITHUB_SHA::7}.bin" >> "$GITHUB_OUTPUT"

      - name: Rename binary
        run: mv dist/firmware.bin "dist/${{ steps.name.outputs.bin }}"

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ steps.name.outputs.bin }}
          path: dist/${{ steps.name.outputs.bin }}

      - name: Attach to release (on tag)
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: dist/${{ steps.name.outputs.bin }}
```

- [ ] **Step 2: Lint the YAML**

Run:
```bash
python -c "import yaml,sys; yaml.safe_load(open('.github/workflows/build.yml')); print('yaml ok')"
```
Expected: prints `yaml ok`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build.yml
git commit -m "ci: build firmware.bin on push and attach to releases"
```

---

## Task 8: Documentation

**Files:**
- Create: `README.md`
- Create: `docs/flashing.md`
- Create: `docs/calibration.md`

- [ ] **Step 1: Write `README.md`**

```markdown
# Marlin — Ender 5 + BTT SKR Mini E3 V1.2 + BL-Touch

Marlin 2.1.2.7 configured for a Creality Ender 5 running a BigTreeTech
SKR Mini E3 V1.2 with a BL-Touch and a direct-drive (relocated stock Creality
extruder).

This is a **config-overlay** repo: it stores only the customizations. The build
script downloads Marlin at the pinned tag (`marlin.version`), overlays the files
in `config/`, and compiles the `STM32F103RC_btt_USB` PlatformIO environment.

## Get the firmware

- **From CI:** download the latest `firmware-ender5-...bin` from the Actions
  artifacts (or from a GitHub Release for tagged builds).
- **Build locally:** `bash scripts/build.sh` → `dist/firmware.bin`
  (requires Python 3 + PlatformIO).

## Flash it

See [docs/flashing.md](docs/flashing.md).

## After flashing

The firmware ships with placeholders that MUST be calibrated on your machine
(probe offset, Z-offset, e-steps). See [docs/calibration.md](docs/calibration.md).

## Hardware

| Item | Value |
|------|-------|
| Printer | Creality Ender 5 (stock 220×220×300, stock hotend/thermistors) |
| Board | BigTreeTech SKR Mini E3 V1.2 (STM32F103RC, 4× TMC2209 UART) |
| Probe | BL-Touch (bilinear ABL) |
| Extruder | Direct drive — relocated stock Creality extruder |
| Display | Stock Creality 12864 (CR10_STOCKDISPLAY) |
```

- [ ] **Step 2: Write `docs/flashing.md`**

```markdown
# Flashing the SKR Mini E3 V1.2

1. Copy `firmware.bin` to the **root** of a FAT32-formatted microSD card.
   - The file MUST be named `firmware.bin`.
2. Power off the printer. Insert the card into the board's microSD slot.
3. Power on. The board flashes on boot (takes ~10–20 s; the screen may stay
   blank briefly).
4. The board renames the file to `FIRMWARE.CUR` on success. If it stays
   `firmware.bin`, the flash did not run — re-format the card as FAT32 and
   retry, and confirm the binary is < 256 KB.
5. After boot, run `M502` then `M500` to load and persist clean defaults to
   EEPROM, then proceed to calibration.

> Connecting over USB: the `STM32F103RC_btt_USB` build exposes the board's USB
> port as a serial device (`SERIAL_PORT -1`) for OctoPrint / Pronterface / the
> host of your choice.
```

- [ ] **Step 3: Write `docs/calibration.md`**

```markdown
# Post-flash calibration

Do these once after flashing. Save with `M500` after each, or all at the end.

## 1. Probe (X/Y) offset
The firmware ships with `NOZZLE_TO_PROBE_OFFSET { -48, -24, 0 }` as a
placeholder for a common mount. Measure the real horizontal distance from the
nozzle tip to the BL-Touch pin (X to the right is +, Y to the back is +) and
update `NOZZLE_TO_PROBE_OFFSET` in `config/Configuration.h`, then rebuild.

## 2. Z-offset (probe trigger to nozzle)
1. Home: `G28`
2. Disable leveling: `M420 S0`
3. Move to Z0 over the bed center and use baby-stepping (`M290`) with the
   paper test until a sheet drags slightly.
4. Read the live offset and set it: `M851 Z<value>` (value is negative).
5. `M500`.

## 3. Extruder e-steps (direct drive)
The relocated stock extruder starts at 93 steps/mm but should be calibrated:
1. Heat the hotend. Mark 120 mm of filament from the entry.
2. `M83` then `G1 E100 F100`.
3. Measure what remains; compute `new = 93 * 100 / (100 - leftover_consumed_error)`.
4. `M92 E<new>` then `M500`.

## 4. Extruder direction
Direct-drive conversions often run the motor backwards. If `G1 E10` retracts
instead of extrudes, flip `INVERT_E0_DIR` in `config/Configuration.h` and
rebuild.

## 5. PID autotune
- Hotend: `M303 E0 S210 C8 U1` then `M500`.
- Bed: `M303 E-1 S60 C8 U1` then `M500`.

## 6. First leveling
`G28` then `G29` to build the bilinear mesh, then `M500`. Slicer start G-code
should include `G29` (or `M420 S1` to load a saved mesh).

## Optional: BL-Touch high-speed mode
For faster probing you can enable `BLTOUCH_HS_MODE true` in
`config/Configuration_adv.h`. Verify probe accuracy with `M48` first.
```

- [ ] **Step 4: Verify the docs render and links resolve**

Run:
```bash
ls -la README.md docs/flashing.md docs/calibration.md
```
Expected: all three files exist and are non-empty.

- [ ] **Step 5: Commit**

```bash
git add README.md docs/flashing.md docs/calibration.md
git commit -m "docs: README, flashing guide, calibration guide"
```

---

## Task 9: Final review and wrap-up

- [ ] **Step 1: Confirm the full history and clean tree**

Run:
```bash
git log --oneline && echo "---" && git status --porcelain
```
Expected: commits for spec, scaffold, build script, baseline, Configuration.h, Configuration_adv.h, CI, docs; clean working tree.

- [ ] **Step 2: Re-run the build one last time to confirm green**

Run:
```bash
bash scripts/build.sh && echo "BUILD OK"
```
Expected: ends with `wrote dist/firmware.bin` and `BUILD OK`, size under 256 KB.

- [ ] **Step 3: (User-gated) Push to GitHub**

Only after the user authorizes pushing to their repo:
```bash
git remote add origin https://github.com/Gianotto/marlin-ender5.git
git push -u origin master
```
Then confirm the Actions run goes green and produces the artifact.

---

## Notes on verification

This is firmware configuration, not application code, so the "test" is a
successful cross-compile plus Marlin's built-in sanity checks (`#error`
directives that fire on contradictory options). The build script's size gate
enforces the 256 KB flash budget. Physical correctness (probe offset, e-steps,
Z-offset) cannot be verified in firmware and is delegated to the calibration
guide.
```
