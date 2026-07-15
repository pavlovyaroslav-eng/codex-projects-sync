# Validation report

Date: 2026-07-14
Board: rssi_checker_devkitc_rev2.kicad_pcb

## Structural

- S-expression balance: 0
- Footprints: 20
- Net-assigned pads: 80
- Copper segments: 70
- Copper layers used: F.Cu only
- Widths: 0.8 mm main; 0.3 mm local breakout at USB-C and the DevKitC 3.3 V pin
- Jumpers: JP1, JP2
- Board envelope: 63.50 x 73.66 mm
- Non-45-degree diagonal segments: 0

## Geometric connectivity checker

- Track-to-track clearance violations: 0
- Track-to-pad clearance violations: 0
- Pad-to-pad clearance violations: 0
- Disconnected non-GND pad groups: 0
- Clearance model used: 0.20 mm, pad geometry conservatively approximated by the smaller pad dimension

## Manual checks encoded in the PCB

- ESP32-DevKitC 38-pin footprint: 48.26 x 27.94 mm, 2.54 mm pitch, 25.40 mm row spacing
- GND polygon avoids the antenna end
- Six 3-pin edge connectors use Signal | +5V | GND
- 74HC4051N is DIP-16 with socket outline
- Electrolytics are 16 V
- Ordinary passives are 0805
- USB-C and banana connector are edge-mounted and right-angle

## Required before fabrication

1. Open in KiCad.
2. Press B to refill the GND zone.
3. Run Inspect -> Design Rules Checker.
4. Compare the physical connector dimensions against the purchased part datasheets.
5. Print the board 1:1 and place the real ESP32-DevKitC from the photos over U2.
