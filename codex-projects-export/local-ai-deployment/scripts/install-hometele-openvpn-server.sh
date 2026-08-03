#!/usr/bin/env bash
set -Eeuo pipefail

VPN_PORT="${VPN_PORT:-21200}"
VPN_NETWORK="${VPN_NETWORK:-10.93.0.0}"
VPN_NETMASK="${VPN_NETMASK:-255.255.255.0}"
VPN_ENDPOINT="${VPN_ENDPOINT:-matrix.hometele.com.ru}"
SERVER_CN="local-ai-server"
PKI_ROOT="/etc/openvpn/local-ai-pki"
SERVER_ROOT="/etc/openvpn/server"
CCD_ROOT="/etc/openvpn/ccd-local-ai"
EXPORT_ROOT="/var/lib/local-ai-openvpn/export"
STATE_ROOT="/var/lib/local-ai-openvpn"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_ROOT="/var/backups/openvpn-local-ai-${STAMP}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi
if [[ -e "${SERVER_ROOT}/local-ai.conf" ]] && \
   ! grep -Fq '# managed-by: local-ai-deployment' "${SERVER_ROOT}/local-ai.conf"; then
  echo "Refusing to replace unmanaged ${SERVER_ROOT}/local-ai.conf" >&2
  exit 1
fi
if ss -H -lun | awk '{print $5}' | grep -Eq "(^|:)${VPN_PORT}$" && \
   ! systemctl is-active --quiet openvpn-server@local-ai.service; then
  echo "UDP ${VPN_PORT} is already in use." >&2
  exit 1
fi
if ip -4 route show | grep -q '^10\.93\.0\.0/24'; then
  if ! ip -brief link show tun93 >/dev/null 2>&1; then
    echo "10.93.0.0/24 is already routed by another interface." >&2
    exit 1
  fi
fi

umask 077
install -d -m 0700 "${BACKUP_ROOT}" "${STATE_ROOT}" "${EXPORT_ROOT}"
if [[ -d /etc/openvpn ]]; then
  cp -a /etc/openvpn "${BACKUP_ROOT}/openvpn.before"
else
  : >"${BACKUP_ROOT}/openvpn.was-absent"
fi
cp -a /etc/ufw/user.rules /etc/ufw/user6.rules "${BACKUP_ROOT}/"
dpkg-query -W openvpn easy-rsa >"${BACKUP_ROOT}/packages.before.txt" 2>&1 || true
systemctl list-units --type=service --all 'openvpn*' --no-pager \
  >"${BACKUP_ROOT}/openvpn-services.before.txt"
ss -lunpt >"${BACKUP_ROOT}/sockets.before.txt"
ip -4 route >"${BACKUP_ROOT}/routes.before.txt"
ufw status numbered >"${BACKUP_ROOT}/ufw.before.txt"
printf '%s\n' "${BACKUP_ROOT}" >"${STATE_ROOT}/last-backup"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends openvpn easy-rsa

install -d -m 0700 "${PKI_ROOT}"
install -d -m 0755 "${SERVER_ROOT}" "${CCD_ROOT}"
EASYRSA=/usr/share/easy-rsa/easyrsa
run_easyrsa() {
  EASYRSA_BATCH=1 EASYRSA_PKI="${PKI_ROOT}/pki" EASYRSA_ALGO=ec \
  EASYRSA_CURVE=prime256v1 EASYRSA_DIGEST=sha256 EASYRSA_CA_EXPIRE=3650 \
  EASYRSA_CERT_EXPIRE=1825 EASYRSA_CRL_DAYS=3650 "${EASYRSA}" "$@"
}

if [[ ! -s "${PKI_ROOT}/pki/ca.crt" ]]; then
  run_easyrsa init-pki
  EASYRSA_REQ_CN='Local AI isolated VPN CA' run_easyrsa build-ca nopass
fi
[[ -s "${PKI_ROOT}/pki/issued/${SERVER_CN}.crt" ]] || \
  run_easyrsa build-server-full "${SERVER_CN}" nopass
for client in local-ai owner-laptop; do
  [[ -s "${PKI_ROOT}/pki/issued/${client}.crt" ]] || \
    run_easyrsa build-client-full "${client}" nopass
done
run_easyrsa gen-crl

