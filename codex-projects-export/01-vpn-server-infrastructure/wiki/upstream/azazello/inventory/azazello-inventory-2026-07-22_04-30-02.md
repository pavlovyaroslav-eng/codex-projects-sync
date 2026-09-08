# Inventory snapshot: azazello

Generated: 2026-07-22T04:30:02+03:00  
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
    Firmware Age: 6y 1month 1w 2d

Linux azazello 6.8.0-107-generic #107-Ubuntu SMP PREEMPT_DYNAMIC Fri Mar 13 19:51:50 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux

 04:30:02 up 45 days, 14:09,  0 user,  load average: 2.13, 1.88, 1.06
```

## Network addresses
```text
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             91.242.163.206/24 2a00:fd40:c:3091::1/64 fe80::216:3eff:feab:5be3/64 
br-566ebeb0f4f1  UP             172.18.0.1/16 fe80::46f:8eff:fe1f:36e/64 
amn0             UP             172.29.172.1/24 fe80::50b7:4cff:fe73:3280/64 
docker0          UP             172.17.0.1/16 fe80::1005:7aff:fe69:2e83/64 
tun-home-udp     UNKNOWN        10.77.0.1/24 fe80::2907:9504:1c80:31bc/64 
tun-home-tcp     UNKNOWN        10.78.0.1/24 fe80::1aa:a170:1f66:4b6e/64 
tun79            UNKNOWN        10.79.0.1 peer 10.79.0.2/32 fe80::e3c9:7743:df7b:4dd/64 
wg0              UNKNOWN        172.16.0.2/32 2606:4700:110:8522:d608:2fba:6dba:94bf/128 fe80::2b7b:1d5a:2d81:2ec8/64 
veth409b546@if2  UP             fe80::82d:37ff:fef8:1419/64 
veth8d3c1ca@if2  UP             fe80::d446:9dff:fe2d:83d0/64 
vethfa84b5a@if3  UP             fe80::5c34:1fff:feb6:903c/64 
veth75c026c@if2  UP             fe80::6863:24ff:fe86:80f2/64 
wg-home          UNKNOWN        10.77.77.1/24 
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
fe80::/64 dev br-566ebeb0f4f1 proto kernel metric 256 pref medium
fe80::/64 dev amn0 proto kernel metric 256 pref medium
fe80::/64 dev docker0 proto kernel metric 256 pref medium
fe80::/64 dev tun-home-udp proto kernel metric 256 pref medium
fe80::/64 dev tun-home-tcp proto kernel metric 256 pref medium
fe80::/64 dev tun79 proto kernel metric 256 pref medium
fe80::/64 dev veth409b546 proto kernel metric 256 pref medium
fe80::/64 dev veth8d3c1ca proto kernel metric 256 pref medium
fe80::/64 dev vethfa84b5a proto kernel metric 256 pref medium
fe80::/64 dev veth75c026c proto kernel metric 256 pref medium
fe80::/64 dev wg0 proto kernel metric 256 pref medium
default via 2a00:fd40:c:3000::1 dev eth0 metric 1024 onlink pref medium
```

## Listening ports
```text
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess                                                       
udp   UNCONN 0      0            0.0.0.0:1194       0.0.0.0:*    users:(("openvpn",pid=584119,fd=5))                          
udp   UNCONN 0      0          127.0.0.1:5353       0.0.0.0:*    users:(("unbound",pid=1521352,fd=3))                         
udp   UNCONN 0      0         127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=16))                 
udp   UNCONN 0      0      127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=14))                 
udp   UNCONN 0      0          127.0.0.1:8388       0.0.0.0:*    users:(("ss-server",pid=1087,fd=8))                          
udp   UNCONN 0      0            0.0.0.0:39425      0.0.0.0:*    users:(("docker-proxy",pid=1818375,fd=7))                    
udp   UNCONN 0      0            0.0.0.0:51820      0.0.0.0:*                                                                 
udp   UNCONN 0      0            0.0.0.0:21194      0.0.0.0:*    users:(("openvpn",pid=709029,fd=5))                          
udp   UNCONN 0      0                  *:46539            *:*    users:(("xray-linux-amd6",pid=1869404,fd=16))                
udp   UNCONN 0      0                  *:36995            *:*    users:(("xray-linux-amd6",pid=1869404,fd=18))                
udp   UNCONN 0      0              [::1]:8388          [::]:*    users:(("ss-server",pid=1087,fd=7))                          
udp   UNCONN 0      0               [::]:39425         [::]:*    users:(("docker-proxy",pid=1818380,fd=7))                    
udp   UNCONN 0      0               [::]:51820         [::]:*                                                                 
tcp   LISTEN 0      256        127.0.0.1:5353       0.0.0.0:*    users:(("unbound",pid=1521352,fd=4))                         
tcp   LISTEN 0      4096         0.0.0.0:9443       0.0.0.0:*    users:(("docker-proxy",pid=1818073,fd=7))                    
tcp   LISTEN 0      4096       127.0.0.1:62789      0.0.0.0:*    users:(("xray-linux-amd6",pid=1869404,fd=14))                
tcp   LISTEN 0      4096       127.0.0.1:46341      0.0.0.0:*    users:(("containerd",pid=928209,fd=21))                      
tcp   LISTEN 0      4096         0.0.0.0:52000      0.0.0.0:*    users:(("sshd",pid=1869554,fd=3),("systemd",pid=1,fd=165))   
tcp   LISTEN 0      4096       127.0.0.1:11111      0.0.0.0:*    users:(("xray-linux-amd6",pid=1869404,fd=23))                
tcp   LISTEN 0      1024       127.0.0.1:8388       0.0.0.0:*    users:(("ss-server",pid=1087,fd=6))                          
tcp   LISTEN 0      4096      127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=17))                 
tcp   LISTEN 0      32           0.0.0.0:8443       0.0.0.0:*    users:(("openvpn",pid=584123,fd=5))                          
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=1818637,fd=5),("nginx",pid=1818636,fd=5))
tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=127066,fd=15))                 
tcp   LISTEN 0      100          0.0.0.0:25         0.0.0.0:*    users:(("master",pid=1818974,fd=13))                         
tcp   LISTEN 0      4096               *:2020             *:*    users:(("x-ui",pid=1869397,fd=9))                            
tcp   LISTEN 0      1024           [::1]:8388          [::]:*    users:(("ss-server",pid=1087,fd=5))                          
tcp   LISTEN 0      4096            [::]:9443          [::]:*    users:(("docker-proxy",pid=1818082,fd=7))                    
tcp   LISTEN 0      4096               *:443              *:*    users:(("xray-linux-amd6",pid=1869404,fd=15))                
tcp   LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=1818637,fd=6),("nginx",pid=1818636,fd=6))
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
openvpn	2.6.19-0ubuntu0.24.04.3
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
10.79.79.1 on wg79test     ALLOW IN    10.79.79.2                 # wg79test inner test
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
-A DOCKER -d 172.29.172.2/32 ! -i amn0 -o amn0 -p udp -m udp --dport 39425 -j ACCEPT
-A DOCKER -d 172.17.0.3/32 ! -i docker0 -o docker0 -p tcp -m tcp --dport 443 -j ACCEPT
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
-A f2b-ufw-portscan -s 172.217.119.4/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 173.194.187.6/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 46.228.223.46/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 119.28.179.176/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 157.240.253.61/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 199.103.24.2/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 192.155.88.231/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 142.250.203.130/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 95.163.61.56/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 31.13.84.51/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 142.251.140.66/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 172.104.210.105/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 172.217.114.4/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 46.228.223.44/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 85.217.140.40/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 34.117.147.68/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 34.102.162.219/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 157.240.253.13/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 104.83.5.208/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 104.83.4.48/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 176.119.169.20/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 146.75.122.13/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 146.75.118.13/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 85.217.140.41/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 17.248.213.70/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 87.240.129.140/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 1.1.1.1/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 87.240.139.193/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 15.237.234.254/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 57.144.248.3/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 193.17.93.194/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 95.163.58.192/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 93.186.225.194/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 146.75.118.73/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 178.130.128.39/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 104.243.42.83/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 44.192.202.6/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 176.109.184.170/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 44.192.202.120/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 176.112.173.133/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 10.8.1.3/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 142.250.203.142/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 192.178.25.174/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 176.112.173.132/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 90.156.232.26/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 52.0.252.143/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.3/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.1/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.7/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.4/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 209.38.59.6/32 -j REJECT --reject-with icmp-port-unreachable
-A f2b-ufw-portscan -s 160.119.76.119/32 -j REJECT --reject-with icmp-port-unreachable
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

