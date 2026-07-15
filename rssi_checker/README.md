# RSSI Checker — compact single-layer PCB

Main deliverable: `rssi_checker.kicad_pcb` (KiCad 9).

## Implemented constraints

- Board outline: **55.88 × 53.34 mm**.
- Routed copper: **F.Cu only**; GND zone is also on F.Cu.
- Main track width: **0.8 mm**; all corners are 45° or orthogonal.
- Short **0.3 mm neck-downs** exist only at the fine-pitch USB-C and ESP32 pads and in their immediate fan-out. A true 0.8 mm trace cannot enter the 0.65/1.27 mm pitch pads without a copper-clearance violation.
- Exactly two wire links: **JP1** for the 74HC4051 common output and **JP2** for KRL.
- U1 is **74HC4051N, DIP-16, socket footprint**; there are no CD4066 footprints.
- U2 is an **ESP32-WROOM-32 module**. Its antenna end is at the board edge and the antenna keep-out projects outside the board.
- C3 and C4 are **220 µF, 16 V, radial D8 mm / P3.5 mm** electrolytics.
- J8 is a right-angle, edge-mounted USB-C power receptacle. CC1 and CC2 each have a 5.1 kΩ pull-down.
- J1 is a right-angle two-pin banana/video-output connector.
- J2–J7 are right-angle 1×3 connectors in one row at the board edge. Their physical pad order is **Signal | +5V | GND**.

## 74HC4051 / ESP32 mapping

| Function | ESP32 GPIO | Module pad |
|---|---:|---:|
| MUX common Z | GPIO13 | 16 |
| Select S0/A | GPIO26 | 11 |
| Select S1/B | GPIO27 | 12 |
| Select S2/C | GPIO14 | 13 |
| Video output | GPIO25 | 10 |

| 4051 channel | Receiver | S2 S1 S0 |
|---|---|---|
| Y0 | KRL | 000 |
| Y1 | 2.4G | 001 |
| Y2 | TBS | 010 |
| Y3 | 915 | 011 |
| Y4 | 300 | 100 |
| Y5 | 500 | 101 |

U1 pin 16 is +3.3 V; pins 8 (GND), 7 (VEE), and 6 (/EN) are tied to GND. Therefore receiver signal inputs must stay within **0…3.3 V**.

## Before fabrication

Open the board in KiCad 9, press **B** to refill the GND zone, then run the native DRC and visually confirm the exact mechanical models of the purchased USB-C and banana connectors.

The supplied `rssi_checker.kicad_sch` is the untouched legacy CD4066 schematic from the archive and is retained only as a reference. It is **not synchronized** with this new 74HC4051 board; do not run “Update PCB from Schematic” against it.