install -m 0644 "${PKI_ROOT}/pki/ca.crt" "${SERVER_ROOT}/local-ai-ca.crt"
install -m 0644 "${PKI_ROOT}/pki/issued/${SERVER_CN}.crt" "${SERVER_ROOT}/local-ai-server.crt"
install -m 0600 "${PKI_ROOT}/pki/private/${SERVER_CN}.key" "${SERVER_ROOT}/local-ai-server.key"
install -m 0644 "${PKI_ROOT}/pki/crl.pem" "${SERVER_ROOT}/local-ai-crl.pem"
if [[ ! -s "${SERVER_ROOT}/local-ai-tls-crypt.key" ]]; then
  openvpn --genkey secret "${SERVER_ROOT}/local-ai-tls-crypt.key"
fi
chmod 0600 "${SERVER_ROOT}/local-ai-tls-crypt.key"

cat >"${SERVER_ROOT}/local-ai.conf" <<EOF
# managed-by: local-ai-deployment
port ${VPN_PORT}
proto udp4
dev tun93
topology subnet
server ${VPN_NETWORK} ${VPN_NETMASK}
dh none
client-to-client
client-config-dir ${CCD_ROOT}
verify-client-cert require
remote-cert-tls client
ca ${SERVER_ROOT}/local-ai-ca.crt
cert ${SERVER_ROOT}/local-ai-server.crt
key ${SERVER_ROOT}/local-ai-server.key
crl-verify ${SERVER_ROOT}/local-ai-crl.pem
tls-crypt ${SERVER_ROOT}/local-ai-tls-crypt.key
tls-version-min 1.2
tls-cert-profile preferred
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
data-ciphers-fallback AES-256-GCM
auth SHA256
keepalive 10 60
persist-key
persist-tun
user nobody
group nogroup
explicit-exit-notify 1
verb 3
EOF
chmod 0600 "${SERVER_ROOT}/local-ai.conf"
printf '%s\n' 'ifconfig-push 10.93.0.10 255.255.255.0' >"${CCD_ROOT}/local-ai"
printf '%s\n' 'ifconfig-push 10.93.0.11 255.255.255.0' >"${CCD_ROOT}/owner-laptop"
chmod 0644 "${CCD_ROOT}/local-ai" "${CCD_ROOT}/owner-laptop"

build_profile() {
  local cn="$1" device="$2" output="${EXPORT_ROOT}/${1}.ovpn"
  {
    cat <<EOF
client
dev ${device}
proto udp4
remote ${VPN_ENDPOINT} ${VPN_PORT}
nobind
persist-key
persist-tun
resolv-retry infinite
remote-cert-tls server
verify-x509-name ${SERVER_CN} name
tls-version-min 1.2
tls-cert-profile preferred
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
auth SHA256
auth-nocache
pull-filter ignore "redirect-gateway"
pull-filter ignore "dhcp-option"
verb 3
<ca>
EOF
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' "${PKI_ROOT}/pki/ca.crt"
    printf '%s\n' '</ca>' '<cert>'
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' "${PKI_ROOT}/pki/issued/${cn}.crt"
    printf '%s\n' '</cert>' '<key>'
    cat "${PKI_ROOT}/pki/private/${cn}.key"
    printf '%s\n' '</key>' '<tls-crypt>'
    cat "${SERVER_ROOT}/local-ai-tls-crypt.key"
    printf '%s\n' '</tls-crypt>'
  } >"${output}"
  chmod 0600 "${output}"
}
build_profile local-ai tun93
build_profile owner-laptop tun

if ! ufw status | grep -Eq "^${VPN_PORT}/udp\s+ALLOW"; then
  ufw allow "${VPN_PORT}/udp" comment 'OpenVPN local-ai tun93'
fi
systemctl disable --now openvpn.service >/dev/null 2>&1 || true
systemctl daemon-reload
systemctl enable --now openvpn-server@local-ai.service

for _ in {1..30}; do
  systemctl is-active --quiet openvpn-server@local-ai.service && \
    ip -4 addr show dev tun93 | grep -Fq '10.93.0.1/24' && break
  sleep 1
done
systemctl is-active --quiet openvpn-server@local-ai.service
ip -4 addr show dev tun93 | grep -F '10.93.0.1/24'
ss -H -lunp | grep -E ":${VPN_PORT}\b"
openssl verify -CAfile "${PKI_ROOT}/pki/ca.crt" \
  "${PKI_ROOT}/pki/issued/${SERVER_CN}.crt" \
  "${PKI_ROOT}/pki/issued/local-ai.crt" \
  "${PKI_ROOT}/pki/issued/owner-laptop.crt"
echo "Backup: ${BACKUP_ROOT}"
echo "Profiles: ${EXPORT_ROOT}/local-ai.ovpn and owner-laptop.ovpn"
