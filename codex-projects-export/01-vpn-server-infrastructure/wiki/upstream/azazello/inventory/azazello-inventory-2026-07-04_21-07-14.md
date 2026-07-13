# Inventory snapshot: azazello

Generated: 2026-07-04T21:07:14+00:00  
Host: azazello  
FQDN: azazello  
Collector: collect-inventory.sh  
Mode: safe / no secrets / no full configs

> This file is intended for the VPN Server WIKI Git repository. It must contain structure and operational facts only.
> Do not paste private keys, tokens, passwords, client UUIDs, MTProto secrets, Reality/WARP private keys or ready VPN links here.

## OS / kernel / uptime
```text
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo

 Static hostname: azazello
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: da22c5b88e7e42878bac05c5c8b46e4f
         Boot ID: e1cc3fd3e96044faa4796e5e9fa51695
  Virtualization: xen
Operating System: Ubuntu 24.04.4 LTS
          Kernel: Linux 6.8.0-107-generic
    Architecture: x86-64
 Hardware Vendor: Xen
  Hardware Model: HVM domU
Firmware Version: 4.13
   Firmware Date: Fri 2020-06-12
    Firmware Age: 6y 3w 1d

Linux azazello 6.8.0-107-generic #107-Ubuntu SMP PREEMPT_DYNAMIC Fri Mar 13 19:51:50 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux

 21:07:14 up 28 days,  9:47,  1 user,  load average: 4.26, 2.97, 2.47
```

## Network addresses
```text
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             91.242.163.206/24 2a00:fd40:c:3091::1/64 fe80::216:3eff:feab:5be3/64 
br-566ebeb0f4f1  UP             172.18.0.1/16 fe80::46f:8eff:fe1f:36e/64 
amn0             UP             172.29.172.1/24 fe80::50b7:4cff:fe73:3280/64 
docker0          UP             172.17.0.1/16 fe80::1005:7aff:fe69:2e83/64 
veth31b2825@if2  UP             fe80::8020:4fff:feae:d7d5/64 
veth553c896@if2  UP             fe80::f0c1:60ff:fe59:543d/64 
veth26bb241@if3  UP             fe80::801:bbff:fe73:acb6/64 
veth55612f1@if2  UP             fe80::c4c5:52ff:fe1a:58c/64 
tun-home-udp     UNKNOWN        10.77.0.1/24 fe80::2907:9504:1c80:31bc/64 
tun-home-tcp     UNKNOWN        10.78.0.1/24 fe80::1aa:a170:1f66:4b6e/64 
wg-home          UNKNOWN        10.77.77.1/24 
tun79            UNKNOWN        10.79.0.1 peer 10.79.0.2/32 fe80::e3c9:7743:df7b:4dd/64 
wg0              UNKNOWN        172.16.0.2/32 2606:4700:110:8522:d608:2fba:6dba:94bf/128 fe80::f0bc:9a8a:ad66:a4fe/64 
```

## Routes
```text
default via 91.242.163.1 dev eth0 onlink 
10.77.0.0/24 dev tun-home-udp proto kernel scope link src 10.77.0.1 
10.77.77.0/24 dev wg-home proto kernel scope link src 10.77.77.1 
10.78.0.0/24 dev tun-home-tcp proto kernel scope link src 10.78.0.1 
10.79.0.2 dev tun79 proto kernel scope link src 10.79.0.1 
91.242.163.0/24 dev eth0 proto kernel scope link src 91.242.163.206 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 
172.18.0.0/16 dev br-566ebeb0f4f1 proto kernel scope link src 172.18.0.1 
172.29.172.0/24 dev amn0 proto kernel scope link src 172.29.172.1 
192.168.77.0/24 dev wg-home scope link 

2606:4700:110:8522:d608:2fba:6dba:94bf dev wg0 proto kernel metric 256 pref medium
2a00:fd40:c:3091::/64 dev eth0 proto kernel metric 256 pref medium
fe80::/64 dev eth0 proto kernel metric 256 pref medium
fe80::/64 dev veth31b2825 proto kernel metric 256 pref medium
fe80::/64 dev br-566ebeb0f4f1 proto kernel metric 256 pref medium
fe80::/64 dev veth553c896 proto kernel metric 256 pref medium
fe80::/64 dev amn0 proto kernel metric 256 pref medium
fe80::/64 dev veth26bb241 proto kernel metric 256 pref medium
fe80::/64 dev docker0 proto kernel metric 256 pref medium
fe80::/64 dev tun-home-udp proto kernel metric 256 pref medium
fe80::/64 dev tun-home-tcp proto kernel metric 256 pref medium
fe80::/64 dev tun79 proto kernel metric 256 pref medium
fe80::/64 dev wg0 proto kernel metric 256 pref medium
fe80::/64 dev veth55612f1 proto kernel metric 256 pref medium
default via 2a00:fd40:c:3000::1 dev eth0 metric 1024 onlink pref medium
```

