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
