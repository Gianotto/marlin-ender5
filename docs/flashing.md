# Flashing the SKR Mini E3 V2.0

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
