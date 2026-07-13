#!/usr/bin/env bash
# collect-inventory.sh
# Safe inventory collector for the VPN Server WIKI.
# It collects structure, services, ports and presence/fingerprints only.
# It must NOT dump private keys, tokens, UUIDs, client links or full secret configs.

set -u
umask 077

OUT_DIR="${1:-./inventory}"
TS="$(date +%Y-%m-%d_%H-%M-%S)"
HOST="$(hostname -s 2>/dev/null || echo unknown)"
FQDN="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"
OUT="${OUT_DIR%/}/${HOST}-inventory-${TS}.md"
LATEST="${OUT_DIR%/}/${HOST}-latest.md"

mkdir -p "$OUT_DIR"

redact_stream() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import re, sys
text = sys.stdin.read()
# UUID/client IDs
text = re.sub(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\b", "[UUID-REDACTED]", text)
# Common secret key/value forms in logs/config snippets
secret_keys = r"(password|passwd|token|access_token|refresh_token|secret|mtproto_secret|privateKey|private_key|secretKey|secret_key|auth|uuid)"
text = re.sub(r"(?i)(" + secret_keys + r")\s*[:=]\s*[\"\x27]?[^\"\x27\s,}]+", lambda m: m.group(1) + ": [REDACTED]", text)
# VPN/client links
text = re.sub(r"\b(vless|vmess|trojan|hysteria2|hy2|ss|ssr)://\S+", "[VPN-LINK-REDACTED]", text, flags=re.I)
# Obvious bearer/basic credentials
text = re.sub(r"(?i)\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+", r"\1 [REDACTED]", text)
sys.stdout.write(text)
'
  else
    sed -E \
      -e 's/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}/[UUID-REDACTED]/g' \
      -e 's#(vless|vmess|trojan|hysteria2|hy2|ss|ssr)://[^[:space:]]+#[VPN-LINK-REDACTED]#Ig' \
      -e 's/(password|passwd|token|secret|privateKey|private_key|secretKey|secret_key|auth|uuid)[[:space:]]*[:=][[:space:]]*[^[:space:],}]+/\1: [REDACTED]/Ig'
  fi
}

append() { printf '%s\n' "$*" >> "$OUT"; }

run_cmd() {
  local title="$1"
  local cmd="$2"
  append ""
  append "## ${title}"
  append '```text'
  if command -v timeout >/dev/null 2>&1; then
    timeout 20 bash -o pipefail -c "$cmd" 2>&1 | redact_stream >> "$OUT" || true
  else
    bash -o pipefail -c "$cmd" 2>&1 | redact_stream >> "$OUT" || true
  fi
  append '```'
}

write_header() {
  cat > "$OUT" <<EOF_HEADER
# Inventory snapshot: ${HOST}

Generated: $(date -Is)  
Host: ${HOST}  
FQDN: ${FQDN}  
Collector: collect-inventory.sh  
Mode: safe / no secrets / no full configs

> This file is intended for the VPN Server WIKI Git repository. It must contain structure and operational facts only.
> Do not paste private keys, tokens, passwords, client UUIDs, MTProto secrets, Reality/WARP private keys or ready VPN links here.
EOF_HEADER
}

systemd_table() {
  append ""
  append "## Systemd services of interest"
  append "| Service | Active | Enabled | Unit file present |"
  append "|---|---:|---:|---:|"
  local services=(
    xray x-ui 3x-ui nginx apache2 postfix dovecot fail2ban openvpn
    wg-quick@wg-home matrix-synapse coturn hometele-command-agent hometele-ai
    docker cron crond ssh sshd
  )
  local s active enabled present
  for s in "${services[@]}"; do
    active="$(systemctl is-active "$s" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "$s" 2>/dev/null || true)"
    if systemctl cat "$s" >/dev/null 2>&1; then present="yes"; else present="no"; fi
    [[ -z "$active" ]] && active="unknown"
    [[ -z "$enabled" ]] && enabled="unknown"
    append "| \`${s}\` | ${active} | ${enabled} | ${present} |"
  done
}

