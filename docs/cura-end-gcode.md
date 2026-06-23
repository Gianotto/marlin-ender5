# Cura — End G-code

End G-code used in Cura for this Ender 5 build. Every command here is accepted
by the firmware (Marlin 2.1.2.7 with this repo's config).

```gcode
G91 ;Relative positioning
G1 E-2 F2700 ;Retract a bit
G1 E-2 Z0.2 F2400 ;Retract and raise Z
G1 X5 Y5 F3000 ;Wipe out
G1 E-10 F2400 ;Retract filament when finished
G1 Z10 ;Raise Z more
G90 ;Absolute positioning

G28 X0 Y0 ;Present print
M106 S0 ;Turn-off fan
M104 S0 ;Turn-off hotend
M140 S0 ;Turn-off bed

M84 X Y E ;Disable all steppers but Z
```

## Notes

- **`G1 E-10`** is the end-of-print retraction. This is tuned for the **direct
  drive** setup (relocated stock Creality extruder) — short, unlike the ~60 mm
  bowden-style unload Cura ships by default, which would grind/unload filament
  on a direct drive.
- **`M84 X Y E`** disables the X, Y, and E steppers but leaves Z energized so the
  gantry holds position.
- **`G28 X0 Y0`** homes X and Y only (the `0` arguments are ignored) to present
  the print.