## Listening ports
```text
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess                                                     
udp   UNCONN 0      0            0.0.0.0:1194       0.0.0.0:*    users:(("openvpn",pid=584119,fd=5))                        
udp   UNCONN 0      0          127.0.0.1:5353       0.0.0.0:*    users:(("unbound",pid=575969,fd=3))                        
udp   UNCONN 0      0         127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=16))               
udp   UNCONN 0      0      127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=14))               
udp   UNCONN 0      0          127.0.0.1:8388       0.0.0.0:*    users:(("ss-server",pid=1087,fd=8))                        
udp   UNCONN 0      0            0.0.0.0:39425      0.0.0.0:*    users:(("docker-proxy",pid=1737,fd=7))                     
udp   UNCONN 0      0            0.0.0.0:51820      0.0.0.0:*                                                               
udp   UNCONN 0      0            0.0.0.0:21194      0.0.0.0:*    users:(("openvpn",pid=709029,fd=5))                        
udp   UNCONN 0      0                  *:46539            *:*    users:(("xray-linux-amd6",pid=712801,fd=16))               
udp   UNCONN 0      0              [::1]:8388          [::]:*    users:(("ss-server",pid=1087,fd=7))                        
udp   UNCONN 0      0               [::]:39425         [::]:*    users:(("docker-proxy",pid=1743,fd=7))                     
udp   UNCONN 0      0                  *:33328            *:*    users:(("xray-linux-amd6",pid=712801,fd=20))               
udp   UNCONN 0      0               [::]:51820         [::]:*                                                               
tcp   LISTEN 0      256        127.0.0.1:5353       0.0.0.0:*    users:(("unbound",pid=575969,fd=4))                        
tcp   LISTEN 0      4096         0.0.0.0:9443       0.0.0.0:*    users:(("docker-proxy",pid=1021446,fd=7))                  
tcp   LISTEN 0      4096       127.0.0.1:62789      0.0.0.0:*    users:(("xray-linux-amd6",pid=712801,fd=14))               
tcp   LISTEN 0      4096       127.0.0.1:46341      0.0.0.0:*    users:(("containerd",pid=928209,fd=21))                    
tcp   LISTEN 0      4096         0.0.0.0:52000      0.0.0.0:*    users:(("sshd",pid=759351,fd=3),("systemd",pid=1,fd=160))  
tcp   LISTEN 0      4096       127.0.0.1:11111      0.0.0.0:*    users:(("xray-linux-amd6",pid=712801,fd=23))               
tcp   LISTEN 0      1024       127.0.0.1:8388       0.0.0.0:*    users:(("ss-server",pid=1087,fd=6))                        
tcp   LISTEN 0      4096      127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=17))               
tcp   LISTEN 0      32           0.0.0.0:8443       0.0.0.0:*    users:(("openvpn",pid=584123,fd=5))                        
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=567295,fd=5),("nginx",pid=567221,fd=5))
tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=15))               
tcp   LISTEN 0      100          0.0.0.0:25         0.0.0.0:*    users:(("master",pid=796110,fd=13))                        
tcp   LISTEN 0      4096               *:2020             *:*    users:(("x-ui",pid=670103,fd=9))                           
tcp   LISTEN 0      1024           [::1]:8388          [::]:*    users:(("ss-server",pid=1087,fd=5))                        
tcp   LISTEN 0      4096            [::]:9443          [::]:*    users:(("docker-proxy",pid=1021452,fd=7))                  
tcp   LISTEN 0      4096               *:443              *:*    users:(("xray-linux-amd6",pid=712801,fd=15))               
tcp   LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=567295,fd=6),("nginx",pid=567221,fd=6))
```

## Systemd services of interest
| Service | Active | Enabled | Unit file present |
|---|---:|---:|---:|
| `xray` | inactive | not-found | no |
| `x-ui` | active | enabled | yes |
| `3x-ui` | inactive | not-found | no |
| `nginx` | active | enabled | yes |
| `apache2` | inactive | not-found | no |
| `postfix` | active | enabled | yes |
| `dovecot` | inactive | not-found | no |
| `fail2ban` | active | enabled | yes |
| `openvpn` | active | enabled | yes |
| `wg-quick@wg-home` | active | enabled | yes |
| `matrix-synapse` | inactive | not-found | no |
| `coturn` | inactive | not-found | no |
| `hometele-command-agent` | active | enabled | yes |
| `hometele-ai` | inactive | not-found | no |
| `docker` | active | enabled | yes |
| `cron` | active | enabled | yes |
| `crond` | inactive | not-found | no |
| `ssh` | active | disabled | yes |
| `sshd` | inactive | not-found | no |

## Package versions of interest
```text
apache2	
docker.io	29.1.3-0ubuntu3~24.04.2
fail2ban	1.0.2-3ubuntu0.1
git	1:2.43.0-1ubuntu7.3
iptables	1.8.10-3ubuntu2
nftables	1.0.9-1ubuntu0.1
nginx	1.24.0-2ubuntu7.13
openvpn	2.6.19-0ubuntu0.24.04.2
postfix	3.8.6-1ubuntu0.1
python3	3.12.3-0ubuntu2.1
ufw	0.36.2-6
wireguard	1.0.20210914-1ubuntu4
wireguard-tools	1.0.20210914-1ubuntu4
```

