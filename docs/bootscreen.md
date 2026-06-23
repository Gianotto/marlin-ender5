# Custom bootscreen

The boot logo shown on the 128×64 display comes from
[config/_Bootscreen.h](../config/_Bootscreen.h), a 1-bit bitmap generated from
[images/digital.png](../images/digital.png).

It is enabled by `SHOW_CUSTOM_BOOTSCREEN` in `config/Configuration.h` and is
overlaid into the Marlin tree by `scripts/build.sh` (copied to `Marlin/_Bootscreen.h`).

## Regenerate

```bash
python scripts/make_bootscreen.py images/digital.png --threshold 70
```

Options:
- `--threshold N` (0–255): luminance cutoff. Lower = more pixels lit / more detail.
  The current logo uses `70`.
- `--invert`: flip lit/unlit pixels in the data.
- `--timeout MS`: how long the screen is shown (default 2500).

Then rebuild: `bash scripts/build.sh`.

## If the logo looks inverted on the real panel

The bitmap lights the logo lines on a dark background (matching Marlin's default
bootscreen behavior). If your specific display shows it reversed (dark logo on a
fully-lit screen), either:

- add `#define CUSTOM_BOOTSCREEN_INVERTED` to `config/_Bootscreen.h`, or
- regenerate with `--invert`.
