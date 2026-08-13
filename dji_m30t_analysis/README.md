# TB30 / bq76930 interoperability analysis

This directory contains a static, non-executing analysis of `DJIBatteryKiller.exe` and an independent read-only diagnostic utility for the TI bq76930 AFE used in a DJI TB30 battery.

## What was recovered from the original application

- The executable is a 32-bit mixed C++/CLI application built with Visual C++ linker 14.16.
- It imports the Silicon Labs CP2112 `HidSmbus_*` API through `SLABHIDtoSMBus.dll`.
- Its fixed battery write address is `0x16`, corresponding to the standard Smart Battery 7-bit address `0x0B`.
- It contains explicit profiles for BQ30Z55, BQ9003/BQ40Z307, and BQ9006. It has no bq76930 driver.
- The full IL and a C# reconstruction produced by ILSpy are retained under `ilspy/` and `ilspy-csharp/` as private interoperability research artifacts. They are not used to build the new utility.

The bq76930 is a different class of device: a 6-to-10-series analog front end with a 100 kHz I2C register interface. Orderable variants use 7-bit address `0x08` or `0x18` and may have CRC enabled. A host MCU is normally required for gas-gauge policy and smart-battery protocol; therefore direct AFE access does not by itself implement DJI authentication, unsealing, or firmware update.

## New utility

`Tb30Bq76930Diag.exe` is a clean interoperability implementation. It:

- uses the supplied 32-bit CP2112 DLLs;
- probes `0x08` and `0x18` and detects the optional TI CRC framing;
- reads calibration, fault/status, FET state, 10 AFE cell channels, pack voltage, temperature ADCs, and coulomb-counter raw value;
- applies the bq76930 6S channel map (`VC1`, `VC2`, `VC5`, `VC6`, `VC7`, `VC10`) by default;
- exposes no battery-register write operation, unseal key, permanent-failure reset, protection edit, or firmware writer.

Build:

```powershell
& 'E:\codex-projects-export\dji_m30t_analysis\build.ps1'
```

Offline verification:

```powershell
& 'E:\codex-projects-export\dji_m30t_analysis\dist\Tb30Bq76930Diag.exe' --self-test
```

Hardware use after checking logic level, ground, SDA/SCL pinout, and isolation from the pack power path:

```powershell
& 'E:\codex-projects-export\dji_m30t_analysis\dist\Tb30Bq76930Diag.exe' --list
& 'E:\codex-projects-export\dji_m30t_analysis\dist\Tb30Bq76930Diag.exe' --device-index 0 --address auto --crc auto --cells 6
```

The default USB filter is the factory CP2112 identity `VID 10C4 / PID EA90`. For a legitimately customized CP2112, pass its measured values as `--vid HEX --pid HEX`; unfiltered HID access is intentionally disabled. The utility also verifies the CP2112 part number (`0x0C`) before configuring the bridge.

Do not connect the CP2112 until the TB30 connector/test-point pinout and logic voltage have been measured. The bq76930 LDO option may be 2.5 V or 3.3 V; the CP2112 bus requires compatible open-drain pull-ups and a common reference.

## Sources used for the independent driver

- Texas Instruments, *BQ769x0 3-Series to 15-Series Cell Battery Monitor Family* datasheet, Rev. I.
- Texas Instruments SLUC583 bq769x0 I2C sample code with CRC (BSD-3-Clause), used to cross-check CRC framing.
- Silicon Labs AN495/AN496 CP2112 interface documentation.
- DJI Matrice 30 specifications for the TB30 6S, 5880 mAh, 26.1 V pack.

No original application code is linked into or copied by the new executable.
