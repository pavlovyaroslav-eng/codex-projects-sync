rule Executable_Header_MZ {
  meta:
    description = "Identifies a DOS/PE MZ header; not a malware verdict"
  condition:
    uint16(0) == 0x5a4d
}

rule Executable_Header_ELF {
  meta:
    description = "Identifies an ELF header; not a malware verdict"
  condition:
    uint32(0) == 0x464c457f
}