## Firewall summary
```text
Status: active
Logging: on (medium)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
443/tcp                    ALLOW IN    Anywhere                   # Xray VLESS Reality TCP
46539/udp                  ALLOW IN    Anywhere                   # Hysteria2 UDP
39425/udp                  ALLOW IN    Anywhere                   # Docker UDP service detected
80/tcp                     ALLOW IN    Anywhere                   # HTTP ACME and redirect
1194/udp                   ALLOW IN    Anywhere                   # OpenVPN home UDP
8443/tcp                   ALLOW IN    Anywhere                   # OpenVPN home TCP
21194/udp                  ALLOW IN    Anywhere                   # OpenVPN RU bridge UDP
Anywhere on tun79          ALLOW IN    Anywhere                  
33328/udp                  ALLOW IN    Anywhere                   # Xray UDP inbound
52000/tcp                  ALLOW IN    Anywhere                   # TEMP SSH rescue allow
51820/udp                  ALLOW IN    Anywhere                   # WireGuard Hometele Port2
25/tcp                     ALLOW IN    Anywhere                  
9443/tcp                   ALLOW IN    Anywhere                   # Telegram MTProto Proxy
443/tcp (v6)               ALLOW IN    Anywhere (v6)              # Xray VLESS Reality TCP
46539/udp (v6)             ALLOW IN    Anywhere (v6)              # Hysteria2 UDP
39425/udp (v6)             ALLOW IN    Anywhere (v6)              # Docker UDP service detected
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP ACME and redirect
1194/udp (v6)              ALLOW IN    Anywhere (v6)              # OpenVPN home UDP
8443/tcp (v6)              ALLOW IN    Anywhere (v6)              # OpenVPN home TCP
21194/udp (v6)             ALLOW IN    Anywhere (v6)              # OpenVPN RU bridge UDP
Anywhere (v6) on tun79     ALLOW IN    Anywhere (v6)             
33328/udp (v6)             ALLOW IN    Anywhere (v6)              # Xray UDP inbound
52000/tcp (v6)             ALLOW IN    Anywhere (v6)              # TEMP SSH rescue allow
51820/udp (v6)             ALLOW IN    Anywhere (v6)              # WireGuard Hometele Port2
25/tcp (v6)                ALLOW IN    Anywhere (v6)             
9443/tcp (v6)              ALLOW IN    Anywhere (v6)              # Telegram MTProto Proxy

Anywhere                   ALLOW OUT   Anywhere on tun79         
Anywhere (v6)              ALLOW OUT   Anywhere (v6) on tun79    

Anywhere on eth0           ALLOW FWD   Anywhere on amn0           # Amnezia forwarding
Anywhere on amn0           ALLOW FWD   Anywhere on eth0           # Amnezia return forwarding
Anywhere on eth0           ALLOW FWD   Anywhere on wg0            # Amnezia forwarding
Anywhere on wg0            ALLOW FWD   Anywhere on eth0           # Amnezia return forwarding
Anywhere on eth0           ALLOW FWD   Anywhere on tun-home-udp   # OpenVPN Home UDP route
Anywhere on eth0           ALLOW FWD   Anywhere on tun-home-tcp   # OpenVPN Home TCP route
Anywhere on eth0           ALLOW FWD   Anywhere on tun77         
Anywhere on tun77          ALLOW FWD   Anywhere on eth0          
Anywhere on eth0           ALLOW FWD   Anywhere on tun79         
Anywhere on tun79          ALLOW FWD   Anywhere on eth0          
Anywhere (v6) on eth0      ALLOW FWD   Anywhere (v6) on amn0      # Amnezia forwarding
Anywhere (v6) on amn0      ALLOW FWD   Anywhere (v6) on eth0      # Amnezia return forwarding
Anywhere (v6) on eth0      ALLOW FWD   Anywhere (v6) on wg0       # Amnezia forwarding
Anywhere (v6) on wg0       ALLOW FWD   Anywhere (v6) on eth0      # Amnezia return forwarding
Anywhere (v6) on eth0      ALLOW FWD   Anywhere (v6) on tun-home-udp # OpenVPN Home UDP route
Anywhere (v6) on eth0      ALLOW FWD   Anywhere (v6) on tun-home-tcp # OpenVPN Home TCP route
Anywhere (v6) on eth0      ALLOW FWD   Anywhere (v6) on tun77    
Anywhere (v6) on tun77     ALLOW FWD   Anywhere (v6) on eth0     
Anywhere (v6) on eth0      ALLOW FWD   Anywhere (v6) on tun79    
Anywhere (v6) on tun79     ALLOW FWD   Anywhere (v6) on eth0     


-P INPUT DROP
-P FORWARD DROP
-P OUTPUT ACCEPT
-N DOCKER
-N DOCKER-BRIDGE
-N DOCKER-CT
-N DOCKER-FORWARD
-N DOCKER-INTERNAL
-N DOCKER-USER
-N f2b-ufw-portscan
-N ufw-after-forward
-N ufw-after-input
-N ufw-after-logging-forward
-N ufw-after-logging-input
-N ufw-after-logging-output
-N ufw-after-output
-N ufw-before-forward
-N ufw-before-input
-N ufw-before-logging-forward
-N ufw-before-logging-input
-N ufw-before-logging-output
-N ufw-before-output
-N ufw-logging-allow
-N ufw-logging-deny
-N ufw-not-local
-N ufw-reject-forward
-N ufw-reject-input
-N ufw-reject-output
-N ufw-skip-to-policy-forward
-N ufw-skip-to-policy-input
-N ufw-skip-to-policy-output
-N ufw-track-forward
-N ufw-track-input
-N ufw-track-output
-N ufw-user-forward
-N ufw-user-input
-N ufw-user-limit
-N ufw-user-limit-accept
-N ufw-user-logging-forward
-N ufw-user-logging-input
-N ufw-user-logging-output
-N ufw-user-output
-A INPUT -p tcp -j f2b-ufw-portscan
-A INPUT -i tun79 -j ACCEPT
-A INPUT -j ufw-before-logging-input
-A INPUT -j ufw-before-input
-A INPUT -j ufw-after-input
-A INPUT -j ufw-after-logging-input
-A INPUT -j ufw-reject-input
-A INPUT -j ufw-track-input
-A FORWARD -d 10.79.0.0/24 -i eth0 -o tun79 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 10.79.0.0/24 -i tun79 -o eth0 -j ACCEPT
-A FORWARD -d 10.77.0.0/24 -i eth0 -o tun77 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 10.77.0.0/24 -i tun77 -o eth0 -j ACCEPT
-A FORWARD -j DOCKER-USER
-A FORWARD -j DOCKER-FORWARD
-A FORWARD -j ufw-before-logging-forward
-A FORWARD -j ufw-before-forward
-A FORWARD -j ufw-after-forward
-A FORWARD -j ufw-after-logging-forward
-A FORWARD -j ufw-reject-forward
-A FORWARD -j ufw-track-forward
-A FORWARD -s 10.77.0.0/24 -i tun-home-udp -o eth0 -j ACCEPT
-A FORWARD -d 10.77.0.0/24 -i eth0 -o tun-home-udp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 10.78.0.0/24 -i tun-home-tcp -o eth0 -j ACCEPT
-A FORWARD -d 10.78.0.0/24 -i eth0 -o tun-home-tcp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i wg-home -j ACCEPT
-A FORWARD -o wg-home -j ACCEPT
-A OUTPUT -o tun79 -j ACCEPT
-A OUTPUT -j ufw-before-logging-output
-A OUTPUT -j ufw-before-output
-A OUTPUT -j ufw-after-output
-A OUTPUT -j ufw-after-logging-output
-A OUTPUT -j ufw-reject-output
-A OUTPUT -j ufw-track-output
-A DOCKER -d 172.17.0.3/32 ! -i docker0 -o docker0 -p tcp -m tcp --dport 443 -j ACCEPT
-A DOCKER -d 172.29.172.2/32 ! -i amn0 -o amn0 -p udp -m udp --dport 39425 -j ACCEPT
-A DOCKER ! -i br-566ebeb0f4f1 -o br-566ebeb0f4f1 -j DROP
-A DOCKER ! -i amn0 -o amn0 -j DROP
-A DOCKER ! -i docker0 -o docker0 -j DROP
-A DOCKER-BRIDGE -o br-566ebeb0f4f1 -j DOCKER
-A DOCKER-BRIDGE -o amn0 -j DOCKER
-A DOCKER-BRIDGE -o docker0 -j DOCKER
-A DOCKER-CT -o br-566ebeb0f4f1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o amn0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-FORWARD -j DOCKER-CT
-A DOCKER-FORWARD -j DOCKER-INTERNAL
-A DOCKER-FORWARD -j DOCKER-BRIDGE
-A DOCKER-FORWARD -i br-566ebeb0f4f1 -j ACCEPT
-A DOCKER-FORWARD -i amn0 -j ACCEPT
-A DOCKER-FORWARD -i docker0 -j ACCEPT
-A f2b-ufw-portscan -s 2.17.97.196/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 78.156.232.237/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 176.119.169.241/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 34.104.35.123/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 178.217.160.94/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 178.130.128.39/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 31.13.84.51/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 157.240.253.175/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 195.178.30.195/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 31.13.84.2/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 157.240.30.175/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 157.240.253.17/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 44.192.201.214/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 176.112.173.133/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 13.39.201.21/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 216.239.32.223/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 31.13.84.8/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 216.180.246.12/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 104.83.5.160/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 152.32.178.38/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 185.253.40.251/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 150.171.28.10/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 185.253.40.196/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 91.78.43.7/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 176.100.185.61/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 188.128.76.31/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 2.16.16.169/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 172.16.0.1/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.5/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.3/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.8/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.7/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.6/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.4/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.1/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 205.166.28.6/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -j RETURN
-A ufw-after-input -p udp -m udp --dport 137 -j ufw-skip-to-policy-input
-A ufw-after-input -p udp -m udp --dport 138 -j ufw-skip-to-policy-input
-A ufw-after-input -p tcp -m tcp --dport 139 -j ufw-skip-to-policy-input
-A ufw-after-input -p tcp -m tcp --dport 445 -j ufw-skip-to-policy-input
-A ufw-after-input -p udp -m udp --dport 67 -j ufw-skip-to-policy-input
-A ufw-after-input -p udp -m udp --dport 68 -j ufw-skip-to-policy-input
-A ufw-after-input -m addrtype --dst-type BROADCAST -j ufw-skip-to-policy-input
-A ufw-after-logging-forward -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW BLOCK] "
-A ufw-after-logging-input -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW BLOCK] "
-A ufw-after-logging-output -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW ALLOW] "
-A ufw-before-forward -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-forward -p icmp -m icmp --icmp-type 3 -j ACCEPT
-A ufw-before-forward -p icmp -m icmp --icmp-type 11 -j ACCEPT
-A ufw-before-forward -p icmp -m icmp --icmp-type 12 -j ACCEPT
-A ufw-before-forward -p icmp -m icmp --icmp-type 8 -j ACCEPT
-A ufw-before-forward -j ufw-user-forward
-A ufw-before-input -i lo -j ACCEPT
-A ufw-before-input -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-input -m conntrack --ctstate INVALID -j ufw-logging-deny
-A ufw-before-input -m conntrack --ctstate INVALID -j DROP
-A ufw-before-input -p icmp -m icmp --icmp-type 3 -j ACCEPT
-A ufw-before-input -p icmp -m icmp --icmp-type 11 -j ACCEPT
-A ufw-before-input -p icmp -m icmp --icmp-type 12 -j ACCEPT
-A ufw-before-input -p icmp -m icmp --icmp-type 8 -j ACCEPT
-A ufw-before-input -p udp -m udp --sport 67 --dport 68 -j ACCEPT
-A ufw-before-input -j ufw-not-local
-A ufw-before-input -d 224.0.0.251/32 -p udp -m udp --dport 5353 -j ACCEPT
-A ufw-before-input -d 239.255.255.250/32 -p udp -m udp --dport 1900 -j ACCEPT
-A ufw-before-input -j ufw-user-input
-A ufw-before-logging-forward -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW AUDIT] "
-A ufw-before-logging-input -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW AUDIT] "
-A ufw-before-logging-output -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW AUDIT] "
-A ufw-before-output -o lo -j ACCEPT
-A ufw-before-output -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-output -j ufw-user-output
-A ufw-logging-allow -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW ALLOW] "
-A ufw-logging-deny -m conntrack --ctstate INVALID -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW AUDIT INVALID] "
-A ufw-logging-deny -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW BLOCK] "
-A ufw-not-local -m addrtype --dst-type LOCAL -j RETURN
-A ufw-not-local -m addrtype --dst-type MULTICAST -j RETURN
-A ufw-not-local -m addrtype --dst-type BROADCAST -j RETURN
-A ufw-not-local -m limit --limit 3/min --limit-burst 10 -j ufw-logging-deny
-A ufw-not-local -j DROP
-A ufw-skip-to-policy-forward -j DROP
-A ufw-skip-to-policy-input -j DROP
-A ufw-skip-to-policy-output -j ACCEPT
-A ufw-track-output -p tcp -m conntrack --ctstate NEW -j ACCEPT
-A ufw-track-output -p udp -m conntrack --ctstate NEW -j ACCEPT
-A ufw-user-forward -i amn0 -o eth0 -j ACCEPT
-A ufw-user-forward -i eth0 -o amn0 -j ACCEPT
-A ufw-user-forward -i wg0 -o eth0 -j ACCEPT
-A ufw-user-forward -i eth0 -o wg0 -j ACCEPT
-A ufw-user-forward -i tun-home-udp -o eth0 -j ACCEPT
-A ufw-user-forward -i tun-home-tcp -o eth0 -j ACCEPT
-A ufw-user-forward -i tun77 -o eth0 -j ACCEPT
-A ufw-user-forward -i eth0 -o tun77 -j ACCEPT
-A ufw-user-forward -i tun79 -o eth0 -j ACCEPT
-A ufw-user-forward -i eth0 -o tun79 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 443 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 46539 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 39425 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 80 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 1194 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 8443 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 21194 -j ACCEPT
-A ufw-user-input -i tun79 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 33328 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 52000 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 51820 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 25 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 9443 -j ACCEPT

table ip filter {
	chain ufw-before-logging-input {
		ct state new limit rate 3/minute burst 10 packets counter packets 23783 bytes 5868638 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-output {
		ct state new limit rate 3/minute burst 10 packets counter packets 23783 bytes 1684853 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-forward {
		ct state new limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-input {
		iifname "lo" counter packets 6615706 bytes 3962437636 accept
		ct state related,established counter packets 156402821 bytes 131390223605 accept
		ct state invalid counter packets 5711 bytes 374890 jump ufw-logging-deny
		ct state invalid counter packets 5711 bytes 374890 drop
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 12001 bytes 695562 accept
		udp sport 67 udp dport 68 counter packets 0 bytes 0 accept
		counter packets 1242525 bytes 277828803 jump ufw-not-local
		ip daddr 224.0.0.251 udp dport 5353 counter packets 0 bytes 0 accept
		ip daddr 239.255.255.250 udp dport 1900 counter packets 0 bytes 0 accept
		counter packets 1242525 bytes 277828803 jump ufw-user-input
	}

	chain ufw-before-output {
		oifname "lo" counter packets 6615710 bytes 3962437852 accept
		ct state related,established counter packets 165482742 bytes 192467001446 accept
		counter packets 1334541 bytes 184597360 jump ufw-user-output
	}

	chain ufw-before-forward {
		ct state related,established counter packets 0 bytes 0 accept
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 0 bytes 0 accept
		counter packets 193 bytes 10338 jump ufw-user-forward
	}

	chain ufw-after-input {
		udp dport 137 counter packets 131 bytes 11784 jump ufw-skip-to-policy-input
		udp dport 138 counter packets 0 bytes 0 jump ufw-skip-to-policy-input
		tcp dport 139 counter packets 74 bytes 3908 jump ufw-skip-to-policy-input
		tcp dport 445 counter packets 416 bytes 21156 jump ufw-skip-to-policy-input
		udp dport 67 counter packets 458293 bytes 150320750 jump ufw-skip-to-policy-input
		udp dport 68 counter packets 0 bytes 0 jump ufw-skip-to-policy-input
		fib daddr type broadcast counter packets 76585 bytes 23309243 jump ufw-skip-to-policy-input
	}

	chain ufw-after-output {
	}

	chain ufw-after-forward {
	}

	chain ufw-after-logging-input {
		limit rate 3/minute burst 10 packets counter packets 23783 bytes 1527191 log prefix "[UFW BLOCK] "
	}

	chain ufw-after-logging-output {
		limit rate 3/minute burst 10 packets counter packets 23410 bytes 1955728 log prefix "[UFW ALLOW] "
	}

	chain ufw-after-logging-forward {
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW BLOCK] "
	}

	chain ufw-reject-input {
	}

	chain ufw-reject-output {
	}

	chain ufw-reject-forward {
	}

	chain ufw-track-input {
	}

	chain ufw-track-output {
		ip protocol tcp ct state new counter packets 170503 bytes 11635696 accept
		ip protocol udp ct state new counter packets 1154027 bytes 171981051 accept
	}

	chain ufw-track-forward {
	}

	chain INPUT {
		type filter hook input priority filter; policy drop;
		ip protocol tcp counter packets 45002528 bytes 43956201643 jump f2b-ufw-portscan
		iifname "tun79" counter packets 364458 bytes 453692604 accept
		counter packets 538354239 bytes 502070542099 jump ufw-before-logging-input
		counter packets 538354239 bytes 502070542099 jump ufw-before-input
		counter packets 4808538 bytes 926170907 jump ufw-after-input
		counter packets 2351771 bytes 130144746 jump ufw-after-logging-input
		counter packets 2351771 bytes 130144746 jump ufw-reject-input
		counter packets 2351771 bytes 130144746 jump ufw-track-input
	}

	chain OUTPUT {
		type filter hook output priority filter; policy accept;
		oifname "tun79" counter packets 10489 bytes 2001646 accept
		counter packets 491589743 bytes 475121963442 jump ufw-before-logging-output
		counter packets 491589743 bytes 475121963442 jump ufw-before-output
		counter packets 4838240 bytes 688124438 jump ufw-after-output
		counter packets 4838240 bytes 688124438 jump ufw-after-logging-output
		counter packets 4838240 bytes 688124438 jump ufw-reject-output
		counter packets 4838240 bytes 688124438 jump ufw-track-output
	}

	chain FORWARD {
		type filter hook forward priority filter; policy drop;
		ip daddr 10.79.0.0/24 iifname "eth0" oifname "tun79" ct state related,established counter packets 51863424 bytes 127781404716 accept
		ip saddr 10.79.0.0/24 iifname "tun79" oifname "eth0" counter packets 62256789 bytes 11488281058 accept
		ip daddr 10.77.0.0/24 iifname "eth0" oifname "tun77" ct state related,established counter packets 0 bytes 0 accept
		ip saddr 10.77.0.0/24 iifname "tun77" oifname "eth0" counter packets 0 bytes 0 accept
		counter packets 258492872 bytes 298044445853 jump DOCKER-USER
		counter packets 258492872 bytes 298044445853 jump DOCKER-FORWARD
		counter packets 417 bytes 24398 jump ufw-before-logging-forward
		counter packets 417 bytes 24398 jump ufw-before-forward
		counter packets 0 bytes 0 jump ufw-after-forward
		counter packets 0 bytes 0 jump ufw-after-logging-forward
		counter packets 0 bytes 0 jump ufw-reject-forward
		counter packets 0 bytes 0 jump ufw-track-forward
		ip saddr 10.77.0.0/24 iifname "tun-home-udp" oifname "eth0" counter packets 0 bytes 0 accept
		ip daddr 10.77.0.0/24 iifname "eth0" oifname "tun-home-udp" ct state related,established counter packets 0 bytes 0 accept
		ip saddr 10.78.0.0/24 iifname "tun-home-tcp" oifname "eth0" counter packets 0 bytes 0 accept
		ip daddr 10.78.0.0/24 iifname "eth0" oifname "tun-home-tcp" ct state related,established counter packets 0 bytes 0 accept
		iifname "wg-home" counter packets 0 bytes 0 accept
		oifname "wg-home" counter packets 0 bytes 0 accept
	}

	chain DOCKER {
		ip daddr 172.17.0.3 iifname != "docker0" oifname "docker0" tcp dport 443 counter packets 3048 bytes 188880 accept
		ip daddr 172.29.172.2 iifname != "amn0" oifname "amn0" udp dport 39425 counter packets 23436 bytes 3626480 accept
		iifname != "br-566ebeb0f4f1" oifname "br-566ebeb0f4f1" counter packets 0 bytes 0 drop
		iifname != "amn0" oifname "amn0" counter packets 0 bytes 0 drop
		iifname != "docker0" oifname "docker0" counter packets 0 bytes 0 drop
	}

	chain DOCKER-FORWARD {
		counter packets 258492872 bytes 298044445853 jump DOCKER-CT
		counter packets 129543669 bytes 151332522819 jump DOCKER-INTERNAL
		counter packets 129543669 bytes 151332522819 jump DOCKER-BRIDGE
		iifname "br-566ebeb0f4f1" counter packets 0 bytes 0 accept
		iifname "amn0" counter packets 128029797 bytes 150955992146 accept
		iifname "docker0" counter packets 1486971 bytes 372690915 accept
	}

	chain DOCKER-BRIDGE {
		oifname "br-566ebeb0f4f1" counter packets 0 bytes 0 jump DOCKER
		oifname "amn0" counter packets 23436 bytes 3626480 jump DOCKER
		oifname "docker0" counter packets 3048 bytes 188880 jump DOCKER
	}

	chain DOCKER-CT {
		oifname "br-566ebeb0f4f1" ct state related,established counter packets 0 bytes 0 accept
		oifname "amn0" ct state related,established counter packets 127797225 bytes 146313724534 accept
		oifname "docker0" ct state related,established counter packets 1151978 bytes 398198500 accept
	}

	chain DOCKER-INTERNAL {
	}

	chain DOCKER-USER {
	}

	chain ufw-logging-deny {
		ct state invalid limit rate 3/minute burst 10 packets counter packets 4938 bytes 328968 log prefix "[UFW AUDIT INVALID] "
		limit rate 3/minute burst 10 packets counter packets 4938 bytes 328968 log prefix "[UFW BLOCK] "
	}

	chain ufw-logging-allow {
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW ALLOW] "
	}

	chain ufw-skip-to-policy-input {
		counter packets 535499 bytes 173666841 drop
	}

	chain ufw-skip-to-policy-output {
		counter packets 0 bytes 0 accept
	}

	chain ufw-skip-to-policy-forward {
		counter packets 0 bytes 0 drop
	}

	chain ufw-not-local {
		fib daddr type local counter packets 707560 bytes 104190458 return
		fib daddr type multicast counter packets 0 bytes 0 return
		fib daddr type broadcast counter packets 534965 bytes 173638345 return
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 jump ufw-logging-deny
		counter packets 0 bytes 0 drop
	}

	chain ufw-user-input {
		tcp dport 443 counter packets 151028 bytes 9504124 accept
		udp dport 46539 counter packets 43789 bytes 50552007 accept
		udp dport 39425 counter packets 75 bytes 7699 accept
		tcp dport 80 counter packets 56290 bytes 3361145 accept
		udp dport 1194 counter packets 34 bytes 1365 accept
		tcp dport 8443 counter packets 2276 bytes 130194 accept
		udp dport 21194 counter packets 6 bytes 872 accept
		iifname "tun79" counter packets 0 bytes 0 accept
		udp dport 33328 counter packets 0 bytes 0 accept
		tcp dport 52000 counter packets 105 bytes 5752 accept
		udp dport 51820 counter packets 0 bytes 0 accept
		tcp dport 25 counter packets 1144 bytes 66444 accept
		tcp dport 9443 counter packets 0 bytes 0 accept
	}

	chain ufw-user-output {
		oifname "tun79" counter packets 0 bytes 0 accept
	}
```