important_paths() {
  append ""
  append "## Important paths: presence only"
  append "| Path | Type | Owner | Mode | Size | Modified |"
  append "|---|---:|---:|---:|---:|---:|"
  local paths=(
    /usr/local/etc/xray/config.json
    /etc/xray/config.json
    /etc/nginx
    /etc/fail2ban
    /etc/postfix
    /etc/dovecot
    /etc/cron.d/server-maintenance
    /opt/server-maintenance
    /usr/local/sbin/hometele-vpn-user
    /usr/local/sbin/hometele-vpn-ssh-wrapper
    /usr/local/sbin/www-hometele-vpn
    /usr/local/bin/hometele-command-agent.py
    /etc/hometele-monitor/command-agent.conf
    /var/lib/hometele-monitor/command-agent.since
    /etc/systemd/system/hometele-command-agent.service
    /etc/systemd/system/hometele-ai.service
    /root/.ssh
    /etc/letsencrypt
    /root/cert
    /etc/x-ui
    /etc/3x-ui
  )
  local p type owner mode size mtime
  for p in "${paths[@]}"; do
    if [[ -e "$p" ]]; then
      type="$(stat -c '%F' "$p" 2>/dev/null || echo '?')"
      owner="$(stat -c '%U:%G' "$p" 2>/dev/null || echo '?')"
      mode="$(stat -c '%a' "$p" 2>/dev/null || echo '?')"
      size="$(stat -c '%s' "$p" 2>/dev/null || echo '?')"
      mtime="$(stat -c '%y' "$p" 2>/dev/null | cut -d'.' -f1 || echo '?')"
      append "| \`${p}\` | ${type} | ${owner} | ${mode} | ${size} | ${mtime} |"
    else
      append "| \`${p}\` | missing | - | - | - | - |"
    fi
  done
}

ssh_fingerprints() {
  append ""
  append "## SSH keys: fingerprints only"
  append '```text'
  if command -v ssh-keygen >/dev/null 2>&1 && [[ -d /root/.ssh ]]; then
    find /root/.ssh -maxdepth 1 -type f \( -name '*.pub' -o -name 'id_*' -o -name '*key*' \) -print 2>/dev/null | while read -r f; do
      printf '%s -> ' "$f"
      ssh-keygen -lf "$f" 2>/dev/null || echo 'not a public/private SSH key or unreadable'
    done | redact_stream >> "$OUT" || true
  else
    echo "No /root/.ssh or ssh-keygen not available." >> "$OUT"
  fi
  append '```'
}

wireguard_summary() {
  append ""
  append "## WireGuard summary: no keys"
  append '```text'
  if command -v wg >/dev/null 2>&1; then
    ifaces="$(wg show interfaces 2>/dev/null || true)"
    if [[ -z "$ifaces" ]]; then
      echo "No active WireGuard interfaces." >> "$OUT"
    else
      for iface in $ifaces; do
        echo "interface: ${iface}" >> "$OUT"
        echo "  listen_port: $(wg show "$iface" listen-port 2>/dev/null || echo '-')" >> "$OUT"
        echo "  peer_count: $(wg show "$iface" peers 2>/dev/null | wc -l)" >> "$OUT"
        echo "" >> "$OUT"
      done
    fi
  else
    echo "wg command not found." >> "$OUT"
  fi
  append '```'
}

fail2ban_summary() {
  append ""
  append "## Fail2Ban summary"
  append '```text'
  if command -v fail2ban-client >/dev/null 2>&1; then
    fail2ban-client status 2>&1 | redact_stream >> "$OUT" || true
    jails="$(fail2ban-client status 2>/dev/null | awk -F: '/Jail list/{gsub(/,/," ",$2); print $2}' || true)"
    for jail in $jails; do
      echo "" >> "$OUT"
      echo "jail: ${jail}" >> "$OUT"
      fail2ban-client status "$jail" 2>/dev/null | awk '/Currently failed:|Total failed:|Currently banned:|Total banned:/{print}' >> "$OUT" || true
    done
  else
    echo "fail2ban-client not found." >> "$OUT"
  fi
  append '```'
}

