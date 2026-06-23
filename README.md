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

## Slicer (Cura)

G-code verified against this firmware:
- [docs/cura-start-gcode.md](docs/cura-start-gcode.md) — Start G-code
- [docs/cura-end-gcode.md](docs/cura-end-gcode.md) — End G-code

## Hardware

| Item | Value |
|------|-------|
| Printer | Creality Ender 5 (stock 220×220×300, stock hotend/thermistors) |
| Board | BigTreeTech SKR Mini E3 V1.2 (STM32F103RC, 4× TMC2209 UART) |
| Probe | BL-Touch (bilinear ABL) |
| Extruder | Direct drive — relocated stock Creality extruder |
| Display | Stock Creality 12864 (CR10_STOCKDISPLAY) |

## Boot logo

A custom boot logo is shown on startup — see [docs/bootscreen.md](docs/bootscreen.md)
for how it's generated and how to change it.