table ip filter {
	chain ufw-before-logging-input {
		ct state new limit rate 3/minute burst 10 packets counter packets 16547 bytes 6582418 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-output {
		ct state new limit rate 3/minute burst 10 packets counter packets 16547 bytes 1044892 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-forward {
		ct state new limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-input {
		iifname "lo" counter packets 24722042 bytes 13198704006 accept
		ct state related,established counter packets 347976364 bytes 239311309759 accept
		ct state invalid counter packets 25515 bytes 2061567 jump ufw-logging-deny
		ct state invalid counter packets 25515 bytes 2061567 drop
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 46699 bytes 2691313 accept
		udp sport 67 udp dport 68 counter packets 0 bytes 0 accept
		counter packets 4178780 bytes 1384319490 jump ufw-not-local
		ip daddr 224.0.0.251 udp dport 5353 counter packets 0 bytes 0 accept
		ip daddr 239.255.255.250 udp dport 1900 counter packets 0 bytes 0 accept
		counter packets 4178780 bytes 1384319490 jump ufw-user-input
	}

	chain ufw-before-output {
		oifname "lo" counter packets 24722390 bytes 13198735240 accept
		ct state related,established counter packets 429183121 bytes 496293897693 accept
		counter packets 2258727 bytes 280577527 jump ufw-user-output
	}

	chain ufw-before-forward {
		ct state related,established counter packets 0 bytes 0 accept
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 0 bytes 0 accept
		counter packets 328 bytes 17550 jump ufw-user-forward
	}

	chain ufw-after-input {
		udp dport 137 counter packets 324 bytes 29690 jump ufw-skip-to-policy-input
		udp dport 138 counter packets 3 bytes 2383 jump ufw-skip-to-policy-input
		tcp dport 139 counter packets 267 bytes 13988 jump ufw-skip-to-policy-input
		tcp dport 445 counter packets 1628 bytes 82412 jump ufw-skip-to-policy-input
		udp dport 67 counter packets 1760883 bytes 577571668 jump ufw-skip-to-policy-input
		udp dport 68 counter packets 3 bytes 2384 jump ufw-skip-to-policy-input
		fib daddr type broadcast counter packets 295659 bytes 89557981 jump ufw-skip-to-policy-input
	}

	chain ufw-after-output {
	}

	chain ufw-after-forward {
	}

	chain ufw-after-logging-input {
		limit rate 3/minute burst 10 packets counter packets 16547 bytes 3279387 log prefix "[UFW BLOCK] "
	}

	chain ufw-after-logging-output {
		limit rate 3/minute burst 10 packets counter packets 16547 bytes 1157346 log prefix "[UFW ALLOW] "
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
		ip protocol tcp ct state new counter packets 380782 bytes 24359268 accept
		ip protocol udp ct state new counter packets 1834100 bytes 251944944 accept
	}

	chain ufw-track-forward {
	}

	chain INPUT {
		type filter hook input priority filter; policy drop;
		ip protocol tcp counter packets 11556844 bytes 10898370163 jump f2b-ufw-portscan
		iifname "tun79" counter packets 1090750 bytes 1359553160 accept
		counter packets 751024875 bytes 620338067738 jump ufw-before-logging-input
		counter packets 751024875 bytes 620338067738 jump ufw-before-input
		counter packets 7090825 bytes 1483721114 jump ufw-after-input
		counter packets 3110790 bytes 194101288 jump ufw-after-logging-input
		counter packets 3110790 bytes 194101288 jump ufw-reject-input
		counter packets 3110790 bytes 194101288 jump ufw-track-input
	}

	chain OUTPUT {
		type filter hook output priority filter; policy accept;
		oifname "tun79" counter packets 31413 bytes 6024246 accept
		counter packets 774320988 bytes 788281137244 jump ufw-before-logging-output
		counter packets 774320988 bytes 788281137244 jump ufw-before-output
		counter packets 5762426 bytes 784104605 jump ufw-after-output
		counter packets 5762426 bytes 784104605 jump ufw-after-logging-output
		counter packets 5762426 bytes 784104605 jump ufw-reject-output
		counter packets 5762426 bytes 784104605 jump ufw-track-output
	}

	chain FORWARD {
		type filter hook forward priority filter; policy drop;
		ip daddr 10.79.0.0/24 iifname "eth0" oifname "tun79" ct state related,established counter packets 156487311 bytes 368629052647 accept
		ip saddr 10.79.0.0/24 iifname "tun79" oifname "eth0" counter packets 187582542 bytes 41043705649 accept
		ip daddr 10.77.0.0/24 iifname "eth0" oifname "tun77" ct state related,established counter packets 0 bytes 0 accept
		ip saddr 10.77.0.0/24 iifname "tun77" oifname "eth0" counter packets 0 bytes 0 accept
		counter packets 649177349 bytes 693074931943 jump DOCKER-USER
		counter packets 649177349 bytes 693074931943 jump DOCKER-FORWARD
		counter packets 552 bytes 31610 jump ufw-before-logging-forward
		counter packets 552 bytes 31610 jump ufw-before-forward
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
		ip daddr 172.29.172.2 iifname != "amn0" oifname "amn0" udp dport 39425 counter packets 13963 bytes 2751962 accept
		ip daddr 172.17.0.3 iifname != "docker0" oifname "docker0" tcp dport 443 counter packets 30109 bytes 1817702 accept
		iifname != "br-566ebeb0f4f1" oifname "br-566ebeb0f4f1" counter packets 0 bytes 0 drop
		iifname != "amn0" oifname "amn0" counter packets 0 bytes 0 drop
		iifname != "docker0" oifname "docker0" counter packets 6 bytes 360 drop
	}

	chain DOCKER-FORWARD {
		counter packets 649177349 bytes 693074931943 jump DOCKER-CT
		counter packets 326009021 bytes 343411485217 jump DOCKER-INTERNAL
		counter packets 326009021 bytes 343411485217 jump DOCKER-BRIDGE
		iifname "br-566ebeb0f4f1" counter packets 0 bytes 0 accept
		iifname "amn0" counter packets 241615327 bytes 309164175130 accept
		iifname "docker0" counter packets 84214426 bytes 34230569208 accept
	}

	chain DOCKER-BRIDGE {
		oifname "br-566ebeb0f4f1" counter packets 0 bytes 0 jump DOCKER
		oifname "amn0" counter packets 52049 bytes 9001855 jump DOCKER
		oifname "docker0" counter packets 126667 bytes 7707414 jump DOCKER
	}

	chain DOCKER-CT {
		oifname "br-566ebeb0f4f1" ct state related,established counter packets 0 bytes 0 accept
		oifname "amn0" ct state related,established counter packets 249404855 bytes 300295691843 accept
		oifname "docker0" ct state related,established counter packets 73763473 bytes 49367754883 accept
	}

	chain DOCKER-INTERNAL {
	}

	chain DOCKER-USER {
	}

	chain ufw-logging-deny {
		ct state invalid limit rate 3/minute burst 10 packets counter packets 3423 bytes 233214 log prefix "[UFW AUDIT INVALID] "
		limit rate 3/minute burst 10 packets counter packets 3423 bytes 233214 log prefix "[UFW BLOCK] "
	}

	chain ufw-logging-allow {
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW ALLOW] "
	}

	chain ufw-skip-to-policy-input {
		counter packets 2058767 bytes 667260506 drop
	}

	chain ufw-skip-to-policy-output {
		counter packets 0 bytes 0 accept
	}

	chain ufw-skip-to-policy-forward {
		counter packets 0 bytes 0 drop
	}

	chain ufw-not-local {
		fib daddr type local counter packets 2122101 bytes 717178873 return
		fib daddr type multicast counter packets 0 bytes 0 return
		fib daddr type broadcast counter packets 2056679 bytes 667140617 return
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 jump ufw-logging-deny
		counter packets 0 bytes 0 drop
	}

	chain ufw-user-input {
		tcp dport 443 counter packets 9138 bytes 540533 accept
		udp dport 46539 counter packets 203170 bytes 281144190 accept
		udp dport 39425 counter packets 131 bytes 12435 accept
		tcp dport 80 counter packets 25810 bytes 1540024 accept
		udp dport 1194 counter packets 44 bytes 4331 accept
		tcp dport 8443 counter packets 1374 bytes 78250 accept
		udp dport 21194 counter packets 0 bytes 0 accept
		iifname "tun79" counter packets 0 bytes 0 accept
		udp dport 33328 counter packets 0 bytes 0 accept
		tcp dport 52000 counter packets 140 bytes 7452 accept
		udp dport 51820 counter packets 0 bytes 0 accept
		tcp dport 25 counter packets 355 bytes 19088 accept
		tcp dport 9443 counter packets 0 bytes 0 accept
		ip saddr 10.79.79.2 ip daddr 10.79.79.1 iifname "wg79test" counter packets 0 bytes 0 accept
	}

	chain ufw-user-output {
		oifname "tun79" counter packets 0 bytes 0 accept
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
|  |- Currently failed:	28
|  |- Total failed:	28162
   |- Currently banned:	53
   |- Total banned:	432
```

## Docker containers
```text
NAMES                        IMAGE                            STATUS      PORTS
mtproto-telegram             telegrammessenger/proxy:latest   Up 4 days   0.0.0.0:9443->443/tcp, [::]:9443->443/tcp
amnezia-awg2                 amnezia-awg2                     Up 4 days   0.0.0.0:39425->39425/udp, [::]:39425->39425/udp
signal-tls-proxy-certbot-1   certbot/certbot                  Up 4 days   80/tcp, 443/tcp
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
| `/etc/nginx` | directory | root:root | 755 | 4096 | 2026-06-24 17:13:44 |
| `/etc/fail2ban` | directory | root:root | 755 | 4096 | 2026-07-17 23:04:40 |
| `/etc/postfix` | directory | root:root | 755 | 4096 | 2026-06-29 18:34:38 |
| `/etc/dovecot` | missing | - | - | - | - |
| `/etc/cron.d/server-maintenance` | regular file | root:root | 644 | 334 | 2026-07-17 23:29:40 |
| `/opt/server-maintenance` | directory | root:root | 755 | 4096 | 2026-07-17 23:29:01 |
| `/usr/local/sbin/hometele-vpn-user` | missing | - | - | - | - |
| `/usr/local/sbin/hometele-vpn-ssh-wrapper` | missing | - | - | - | - |
| `/usr/local/sbin/www-hometele-vpn` | missing | - | - | - | - |
| `/usr/local/bin/hometele-command-agent.py` | regular file | root:root | 755 | 7535 | 2026-07-02 22:28:01 |
| `/etc/hometele-monitor/command-agent.conf` | regular file | root:root | 600 | 293 | 2026-07-02 22:20:29 |
| `/var/lib/hometele-monitor/command-agent.since` | regular file | root:root | 644 | 43 | 2026-07-22 04:29:58 |
| `/etc/systemd/system/hometele-command-agent.service` | regular file | root:root | 644 | 263 | 2026-07-02 22:20:29 |
| `/etc/systemd/system/hometele-ai.service` | missing | - | - | - | - |
| `/root/.ssh` | directory | root:root | 700 | 4096 | 2025-09-15 11:03:54 |
| `/etc/letsencrypt` | directory | root:root | 755 | 4096 | 2026-06-30 13:11:18 |
| `/root/cert` | directory | root:root | 755 | 4096 | 2025-03-17 17:20:58 |
| `/etc/x-ui` | directory | root:root | 755 | 4096 | 2026-07-22 04:29:43 |
| `/etc/3x-ui` | missing | - | - | - | - |

## SSH keys: fingerprints only
```text
/root/.ssh/authorized_keys -> not a public/private SSH key or unreadable
```

## Maintenance cron
```text
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Daily conditional maintenance at 03:10 Europe/Moscow
10 3 * * * root /opt/server-maintenance/conditional-maintenance.sh azazello

# Weekly package update on Sunday at 03:30 Europe/Moscow
30 3 * * 0 root /opt/server-maintenance/weekly-apt-upgrade.sh

total 20K
drwxr-xr-x 2 root root 4.0K Jul 17 23:29 .
drwxr-xr-x 7 root root 4.0K Jul  4 23:02 ..
-rwxr-xr-x 1 root root 4.0K Jul 17 23:29 conditional-maintenance.sh
-rwxr-xr-x 1 root root 2.4K Jul  4 15:46 restart-containers-and-services.sh
-rwxr-xr-x 1 root root 1.4K Jul  4 15:46 weekly-apt-upgrade.sh

total 116K
drwxr-xr-x  2 root root   4.0K Jul 22 03:10 .
drwxr-xr-x 18 root syslog 4.0K Jul 19 00:00 ..
-rw-r--r--  1 root root    12K Jul  5 06:31 apt-upgrade-2026-07-05.log
-rw-r--r--  1 root root    15K Jul 12 06:33 apt-upgrade-2026-07-12.log
-rw-r--r--  1 root root   2.2K Jul 19 03:30 apt-upgrade-2026-07-19.log
-rw-r--r--  1 root root    819 Jul 17 23:30 conditional-azazello-2026-07-17.log
-rw-r--r--  1 root root   1.4K Jul 18 03:10 conditional-azazello-2026-07-18.log
-rw-r--r--  1 root root   1.4K Jul 19 03:10 conditional-azazello-2026-07-19.log
-rw-r--r--  1 root root   1.4K Jul 20 03:10 conditional-azazello-2026-07-20.log
-rw-r--r--  1 root root   1.4K Jul 21 03:10 conditional-azazello-2026-07-21.log
-rw-r--r--  1 root root   1.4K Jul 22 03:10 conditional-azazello-2026-07-22.log
-rw-r--r--  1 root root   3.2K Jul  5 06:00 restart-2026-07-05.log
-rw-r--r--  1 root root   3.2K Jul  6 06:00 restart-2026-07-06.log
-rw-r--r--  1 root root   3.2K Jul  7 06:00 restart-2026-07-07.log
-rw-r--r--  1 root root   3.2K Jul  8 06:00 restart-2026-07-08.log
-rw-r--r--  1 root root   3.2K Jul  9 06:00 restart-2026-07-09.log
-rw-r--r--  1 root root   3.2K Jul 10 06:00 restart-2026-07-10.log
-rw-r--r--  1 root root   3.2K Jul 11 06:00 restart-2026-07-11.log
-rw-r--r--  1 root root   3.2K Jul 12 06:00 restart-2026-07-12.log
-rw-r--r--  1 root root   3.2K Jul 13 06:00 restart-2026-07-13.log
-rw-r--r--  1 root root   3.2K Jul 14 06:00 restart-2026-07-14.log
-rw-r--r--  1 root root   3.2K Jul 15 06:00 restart-2026-07-15.log
-rw-r--r--  1 root root   3.2K Jul 16 06:00 restart-2026-07-16.log
-rw-r--r--  1 root root   3.2K Jul 17 06:00 restart-2026-07-17.log
```

## Reboot required marker
```text
reboot_required: no
```