## WireGuard summary: no keys
```text
interface: wg-home
  listen_port: 51820
  peer_count: 2

```

## Fail2Ban summary
```text
Status
|- Number of jail:	4
`- Jail list:	3x-ipl, recidive, sshd, ufw-portscan

jail: 3x-ipl
|  |- Currently failed:	0
|  |- Total failed:	0
   |- Currently banned:	0
   |- Total banned:	0

jail: recidive
|  |- Currently failed:	0
|  |- Total failed:	0
   |- Currently banned:	0
   |- Total banned:	0

jail: sshd
|  |- Currently failed:	0
|  |- Total failed:	0
   |- Currently banned:	0
   |- Total banned:	0

jail: ufw-portscan
|  |- Currently failed:	32
|  |- Total failed:	34888
   |- Currently banned:	38
   |- Total banned:	206
```

## Docker containers
```text
NAMES                        IMAGE                            STATUS       PORTS
mtproto-telegram             telegrammessenger/proxy:latest   Up 9 hours   0.0.0.0:9443->443/tcp, [::]:9443->443/tcp
amnezia-awg2                 amnezia-awg2                     Up 4 weeks   0.0.0.0:39425->39425/udp, [::]:39425->39425/udp
signal-tls-proxy-certbot-1   certbot/certbot                  Up 4 weeks   80/tcp, 443/tcp
```

## Xray config summary: sanitized
```text
No readable Xray config found in known paths.
```

## Nginx summary: listen/server_name only
```text
nginx version: nginx/1.24.0 (Ubuntu)

 listen [::]:80 default_server;
 listen 80 default_server;
 server_name _;
