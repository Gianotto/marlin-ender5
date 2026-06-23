# Cura — Start G-code

Start G-code used in Cura for this Ender 5 build. Every command here is accepted
by the firmware (Marlin 2.1.2.7 with this repo's config).

```gcode
M201 X500.00 Y500.00 Z100.00 E5000.00 ;Setup machine max acceleration
M203 X500.00 Y500.00 Z10.00 E50.00 ;Setup machine max feedrate
M204 P500.00 R1000.00 T500.00 ;Setup Print/Retract/Travel acceleration
M220 S100 ;Reset Feedrate
M221 S100 ;Reset Flowrate

M140 S{material_bed_temperature} ;set bed temp no wait
M104 S{material_print_temperature} ;set nozzle temp no wait
G28 ;Home
M190 S{material_bed_temperature} ;wait bed temp

G29 ;Bed Leveling sequence
M109 S{material_print_temperature} ;wait nozzle temp

G92 E0 ;Reset Extruder
G1 Z2.0 F3000 ;Move Z Axis up
G1 X10.1 Y20 Z0.28 F5000.0 ;Move to start position
G1 X10.1 Y200.0 Z0.28 F1500.0 E15 ;Draw the first line
G1 X10.4 Y200.0 Z0.28 F5000.0 ;Move to side a little
G1 X10.4 Y20 Z0.28 F1500.0 E30 ;Draw the second line
G92 E0 ;Reset Extruder
G1 Z2.0 F3000 ;Move Z Axis up
G1 E-2 F1800
```

## Notes

- **`G29`** runs a fresh BL-Touch bilinear probe before every print. With
  `RESTORE_LEVELING_AFTER_G28` and fade height enabled in the firmware, the mesh
  is applied automatically.
- **Sequence:** the bed is heated (`M190`) before `G29`, and the nozzle reaches
  temperature (`M109`) only after probing — probing with a cold nozzle avoids ooze.
- **No `M205` (jerk) line:** the firmware uses Junction Deviation (`CLASSIC_JERK`
  is off), so explicit jerk values would be ignored anyway. Leaving it out is
  correct. To use classic jerk instead, enable `CLASSIC_JERK` in
  `config/Configuration.h` and rebuild.
