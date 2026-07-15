# Validation report — rectangular rev3

Date: 2026-07-14
Board: rssi_checker_rect_rev3.kicad_pcb

## Mechanics

- Board outline: rectangle
- Width: 65.00 mm
- Height: 75.00 mm
- Edge segments: 4
- ESP32 antenna end at right edge

## Layer allocation

- Routed copper: B.Cu only
- Ground zone: B.Cu
- SMD footprints on B.Cu: R1, R2, R3, C1, C2, C5
- Front THT/mechanical footprints: U2, U1, J1–J8, C3, C4, JP1, JP2
- Routed segments on F.Cu: 0

## Structural checks

- S-expression balance: 0
- Footprints: 20
- Copper segments: 74
- Track widths: 0.8 mm main; 0.3 mm local ESP32 3.3 V escape
- Non-45-degree diagonal segments: 0
- Track-to-track violations: 0
- Track-to-pad violations: 0
- Pad-to-pad violations: 0
- Disconnected non-GND groups: 0
- Jumpers: JP1, JP2
- Duplicate UUID: 0

Clearance model: 0.20 mm. Pads were conservatively checked using their smaller dimension.

## Required before fabrication

1. Select the exact right-angle THT USB-C connector and compare its mechanical drawing with J8.
2. Print the PCB 1:1 and place the real ESP32 board and connectors on it.
3. Open in KiCad and press B to refill B.Cu GND.
4. Run native KiCad DRC.
5. Check enclosure wall clearances around USB-C, banana jack and the six lower connectors.

