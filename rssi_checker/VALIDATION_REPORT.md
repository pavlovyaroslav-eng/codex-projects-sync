# PCB validation report

## Automated structural/geometric checks

- KiCad S-expression parentheses balance: **pass**.
- Footprints: **22**.
- Routed segments: **88**.
- Used track layers: **F.Cu only**.
- Track widths present: **0.8 mm** and local **0.3 mm** fine-pitch escapes.
- Non-orthogonal segments: all are 45° within 0.03 mm coordinate tolerance.
- Non-GND electrical nets: **all connected** by pad/segment graph analysis.
- Different-net track intersections or track-to-track clearance below 0.20 mm: **none detected**.
- Wire links: **2** (JP1 and JP2).
- J2–J7 pad order: **Signal, +5V, GND**.
- Board outline: **55.88 × 53.34 mm**.

## Native KiCad checks not run

`kicad-cli`/KiCad is not installed in this workspace, so the native KiCad ERC/DRC and zone refill could not be executed here. GND connectivity depends on the F.Cu polygon and must be finalized by pressing **B** in KiCad before the fabrication DRC.

The retained legacy schematic still contains the former CD4066 implementation, so ERC against that file is not representative of the new board.
