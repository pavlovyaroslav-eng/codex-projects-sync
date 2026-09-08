# HomeMesh user onboarding

## Purpose

HomeMesh gives a VPN user private access between that user's own computers
while Hiddify remains enabled. It uses the official Tailscale client with the
self-hosted Headscale control server at `https://mesh.hometele.com.ru`.

HomeMesh is an overlay network, not an Internet exit VPN. Do not enable a
Tailscale exit node and do not advertise or accept home-LAN subnet routes in
the standard onboarding flow.

## Isolation model

Each Remnawave user receives a separate Headscale identity. Headscale policy:

```hujson
{
  "grants": [
    {
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "ip": ["*"]
    }
  ]
}
```

This permits a user's own untagged devices to communicate and prevents access
to devices owned by another user. Do not replace it with an allow-all ACL.

Each device gets a different single-use enrolment key. A key is valid for 24
hours by default and is removed from the Windows computer after successful
registration. Never send a reusable global key to customers.

## Administrator algorithm

1. Confirm that the person has an active Remnawave account.
2. On `hometele`, create an enrolment package. Two keys are appropriate for a
   remote computer and a controlling laptop:

   ```bash
   sudo /opt/vpn-migration/scripts/create-homemesh-enrollment.sh USERNAME 2 24h
   ```

3. The command prints only the protected directory path, never the keys. The
   directory is under `/root/homemesh-enrollments/` and contains:

   ```text
   Install-HomeMesh.ps1
   Remove-HomeMesh.ps1
   device-1.authkey
   device-2.authkey
   keys.metadata.jsonl
   README.txt
   ```

4. Export a separate archive for each computer. Substitute the exact directory
   printed by the create command:

   ```bash
   sudo /opt/vpn-migration/scripts/export-homemesh-device-package.sh /root/homemesh-enrollments/EXACT-DIRECTORY 1
   sudo /opt/vpn-migration/scripts/export-homemesh-device-package.sh /root/homemesh-enrollments/EXACT-DIRECTORY 2
   ```

   Each archive contains both scripts, the README and exactly one key. Download
   it with WinSCP or PSCP from `/home/suazzzi/homemesh-outbox/`, deliver it over
   a secure channel, then delete the downloaded server-side archive. Never send
   `keys.metadata.jsonl` or the whole enrolment directory.
5. After both devices register, unused keys can be revoked and removed:

   ```bash
   sudo /opt/vpn-migration/scripts/revoke-homemesh-enrollment.sh /root/homemesh-enrollments/EXACT-DIRECTORY
   ```

6. Confirm ownership and online state without showing credentials:

   ```bash
   sudo docker exec headscale headscale users list
   sudo docker exec headscale headscale nodes list
   ```

## Remote Windows computer

The following enables ICMP diagnostics and Remote Desktop only for the
HomeMesh overlay. It does not expose RDP to the public Internet:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-HomeMesh.ps1 `
  -AuthKeyFile .\device-1.authkey `
  -RemoveAuthKeyFile `
  -DeviceName REMOTE-PC `
  -AllowPing `
  -AllowRDP
```

Windows Home cannot act as a Microsoft RDP host. The installer detects this
and leaves RDP disabled; use a separately approved remote-desktop application
or upgrade Windows. SMB requires an existing Windows share. SSH requires the
Windows OpenSSH Server service.

Optional service switches:

- `-AllowPing` — ICMP echo;
- `-AllowRDP` — TCP 3389 and RDP host activation on supported Windows editions;
- `-AllowSMB` — TCP 445 for already configured shares;
- `-AllowSSH` — TCP 22; it does not install OpenSSH Server.

## Controlling Windows computer

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-HomeMesh.ps1 `
  -AuthKeyFile .\device-2.authkey `
  -RemoveAuthKeyFile `
  -DeviceName USER-LAPTOP `
  -AllowPing `
  -PeerName REMOTE-PC
```

The script elevates through UAC, installs official Tailscale through Winget,
enables unattended mode, rejects subnet routes, checks the Headscale health
endpoint and verifies an address from `100.64.0.0/10`. It stores no auth key in
the diagnostic log.

MagicDNS is enabled by default. If a particular endpoint has a DNS conflict,
rerun with `-DisableMagicDNS` and use the peer's `100.64.0.0/10` address.

## Hiddify coexistence

The Remnawave Hiddify template bypasses these overlay ranges:

```text
100.64.0.0/10
fd7a:115c:a1e0::/48
```

The Windows installer sets the Tailscale interface metric to `5` and does not
enable an exit node or accept advertised routes. Hiddify should remain enabled
during all tests.

## Verification

Run on the controlling computer:

```powershell
& "$env:ProgramFiles\Tailscale\tailscale.exe" status
& "$env:ProgramFiles\Tailscale\tailscale.exe" ping REMOTE-PC
Test-NetConnection REMOTE-PC -Port 3389
route print
Get-NetRoute | Where-Object InterfaceAlias -Like '*Tailscale*'
```

Then test the required application:

```text
RDP: mstsc /v:REMOTE-PC
SMB: \\REMOTE-PC\share
SSH: ssh user@REMOTE-PC
HTTP: http://REMOTE-PC:PORT/
```

Successful `tailscale ping` proves overlay connectivity. A failed application
port with successful overlay ping normally means the Windows service, edition,
local account, share or firewall configuration still needs attention.

## Revocation and Windows rollback

An unused enrolment key can be expired with the server script above. Revoking
a key does not remove an already enrolled computer. To remove a registered
computer, identify its numeric ID and delete only that node:

```bash
sudo docker exec headscale headscale nodes list
sudo docker exec headscale headscale nodes delete --identifier NODE_ID
```

On Windows, disconnect HomeMesh and remove only its firewall rules:

```powershell
powershell -ExecutionPolicy Bypass -File .\Remove-HomeMesh.ps1
```

Add `-UninstallTailscale` only when the Tailscale application itself should
also be removed. Installer state and non-secret diagnostics remain in
`C:\ProgramData\HomeMesh\`.