xray_summary() {
  local cfg=""
  if [[ -r /usr/local/etc/xray/config.json ]]; then cfg="/usr/local/etc/xray/config.json"; fi
  if [[ -z "$cfg" && -r /etc/xray/config.json ]]; then cfg="/etc/xray/config.json"; fi

  append ""
  append "## Xray config summary: sanitized"
  append '```text'
  if [[ -z "$cfg" ]]; then
    echo "No readable Xray config found in known paths." >> "$OUT"
    append '```'
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    XCFG="$cfg" python3 - <<'PY' | redact_stream >> "$OUT"
import json, os, sys
p = os.environ.get('XCFG')
try:
    with open(p, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print(f"config: {p}")
    print(f"error: {e}")
    sys.exit(0)
print(f"config: {p}")
print(f"inbounds_count: {len(data.get('inbounds', []))}")
for i, ib in enumerate(data.get('inbounds', []), 1):
    st = ib.get('streamSettings') or {}
    settings = ib.get('settings') or {}
    clients = settings.get('clients') or []
    flows = sorted({c.get('flow') for c in clients if isinstance(c, dict) and c.get('flow')})
    print(f"inbound_{i}: tag={ib.get('tag','-')} listen={ib.get('listen','-')} port={ib.get('port','-')} protocol={ib.get('protocol','-')} network={st.get('network','-')} security={st.get('security','-')} clients_count={len(clients)}")
    if flows:
        print(f"  flows: {', '.join(flows)}")
    reality = st.get('realitySettings') or {}
    if reality:
        print(f"  reality_target: {reality.get('target','-')}")
        print(f"  reality_server_names: {', '.join(reality.get('serverNames') or [])}")
        print(f"  reality_short_ids_count: {len(reality.get('shortIds') or [])}")
    tls = st.get('tlsSettings') or {}
    if tls:
        print(f"  tls_server_name: {tls.get('serverName','-')}")
        certs = tls.get('certificates') or []
        for n, cert in enumerate(certs, 1):
            print(f"  tls_cert_{n}: certificateFile={cert.get('certificateFile','-')} keyFile=[REDACTED-PATH]")
print(f"outbounds_count: {len(data.get('outbounds', []))}")
for ob in data.get('outbounds', []):
    print(f"outbound: tag={ob.get('tag','-')} protocol={ob.get('protocol','-')}")
routing = data.get('routing') or {}
print(f"routing_domain_strategy: {routing.get('domainStrategy','-')}")
print(f"routing_rules_count: {len(routing.get('rules', []))}")
dns = data.get('dns') or {}
if dns:
    print(f"dns_servers_count: {len(dns.get('servers', []))}")
PY
  else
    echo "python3 not found; cannot summarize JSON safely." >> "$OUT"
  fi
  append '```'
}

nginx_summary() {
  append ""
  append "## Nginx summary: listen/server_name only"
  append '```text'
  if command -v nginx >/dev/null 2>&1; then
    nginx -v 2>&1 | redact_stream >> "$OUT" || true
    echo "" >> "$OUT"
    if [[ -d /etc/nginx ]]; then
      grep -RhsE '^[[:space:]]*(listen|server_name)[[:space:]]+' /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null \
        | sed -E 's/[[:space:]]+/ /g' \
        | sort -u \
        | redact_stream >> "$OUT" || true
    fi
  else
    echo "nginx not found." >> "$OUT"
  fi
  append '```'
}

postfix_summary() {
  append ""
  append "## Postfix summary: selected safe settings only"
  append '```text'
  if command -v postconf >/dev/null 2>&1; then
    postconf -n 2>/dev/null \
      | grep -E '^(myhostname|mydomain|myorigin|mydestination|relayhost|inet_interfaces|inet_protocols|smtpd_tls_cert_file|smtpd_tls_key_file|smtpd_tls_security_level|smtp_tls_security_level|virtual_alias_maps|smtpd_recipient_restrictions|smtpd_sender_restrictions) =' \
      | sed -E 's#(smtpd_tls_key_file = ).*#\1[REDACTED-PATH]#' \
      | redact_stream >> "$OUT" || true
  else
    echo "postconf not found." >> "$OUT"
  fi
  append '```'
}

docker_summary() {
  append ""
  append "## Docker containers"
  append '```text'
  if command -v docker >/dev/null 2>&1; then
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>&1 | redact_stream >> "$OUT" || true
  else
    echo "docker not found." >> "$OUT"
  fi
  append '```'
}

write_header
run_cmd "OS / kernel / uptime" "cat /etc/os-release 2>/dev/null; echo; hostnamectl 2>/dev/null || true; echo; uname -a; echo; uptime"
run_cmd "Network addresses" "ip -brief address 2>/dev/null || true"
run_cmd "Routes" "ip route 2>/dev/null || true; echo; ip -6 route 2>/dev/null || true"
run_cmd "Listening ports" "ss -lntup 2>/dev/null || ss -lntu 2>/dev/null || true"
systemd_table
run_cmd "Package versions of interest" "dpkg-query -W -f='\${binary:Package}\t\${Version}\n' xray x-ui 3x-ui nginx apache2 postfix dovecot-core fail2ban openvpn wireguard wireguard-tools coturn matrix-synapse docker.io docker-ce python3 git ufw iptables nftables 2>/dev/null || true"
run_cmd "Firewall summary" "ufw status verbose 2>/dev/null || true; echo; iptables -S 2>/dev/null | head -200 || true; echo; nft list ruleset 2>/dev/null | head -220 || true"
wireguard_summary
fail2ban_summary
docker_summary
xray_summary
nginx_summary
postfix_summary
important_paths
ssh_fingerprints
run_cmd "Maintenance cron" "cat /etc/cron.d/server-maintenance 2>/dev/null || true; echo; ls -lah /opt/server-maintenance 2>/dev/null || true; echo; ls -lah /var/log/server-maintenance 2>/dev/null || true"
run_cmd "Reboot required marker" "if [ -f /var/run/reboot-required ]; then echo 'reboot_required: yes'; cat /var/run/reboot-required.pkgs 2>/dev/null || true; else echo 'reboot_required: no'; fi"

ln -sfn "$(basename "$OUT")" "$LATEST" 2>/dev/null || cp -f "$OUT" "$LATEST" 2>/dev/null || true
chmod 600 "$OUT" "$LATEST" 2>/dev/null || true

echo "OK: inventory saved to $OUT"
echo "OK: latest link/copy is $LATEST"
echo "Next: review the file before committing it to Git."