```

## Postfix summary: selected safe settings only
```text
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, localhost.$mydomain, localhost, hometele.com.ru, www.hometele.com.ru
mydomain = hometele.com.ru
myhostname = mail.hometele.com.ru
myorigin = hometele.com.ru
relayhost =
smtp_tls_security_level = may
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file = [REDACTED-PATH]
smtpd_tls_security_level = may
```

## Important paths: presence only
| Path | Type | Owner | Mode | Size | Modified |
|---|---:|---:|---:|---:|---:|
| `/usr/local/etc/xray/config.json` | missing | - | - | - | - |
| `/etc/xray/config.json` | missing | - | - | - | - |
| `/etc/nginx` | directory | root:root | 755 | 4096 | 2026-06-24 14:13:44 |
| `/etc/fail2ban` | directory | root:root | 755 | 4096 | 2026-06-26 20:11:48 |
| `/etc/postfix` | directory | root:root | 755 | 4096 | 2026-06-29 15:34:38 |
| `/etc/dovecot` | missing | - | - | - | - |
| `/etc/cron.d/server-maintenance` | regular file | root:root | 644 | 434 | 2026-07-04 12:46:05 |
| `/opt/server-maintenance` | directory | root:root | 755 | 4096 | 2026-07-04 12:46:05 |
| `/usr/local/sbin/hometele-vpn-user` | missing | - | - | - | - |
| `/usr/local/sbin/hometele-vpn-ssh-wrapper` | missing | - | - | - | - |
| `/usr/local/sbin/www-hometele-vpn` | missing | - | - | - | - |
| `/usr/local/bin/hometele-command-agent.py` | regular file | root:root | 755 | 7535 | 2026-07-02 19:28:01 |
| `/etc/hometele-monitor/command-agent.conf` | regular file | root:root | 600 | 293 | 2026-07-02 19:20:29 |
| `/var/lib/hometele-monitor/command-agent.since` | regular file | root:root | 644 | 41 | 2026-07-04 21:07:04 |
| `/etc/systemd/system/hometele-command-agent.service` | regular file | root:root | 644 | 263 | 2026-07-02 19:20:29 |
| `/etc/systemd/system/hometele-ai.service` | missing | - | - | - | - |
| `/root/.ssh` | directory | root:root | 700 | 4096 | 2025-09-15 08:03:54 |
| `/etc/letsencrypt` | directory | root:root | 755 | 4096 | 2026-06-30 10:11:18 |
| `/root/cert` | directory | root:root | 755 | 4096 | 2025-03-17 14:20:58 |
| `/etc/x-ui` | directory | root:root | 755 | 4096 | 2026-07-04 21:07:22 |
| `/etc/3x-ui` | missing | - | - | - | - |

## SSH keys: fingerprints only
```text
/root/.ssh/authorized_keys -> not a public/private SSH key or unreadable
```

## Maintenance cron
```text
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Каждый день в 03:00 — перезапуск Docker-контейнеров и выбранных сервисов
0 3 * * * root /opt/server-maintenance/restart-containers-and-services.sh

# Каждое воскресенье в 03:30 — обновление системы
30 3 * * 0 root /opt/server-maintenance/weekly-apt-upgrade.sh

total 16K
drwxr-xr-x 2 root root 4.0K Jul  4 12:46 .
drwxr-xr-x 7 root root 4.0K Jul  4 20:02 ..
-rwxr-xr-x 1 root root 2.4K Jul  4 12:46 restart-containers-and-services.sh
-rwxr-xr-x 1 root root 1.4K Jul  4 12:46 weekly-apt-upgrade.sh

total 8.0K
drwxr-xr-x  2 root root   4.0K Jul  4 12:46 .
drwxr-xr-x 18 root syslog 4.0K Jul  4 21:00 ..
```

## Reboot required marker
```text
reboot_required: no
```
