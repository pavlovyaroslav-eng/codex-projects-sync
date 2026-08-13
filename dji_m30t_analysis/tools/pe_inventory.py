#!/usr/bin/env python3
"""Static PE inventory and string extraction. The target is never executed."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
from pathlib import Path

import pefile


def entropy(data: bytes) -> float:
    if not data:
        return 0.0
    counts = [0] * 256
    for value in data:
        counts[value] += 1
    size = len(data)
    return -sum((count / size) * math.log2(count / size) for count in counts if count)


def decode_name(value: bytes | None) -> str | None:
    return value.decode("utf-8", "replace") if value else None


def printable_strings(data: bytes, minimum: int) -> list[dict[str, object]]:
    ascii_re = re.compile(rb"[\x20-\x7e]{%d,}" % minimum)
    utf16_re = re.compile(rb"(?:[\x20-\x7e]\x00){%d,}" % minimum)
    found: list[dict[str, object]] = []
    for match in ascii_re.finditer(data):
        found.append({"offset": match.start(), "encoding": "ascii", "text": match.group().decode("ascii")})
    for match in utf16_re.finditer(data):
        found.append({"offset": match.start(), "encoding": "utf-16le", "text": match.group().decode("utf-16le")})
    found.sort(key=lambda item: (int(item["offset"]), str(item["encoding"])))
    return found


def inventory(path: Path, minimum: int) -> dict[str, object]:
    data = path.read_bytes()
    pe = pefile.PE(data=data, fast_load=False)
    pe.parse_data_directories()
    imports: dict[str, list[dict[str, object]]] = {}
    for entry in getattr(pe, "DIRECTORY_ENTRY_IMPORT", []):
        imports[decode_name(entry.dll) or ""] = [
            {"name": decode_name(symbol.name), "ordinal": symbol.ordinal, "iat": symbol.address}
            for symbol in entry.imports
        ]
    delay_imports: dict[str, list[dict[str, object]]] = {}
    for entry in getattr(pe, "DIRECTORY_ENTRY_DELAY_IMPORT", []):
        delay_imports[decode_name(entry.dll) or ""] = [
            {"name": decode_name(symbol.name), "ordinal": symbol.ordinal, "iat": symbol.address}
            for symbol in entry.imports
        ]
    exports: list[dict[str, object]] = []
    if hasattr(pe, "DIRECTORY_ENTRY_EXPORT"):
        exports = [
            {"name": decode_name(symbol.name), "ordinal": symbol.ordinal, "rva": symbol.address}
            for symbol in pe.DIRECTORY_ENTRY_EXPORT.symbols
        ]
    pdb_paths: list[str] = []
    for entry in getattr(pe, "DIRECTORY_ENTRY_DEBUG", []):
        try:
            debug_data = pe.get_data(entry.struct.AddressOfRawData, entry.struct.SizeOfData)
        except Exception:
            continue
        if debug_data.startswith(b"RSDS") and len(debug_data) > 24:
            pdb_paths.append(debug_data[24:].split(b"\0", 1)[0].decode("utf-8", "replace"))
    dll_characteristics = pe.OPTIONAL_HEADER.DllCharacteristics
    mitigations = {
        "aslr_dynamic_base": bool(dll_characteristics & 0x0040),
        "high_entropy_va": bool(dll_characteristics & 0x0020),
        "dep_nx_compat": bool(dll_characteristics & 0x0100),
        "cfg_guard_cf": bool(dll_characteristics & 0x4000),
    }
    sections = []
    for section in pe.sections:
        raw = section.get_data()
        sections.append(
            {
                "name": section.Name.rstrip(b"\0").decode("ascii", "replace"),
                "rva": section.VirtualAddress,
                "virtual_size": section.Misc_VirtualSize,
                "raw_offset": section.PointerToRawData,
                "raw_size": section.SizeOfRawData,
                "entropy": round(entropy(raw), 4),
                "characteristics": section.Characteristics,
            }
        )
    overlay_offset = pe.get_overlay_data_start_offset()
    return {
        "path": str(path.resolve()),
        "size": len(data),
        "sha256": hashlib.sha256(data).hexdigest().upper(),
        "machine": pe.FILE_HEADER.Machine,
        "timestamp": pe.FILE_HEADER.TimeDateStamp,
        "number_of_sections": pe.FILE_HEADER.NumberOfSections,
        "characteristics": pe.FILE_HEADER.Characteristics,
        "image_base": pe.OPTIONAL_HEADER.ImageBase,
        "entry_point_rva": pe.OPTIONAL_HEADER.AddressOfEntryPoint,
        "subsystem": pe.OPTIONAL_HEADER.Subsystem,
        "linker_version": f"{pe.OPTIONAL_HEADER.MajorLinkerVersion}.{pe.OPTIONAL_HEADER.MinorLinkerVersion}",
        "mitigations": mitigations,
        "sections": sections,
        "imports": imports,
        "delay_imports": delay_imports,
        "exports": exports,
        "pdb_paths": pdb_paths,
        "overlay_offset": overlay_offset,
        "overlay_size": len(data) - overlay_offset if overlay_offset is not None else 0,
        "strings": printable_strings(data, minimum),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--minimum", type=int, default=5)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = [inventory(path, args.minimum) for path in args.paths]
    text = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        args.output.write_text(text + "\n", encoding="utf-8")
    else:
        print(text)


if __name__ == "__main__":
    main()
