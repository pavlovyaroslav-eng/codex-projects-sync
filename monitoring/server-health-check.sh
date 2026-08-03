#!/bin/bash
# Universal health check script for VPN infrastructure
# Optimized for azazello, hometele, www servers
# Usage: ./server-health-check.sh [hostname]
# Output: JSON format for easy parsing
# SSH Port: 52000 (non-standard)
# Version: 2.0

set -euo pipefail

HOSTNAME="${1:-$(hostname)}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION="2.0"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# JSON escaping
json_escape() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//'
}

# Check if command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# System info
get_uptime() {
    uptime -p 2>/dev/null || uptime | awk '{print $3,$4}'
}

get_load() {
    uptime | awk -F'load average:' '{print $2}' | xargs
}

get_cpu_usage() {
    if has_cmd mpstat; then
        mpstat 1 1 | awk '/Average:/ {print 100 - $NF"%"}'
    else
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//'
    fi
}

get_memory() {
    free -h | awk '/^Mem:/ {printf "{\"total\":\"%s\",\"used\":\"%s\",\"free\":\"%s\",\"usage\":\"%.1f%%\"}", $2, $3, $4, ($3/$2)*100}'
}

get_disk() {
    df -h / | awk 'NR==2 {printf "{\"total\":\"%s\",\"used\":\"%s\",\"free\":\"%s\",\"usage\":\"%s\"}", $2, $3, $4, $5}'
}

# Network checks
get_interfaces() {
    ip -br addr | awk '{printf "{\"iface\":\"%s\",\"state\":\"%s\",\"ip\":\"%s\"},", $1, $2, $3}' | sed 's/,$//'
}

get_listening_ports() {
    ss -lntup | grep LISTEN | awk '{print $5}' | awk -F: '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/,$//'
}

# Service checks
check_systemd_services() {
    local services=""
    case "$HOSTNAME" in
        azazello*)
            services="xray docker fail2ban ufw"
            ;;
        hometele*)
            services="xray postfix fail2ban ufw"
            ;;
        www*)
            services="matrix-synapse coturn nginx fail2ban ufw"
            ;;
        *)
            services="fail2ban ufw"
            ;;
    esac

    local result="["
    for svc in $services; do
        if systemctl list-unit-files | grep -q "^${svc}.service"; then
            local status=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
            local enabled=$(systemctl is-enabled "$svc" 2>/dev/null || echo "unknown")
            result+="{\"name\":\"$svc\",\"status\":\"$status\",\"enabled\":\"$enabled\"},"
        fi
    done
    echo "$result" | sed 's/,$/]/'
}

# VPN-specific checks
check_xray() {
    local result="{\"installed\":false}"
    if has_cmd xray; then
        local version=$(xray version 2>/dev/null | head -1 || echo "unknown")
        local running=$(pgrep -x xray >/dev/null && echo "true" || echo "false")
        result="{\"installed\":true,\"version\":\"$(json_escape "$version")\",\"running\":$running}"
    fi
    echo "$result"
}

check_wireguard() {
    local result="[]"
    if has_cmd wg; then
        local interfaces=$(wg show interfaces 2>/dev/null || echo "")
        if [ -n "$interfaces" ]; then
            result="["
            for iface in $interfaces; do
                local peers=$(wg show "$iface" | grep -c "peer:" || echo 0)
                result+="{\"interface\":\"$iface\",\"peers\":$peers},"
            done
            result=$(echo "$result" | sed 's/,$/]/')
        fi
    fi
    echo "$result"
}

check_openvpn() {
    local result="[]"
    if [ -d /etc/openvpn ]; then
        local tunnels=$(ip link show | grep -c "tun" || echo 0)
        result="[{\"tunnels\":$tunnels}]"
    fi
    echo "$result"
}

# Docker checks
check_docker() {
    local result="{\"installed\":false}"
    if has_cmd docker; then
        local running=$(docker ps --format "{{.Names}}" 2>/dev/null | wc -l)
        local total=$(docker ps -a --format "{{.Names}}" 2>/dev/null | wc -l)
        result="{\"installed\":true,\"running\":$running,\"total\":$total}"
    fi
    echo "$result"
}

# Security checks
check_failed_services() {
    systemctl --failed --no-pager --no-legend | wc -l
}

check_fail2ban() {
    local result="{\"installed\":false}"
    if has_cmd fail2ban-client; then
        local jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | sed 's/.*://' | xargs | tr ' ' ',')
        result="{\"installed\":true,\"jails\":\"$jails\"}"
    fi
    echo "$result"
}

check_ufw() {
    local result="{\"installed\":false}"
    if has_cmd ufw; then
        local status=$(sudo ufw status 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        result="{\"installed\":true,\"status\":\"$status\"}"
    fi
    echo "$result"
}

# Critical port checks
check_critical_ports() {
    local result="["
    case "$HOSTNAME" in
        azazello*|hometele*)
            local port443=$(ss -ltn | grep -q ":443 " && echo "listening" || echo "not-listening")
            result+="{\"port\":443,\"status\":\"$port443\",\"critical\":true},"
            ;;
    esac
    echo "$result" | sed 's/,$/]/'
}

# Main JSON output
cat <<EOF
{
  "hostname": "$HOSTNAME",
  "timestamp": "$TIMESTAMP",
  "system": {
    "uptime": "$(get_uptime)",
    "load": "$(get_load)",
    "cpu_usage": "$(get_cpu_usage)",
    "memory": $(get_memory),
    "disk": $(get_disk)
  },
  "network": {
    "interfaces": [$(get_interfaces)],
    "listening_ports": [$(get_listening_ports)]
  },
  "services": {
    "systemd": $(check_systemd_services),
    "failed_count": $(check_failed_services)
  },
  "vpn": {
    "xray": $(check_xray),
    "wireguard": $(check_wireguard),
    "openvpn": $(check_openvpn)
  },
  "containers": $(check_docker),
  "security": {
    "fail2ban": $(check_fail2ban),
    "ufw": $(check_ufw)
  },
  "critical_ports": $(check_critical_ports)
}
EOF
