# Rollback

- `sudo local-ai-rollback qwen14` returns the supported default GPU profile.
- `local-ai-rollback list` lists configuration archives.
- `local-ai-rollback inspect ARCHIVE` verifies SHA256 and lists an archive without
  applying it.
- Selective configuration restore is described in `docs/recovery.md`.
- GRUB recovery uses `/usr/local/sbin/local-ai-recover-grub` only from a correctly
  mounted UEFI/chroot environment.

There is intentionally no blind "restore everything" command: systemd, firewall,
EFI and database changes must be compared before selective restore.

