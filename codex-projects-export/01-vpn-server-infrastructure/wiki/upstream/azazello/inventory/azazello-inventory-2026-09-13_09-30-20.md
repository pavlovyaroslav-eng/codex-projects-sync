# Inventory snapshot: azazello

Generated: 2026-09-13T09:30:20+03:00  
Host: azazello  
FQDN: azazello  
Collector: collect-inventory.sh  
Mode: safe / no secrets / no full configs

> This file is intended for the VPN Server WIKI Git repository. It must contain structure and operational facts only.
> Do not paste private keys, tokens, passwords, client UUIDs, MTProto secrets, Reality/WARP private keys or ready VPN links here.

## OS / kernel / uptime
```text
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.5 LTS (Noble Numbat)"
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
         Boot ID: 0b4389ca4a5a4087b5bd3d0878eec52f
  Virtualization: xen
Operating System: Ubuntu 24.04.5 LTS
          Kernel: Linux 6.8.0-107-generic
    Architecture: x86-64
 Hardware Vendor: Xen
  Hardware Model: HVM domU
Firmware Version: 4.13
   Firmware Date: Fri 2020-06-12
    Firmware Age: 6y 3month 1d

Linux azazello 6.8.0-107-generic #107-Ubuntu SMP PREEMPT_DYNAMIC Fri Mar 13 19:51:50 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux

 09:30:20 up 42 days,  6:17,  1 user,  load average: 0.74, 0.51, 0.48
```

## Network addresses
```text
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             91.242.163.206/24 2a00:fd40:c:3091::1/64 fe80::216:3eff:feab:5be3/64 
tun79            UNKNOWN        10.79.0.1 peer 10.79.0.2/32 fe80::3942:c19d:60d3:2119/64 
tun-home-udp     UNKNOWN        10.77.0.1/24 fe80::ddf3:fe20:116e:7ae9/64 
tun-home-tcp     UNKNOWN        10.78.0.1/24 fe80::6813:aaef:b5cb:a1bb/64 
wg-home          UNKNOWN        10.77.77.1/24 
docker0          UP             172.17.0.1/16 fe80::a0b4:1ff:fec0:e98f/64 
br-566ebeb0f4f1  UP             172.18.0.1/16 fe80::649b:5ff:fea5:6988/64 
amn0             UP             172.29.172.1/24 fe80::4c77:5fff:fea0:8b1e/64 
vethe1c2cfd@if2  UP             fe80::98e8:f4ff:fe8e:6564/64 
vethc4c767d@if2  UP             fe80::94a2:79ff:fe88:6747/64 
vethe2d1fbe@if2  UP             fe80::dc88:6aff:feb4:94e/64 
veth4dca428@if3  UP             fe80::d876:b4ff:fe3c:b663/64 
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

2a00:fd40:c:3091::/64 dev eth0 proto kernel metric 256 pref medium
fe80::/64 dev eth0 proto kernel metric 256 pref medium
fe80::/64 dev tun79 proto kernel metric 256 pref medium
fe80::/64 dev tun-home-tcp proto kernel metric 256 pref medium
fe80::/64 dev tun-home-udp proto kernel metric 256 pref medium
fe80::/64 dev vethc4c767d proto kernel metric 256 pref medium
fe80::/64 dev docker0 proto kernel metric 256 pref medium
fe80::/64 dev vethe1c2cfd proto kernel metric 256 pref medium
fe80::/64 dev br-566ebeb0f4f1 proto kernel metric 256 pref medium
fe80::/64 dev amn0 proto kernel metric 256 pref medium
fe80::/64 dev vethe2d1fbe proto kernel metric 256 pref medium
fe80::/64 dev veth4dca428 proto kernel metric 256 pref medium
default via 2a00:fd40:c:3000::1 dev eth0 metric 1024 onlink pref medium
```

## Listening ports
```text
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess                                                     
udp   UNCONN 0      0         127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=818086,fd=16))               
udp   UNCONN 0      0      127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=818086,fd=14))               
udp   UNCONN 0      0          127.0.0.1:8388       0.0.0.0:*    users:(("ss-server",pid=818092,fd=8))                      
udp   UNCONN 0      0            0.0.0.0:39425      0.0.0.0:*    users:(("docker-proxy",pid=3859397,fd=7))                  
udp   UNCONN 0      0            0.0.0.0:51820      0.0.0.0:*                                                               
udp   UNCONN 0      0            0.0.0.0:21194      0.0.0.0:*    users:(("openvpn",pid=1110,fd=5))                          
udp   UNCONN 0      0            0.0.0.0:1194       0.0.0.0:*    users:(("openvpn",pid=1109,fd=5))                          
udp   UNCONN 0      0          127.0.0.1:5353       0.0.0.0:*    users:(("unbound",pid=818244,fd=3))                        
udp   UNCONN 0      0                  *:24443            *:*    users:(("rw-core",pid=2921938,fd=7))                       
udp   UNCONN 0      0              [::1]:8388          [::]:*    users:(("ss-server",pid=818092,fd=7))                      
udp   UNCONN 0      0               [::]:39425         [::]:*    users:(("docker-proxy",pid=3859403,fd=7))                  
udp   UNCONN 0      0               [::]:51820         [::]:*                                                               
tcp   LISTEN 0      1024       127.0.0.1:8388       0.0.0.0:*    users:(("ss-server",pid=818092,fd=6))                      
tcp   LISTEN 0      4096       127.0.0.1:41141      0.0.0.0:*    users:(("containerd",pid=818110,fd=26))                    
tcp   LISTEN 0      4096         0.0.0.0:52000      0.0.0.0:*    users:(("sshd",pid=818111,fd=3),("systemd",pid=1,fd=133))  
tcp   LISTEN 0      4096      127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=818086,fd=17))               
tcp   LISTEN 0      32           0.0.0.0:8443       0.0.0.0:*    users:(("openvpn",pid=1108,fd=5))                          
tcp   LISTEN 0      100          0.0.0.0:25         0.0.0.0:*    users:(("master",pid=818659,fd=13))                        
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=818140,fd=5),("nginx",pid=818135,fd=5))
tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=818086,fd=15))               
tcp   LISTEN 0      256        127.0.0.1:5353       0.0.0.0:*    users:(("unbound",pid=818244,fd=4))                        
tcp   LISTEN 0      4096         0.0.0.0:9443       0.0.0.0:*    users:(("docker-proxy",pid=2560,fd=7))                     
tcp   LISTEN 0      511                *:2222             *:*    users:(("rw-node",pid=2920231,fd=21))                      
tcp   LISTEN 0      1024           [::1]:8388          [::]:*    users:(("ss-server",pid=818092,fd=5))                      
tcp   LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=818140,fd=6),("nginx",pid=818135,fd=6))
tcp   LISTEN 0      4096            [::]:9443          [::]:*    users:(("docker-proxy",pid=2566,fd=7))                     
```

## Systemd services of interest
| Service | Active | Enabled | Unit file present |
|---|---:|---:|---:|
| `xray` | inactive | not-found | no |
| `x-ui` | inactive | not-found | no |
| `3x-ui` | inactive | not-found | no |
| `nginx` | active | enabled | yes |
| `apache2` | inactive | not-found | no |
| `postfix` | active | enabled | yes |
| `dovecot` | inactive | not-found | no |
| `fail2ban` | failed | enabled | yes |
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
nginx	1.24.0-2ubuntu7.17
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
2222/tcp                   ALLOW IN    93.183.106.203             # Remnawave Panel to Node
24443/udp                  ALLOW IN    185.71.196.110             # Hysteria2 bridge from hometele
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
-A INPUT -i tun79 -j ACCEPT
-A INPUT -j ufw-before-logging-input
-A INPUT -j ufw-before-input
-A INPUT -j ufw-after-input
-A INPUT -j ufw-after-logging-input
-A INPUT -j ufw-reject-input
-A INPUT -j ufw-track-input
-A FORWARD -j DOCKER-USER
-A FORWARD -j DOCKER-FORWARD
-A FORWARD -d 10.79.0.0/24 -i eth0 -o tun79 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 10.79.0.0/24 -i tun79 -o eth0 -j ACCEPT
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
-A DOCKER -d 172.17.0.2/32 ! -i docker0 -o docker0 -p tcp -m tcp --dport 443 -j ACCEPT
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
-A ufw-user-input -s 10.79.79.2/32 -d 10.79.79.1/32 -i wg79test -j ACCEPT
-A ufw-user-input -s 93.183.106.203/32 -p tcp -m tcp --dport 2222 -j ACCEPT
-A ufw-user-input -s 185.71.196.110/32 -p udp -m udp --dport 24443 -j ACCEPT
-A ufw-user-limit -m limit --limit 3/min -j LOG --log-prefix "[UFW LIMIT BLOCK] "
-A ufw-user-limit -j REJECT --reject-with icmp-port-unreachable
-A ufw-user-limit-accept -j ACCEPT
-A ufw-user-output -o tun79 -j ACCEPT

table ip filter {
	chain ufw-before-logging-input {
		ct state new limit rate 3/minute burst 10 packets counter packets 43473 bytes 10312197 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-output {
		ct state new limit rate 3/minute burst 10 packets counter packets 43473 bytes 3428723 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-forward {
		ct state new limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-input {
		iifname "lo" counter packets 203166 bytes 86146464 accept
		ct state related,established counter packets 133260181 bytes 127567862612 accept
		ct state invalid counter packets 877 bytes 235431 jump ufw-logging-deny
		ct state invalid counter packets 877 bytes 235431 drop
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 5306 bytes 313113 accept
		udp sport 67 udp dport 68 counter packets 0 bytes 0 accept
		counter packets 2163896 bytes 680511443 jump ufw-not-local
		ip daddr 224.0.0.251 udp dport 5353 counter packets 0 bytes 0 accept
		ip daddr 239.255.255.250 udp dport 1900 counter packets 0 bytes 0 accept
		counter packets 2163896 bytes 680511443 jump ufw-user-input
	}

	chain ufw-before-output {
		oifname "lo" counter packets 203166 bytes 86146464 accept
		ct state related,established counter packets 147589375 bytes 132023297600 accept
		counter packets 2606606 bytes 312786372 jump ufw-user-output
	}

	chain ufw-before-forward {
		ct state related,established counter packets 0 bytes 0 accept
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 0 bytes 0 accept
		counter packets 0 bytes 0 jump ufw-user-forward
	}

	chain ufw-after-input {
		udp dport 137 counter packets 172 bytes 14278 jump ufw-skip-to-policy-input
		udp dport 138 counter packets 5 bytes 1010 jump ufw-skip-to-policy-input
		tcp dport 139 counter packets 97 bytes 4456 jump ufw-skip-to-policy-input
		tcp dport 445 counter packets 777 bytes 36636 jump ufw-skip-to-policy-input
		udp dport 67 counter packets 758005 bytes 248624964 jump ufw-skip-to-policy-input
		udp dport 68 counter packets 7 bytes 196 jump ufw-skip-to-policy-input
		fib daddr type broadcast counter packets 126312 bytes 38462945 jump ufw-skip-to-policy-input
	}

	chain ufw-after-output {
	}

	chain ufw-after-forward {
	}

	chain ufw-after-logging-input {
		limit rate 3/minute burst 10 packets counter packets 43472 bytes 2680132 log prefix "[UFW BLOCK] "
	}

	chain ufw-after-logging-output {
		limit rate 3/minute burst 10 packets counter packets 43473 bytes 3451917 log prefix "[UFW ALLOW] "
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
		ip protocol tcp ct state new counter packets 1156809 bytes 69411576 accept
		ip protocol udp ct state new counter packets 1446259 bytes 243000213 accept
	}

	chain ufw-track-forward {
	}

	chain INPUT {
		type filter hook input priority filter; policy drop;
		iifname "tun79" counter packets 0 bytes 0 accept
		counter packets 443929167 bytes 450015267699 jump ufw-before-logging-input
		counter packets 443929167 bytes 450015267699 jump ufw-before-input
		counter packets 4897165 bytes 1286228549 jump ufw-after-input
		counter packets 1188520 bytes 86851144 jump ufw-after-logging-input
		counter packets 1188520 bytes 86851144 jump ufw-reject-input
		counter packets 1188520 bytes 86851144 jump ufw-track-input
	}

	chain OUTPUT {
		type filter hook output priority filter; policy accept;
		oifname "tun79" counter packets 0 bytes 0 accept
		counter packets 405618504 bytes 330331863285 jump ufw-before-logging-output
		counter packets 405618504 bytes 330331863285 jump ufw-before-output
		counter packets 3555805 bytes 405909328 jump ufw-after-output
		counter packets 3555805 bytes 405909328 jump ufw-after-logging-output
		counter packets 3555805 bytes 405909328 jump ufw-reject-output
		counter packets 3555805 bytes 405909328 jump ufw-track-output
	}

	chain FORWARD {
		type filter hook forward priority filter; policy drop;
		counter packets 1744052986 bytes 2079108258533 jump DOCKER-USER
		counter packets 1744052993 bytes 2079108259747 jump DOCKER-FORWARD
		ip daddr 10.79.0.0/24 iifname "eth0" oifname "tun79" ct state related,established counter packets 9145010 bytes 11373857446 accept
		ip saddr 10.79.0.0/24 iifname "tun79" oifname "eth0" counter packets 11650546 bytes 5239036250 accept
		counter packets 5 bytes 268 jump ufw-before-logging-forward
		counter packets 5 bytes 268 jump ufw-before-forward
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
		ip daddr 172.29.172.2 iifname != "amn0" oifname "amn0" udp dport 39425 counter packets 12945 bytes 3707485 accept
		ip daddr 172.17.0.2 iifname != "docker0" oifname "docker0" tcp dport 443 counter packets 490661 bytes 30202550 accept
		iifname != "br-566ebeb0f4f1" oifname "br-566ebeb0f4f1" counter packets 22 bytes 1320 drop
		iifname != "amn0" oifname "amn0" counter packets 0 bytes 0 drop
		iifname != "docker0" oifname "docker0" counter packets 0 bytes 0 drop
	}

	chain DOCKER-FORWARD {
		counter packets 1744052993 bytes 2079108259747 jump DOCKER-CT
		counter packets 881774193 bytes 1053348027566 jump DOCKER-INTERNAL
		counter packets 881774193 bytes 1053348027566 jump DOCKER-BRIDGE
		iifname "br-566ebeb0f4f1" counter packets 0 bytes 0 accept
		iifname "amn0" counter packets 635227069 bytes 893084932755 accept
		iifname "docker0" counter packets 225218289 bytes 143611299637 accept
	}

	chain DOCKER-BRIDGE {
		oifname "br-566ebeb0f4f1" counter packets 22 bytes 1320 jump DOCKER
		oifname "amn0" counter packets 42616 bytes 8706885 jump DOCKER
		oifname "docker0" counter packets 490661 bytes 30202550 jump DOCKER
	}

	chain DOCKER-CT {
		oifname "br-566ebeb0f4f1" ct state related,established counter packets 0 bytes 0 accept
		oifname "amn0" ct state related,established counter packets 652730202 bytes 866142887718 accept
		oifname "docker0" ct state related,established counter packets 209548598 bytes 159617344463 accept
	}

	chain DOCKER-INTERNAL {
	}

	chain DOCKER-USER {
	}

	chain ufw-logging-deny {
		ct state invalid limit rate 3/minute burst 10 packets counter packets 838 bytes 233871 log prefix "[UFW AUDIT INVALID] "
		limit rate 3/minute burst 10 packets counter packets 838 bytes 233871 log prefix "[UFW BLOCK] "
	}

	chain ufw-logging-allow {
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW ALLOW] "
	}

	chain ufw-skip-to-policy-input {
		counter packets 885375 bytes 287144485 drop
	}

	chain ufw-skip-to-policy-output {
		counter packets 0 bytes 0 accept
	}

	chain ufw-skip-to-policy-forward {
		counter packets 0 bytes 0 drop
	}

	chain ufw-not-local {
		fib daddr type local counter packets 1279523 bytes 393419416 return
		fib daddr type multicast counter packets 0 bytes 0 return
		fib daddr type broadcast counter packets 884373 bytes 287092027 return
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 jump ufw-logging-deny
		counter packets 0 bytes 0 drop
	}

	chain ufw-user-input {
		tcp dport 443 counter packets 440518 bytes 25980638 accept
		udp dport 46539 counter packets 245901 bytes 330158015 accept
		udp dport 39425 counter packets 231 bytes 56034 accept
		tcp dport 80 counter packets 308604 bytes 18189039 accept
		udp dport 1194 counter packets 105 bytes 4612 accept
		tcp dport 8443 counter packets 76544 bytes 4506631 accept
		udp dport 21194 counter packets 3 bytes 452 accept
		iifname "tun79" counter packets 0 bytes 0 accept
		udp dport 33328 counter packets 0 bytes 0 accept
		tcp dport 52000 counter packets 446 bytes 25537 accept
		udp dport 51820 counter packets 0 bytes 0 accept
		tcp dport 25 counter packets 1171 bytes 64336 accept
		tcp dport 9443 counter packets 0 bytes 0 accept
		ip saddr 10.79.79.2 ip daddr 10.79.79.1 iifname "wg79test" counter packets 0 bytes 0 accept
		ip saddr 93.183.106.203 tcp dport 2222 counter packets 26 bytes 1560 accept
		ip saddr 185.71.196.110 udp dport 24443 counter packets 1464 bytes 1914912 accept
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
2026-09-13 09:30:23,774 fail2ban                [874825]: ERROR   Failed to access socket path: /var/run/fail2ban/fail2ban.sock. Is fail2ban running?
```

## Docker containers
```text
NAMES                        IMAGE                            STATUS       PORTS
remnanode                    remnawave/node:3.4.1             Up 10 days   
mtproto-telegram             telegrammessenger/proxy:latest   Up 6 weeks   0.0.0.0:9443->443/tcp, [::]:9443->443/tcp
amnezia-awg2                 amnezia-awg2                     Up 5 days    0.0.0.0:39425->39425/udp, [::]:39425->39425/udp
signal-tls-proxy-certbot-1   certbot/certbot                  Up 6 weeks   80/tcp, 443/tcp
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
| `/etc/nginx` | directory | root:root | 755 | 4096 | 2026-08-23 03:31:33 |
| `/etc/fail2ban` | directory | root:root | 755 | 4096 | 2026-08-07 08:37:24 |
| `/etc/postfix` | directory | root:root | 755 | 4096 | 2026-06-29 18:34:38 |
| `/etc/dovecot` | missing | - | - | - | - |
| `/etc/cron.d/server-maintenance` | regular file | root:root | 644 | 334 | 2026-07-17 23:29:40 |
| `/opt/server-maintenance` | directory | root:root | 755 | 4096 | 2026-07-17 23:29:01 |
| `/usr/local/sbin/hometele-vpn-user` | missing | - | - | - | - |
| `/usr/local/sbin/hometele-vpn-ssh-wrapper` | missing | - | - | - | - |
| `/usr/local/sbin/www-hometele-vpn` | missing | - | - | - | - |
| `/usr/local/bin/hometele-command-agent.py` | regular file | root:root | 755 | 7535 | 2026-07-02 22:28:01 |
| `/etc/hometele-monitor/command-agent.conf` | regular file | root:root | 600 | 293 | 2026-07-02 22:20:29 |
| `/var/lib/hometele-monitor/command-agent.since` | regular file | root:root | 644 | 49 | 2026-09-13 09:30:03 |
| `/etc/systemd/system/hometele-command-agent.service` | regular file | root:root | 644 | 263 | 2026-07-02 22:20:29 |
| `/etc/systemd/system/hometele-ai.service` | missing | - | - | - | - |
| `/root/.ssh` | directory | root:root | 700 | 4096 | 2025-09-15 11:03:54 |
| `/etc/letsencrypt` | directory | root:root | 755 | 4096 | 2026-09-12 19:12:21 |
| `/root/cert` | directory | root:root | 755 | 4096 | 2025-03-17 17:20:58 |
| `/etc/x-ui` | missing | - | - | - | - |
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
drwxr-xr-x 9 root root 4.0K Sep  3 08:33 ..
-rwxr-xr-x 1 root root 4.0K Jul 17 23:29 conditional-maintenance.sh
-rwxr-xr-x 1 root root 2.4K Jul  4 15:46 restart-containers-and-services.sh
-rwxr-xr-x 1 root root 1.4K Jul  4 15:46 weekly-apt-upgrade.sh

total 424K
drwxr-xr-x  2 root root   4.0K Sep 13 03:30 .
drwxr-xr-x 17 root syslog 4.0K Sep 13 00:00 ..
-rw-r--r--  1 root root    12K Jul  5 06:31 apt-upgrade-2026-07-05.log
-rw-r--r--  1 root root    15K Jul 12 06:33 apt-upgrade-2026-07-12.log
-rw-r--r--  1 root root   2.2K Jul 19 03:30 apt-upgrade-2026-07-19.log
-rw-r--r--  1 root root    16K Jul 26 03:32 apt-upgrade-2026-07-26.log
-rw-r--r--  1 root root   1.6K Aug  2 03:30 apt-upgrade-2026-08-02.log
-rw-r--r--  1 root root   4.6K Aug  9 03:31 apt-upgrade-2026-08-09.log
-rw-r--r--  1 root root   5.1K Aug 16 03:31 apt-upgrade-2026-08-16.log
-rw-r--r--  1 root root    15K Aug 23 03:33 apt-upgrade-2026-08-23.log
-rw-r--r--  1 root root    23K Aug 30 03:32 apt-upgrade-2026-08-30.log
-rw-r--r--  1 root root   1.6K Sep  6 03:30 apt-upgrade-2026-09-06.log
-rw-r--r--  1 root root    15K Sep 13 03:33 apt-upgrade-2026-09-13.log
-rw-r--r--  1 root root    819 Jul 17 23:30 conditional-azazello-2026-07-17.log
-rw-r--r--  1 root root   1.4K Jul 18 03:10 conditional-azazello-2026-07-18.log
-rw-r--r--  1 root root   1.4K Jul 19 03:10 conditional-azazello-2026-07-19.log
-rw-r--r--  1 root root   1.4K Jul 20 03:10 conditional-azazello-2026-07-20.log
-rw-r--r--  1 root root   1.4K Jul 21 03:10 conditional-azazello-2026-07-21.log
-rw-r--r--  1 root root   1.4K Jul 22 03:10 conditional-azazello-2026-07-22.log
-rw-r--r--  1 root root   1.4K Jul 23 03:10 conditional-azazello-2026-07-23.log
-rw-r--r--  1 root root   1.4K Jul 24 03:10 conditional-azazello-2026-07-24.log
-rw-r--r--  1 root root   1.4K Jul 25 03:10 conditional-azazello-2026-07-25.log
-rw-r--r--  1 root root   1.4K Jul 26 03:10 conditional-azazello-2026-07-26.log
-rw-r--r--  1 root root   1.5K Jul 27 03:10 conditional-azazello-2026-07-27.log
-rw-r--r--  1 root root   1.5K Jul 28 03:10 conditional-azazello-2026-07-28.log
-rw-r--r--  1 root root   1.5K Jul 29 03:10 conditional-azazello-2026-07-29.log
-rw-r--r--  1 root root   1.5K Jul 30 03:10 conditional-azazello-2026-07-30.log
-rw-r--r--  1 root root   1.5K Jul 31 03:10 conditional-azazello-2026-07-31.log
-rw-r--r--  1 root root   1.5K Aug  1 03:10 conditional-azazello-2026-08-01.log
-rw-r--r--  1 root root    114 Aug  2 03:10 conditional-azazello-2026-08-02.log
-rw-r--r--  1 root root    196 Aug  3 03:10 conditional-azazello-2026-08-03.log
-rw-r--r--  1 root root    196 Aug  4 03:10 conditional-azazello-2026-08-04.log
-rw-r--r--  1 root root    196 Aug  5 03:10 conditional-azazello-2026-08-05.log
-rw-r--r--  1 root root    196 Aug  6 03:10 conditional-azazello-2026-08-06.log
-rw-r--r--  1 root root    196 Aug  7 03:10 conditional-azazello-2026-08-07.log
-rw-r--r--  1 root root    196 Aug  8 03:10 conditional-azazello-2026-08-08.log
-rw-r--r--  1 root root    196 Aug  9 03:10 conditional-azazello-2026-08-09.log
-rw-r--r--  1 root root    196 Aug 10 03:10 conditional-azazello-2026-08-10.log
-rw-r--r--  1 root root    196 Aug 11 03:10 conditional-azazello-2026-08-11.log
-rw-r--r--  1 root root   1.6K Aug 12 03:10 conditional-azazello-2026-08-12.log
-rw-r--r--  1 root root   1.6K Aug 13 03:10 conditional-azazello-2026-08-13.log
-rw-r--r--  1 root root   1.6K Aug 14 03:10 conditional-azazello-2026-08-14.log
-rw-r--r--  1 root root   1.6K Aug 15 03:10 conditional-azazello-2026-08-15.log
-rw-r--r--  1 root root   1.6K Aug 16 03:10 conditional-azazello-2026-08-16.log
-rw-r--r--  1 root root   1.6K Aug 17 03:10 conditional-azazello-2026-08-17.log
-rw-r--r--  1 root root   1.6K Aug 18 03:10 conditional-azazello-2026-08-18.log
-rw-r--r--  1 root root   1.6K Aug 19 03:10 conditional-azazello-2026-08-19.log
-rw-r--r--  1 root root   1.6K Aug 20 03:10 conditional-azazello-2026-08-20.log
-rw-r--r--  1 root root   1.6K Aug 21 03:10 conditional-azazello-2026-08-21.log
-rw-r--r--  1 root root   1.6K Aug 22 03:10 conditional-azazello-2026-08-22.log
-rw-r--r--  1 root root    931 Aug 23 03:10 conditional-azazello-2026-08-23.log
-rw-r--r--  1 root root   1.6K Aug 24 03:10 conditional-azazello-2026-08-24.log
-rw-r--r--  1 root root   1.6K Aug 25 03:10 conditional-azazello-2026-08-25.log
-rw-r--r--  1 root root   1.6K Aug 26 03:10 conditional-azazello-2026-08-26.log
-rw-r--r--  1 root root   1.6K Aug 27 03:10 conditional-azazello-2026-08-27.log
-rw-r--r--  1 root root   1.6K Aug 28 03:10 conditional-azazello-2026-08-28.log
-rw-r--r--  1 root root   1.6K Aug 29 03:10 conditional-azazello-2026-08-29.log
-rw-r--r--  1 root root   1.6K Aug 30 03:10 conditional-azazello-2026-08-30.log
-rw-r--r--  1 root root   1.7K Aug 31 03:10 conditional-azazello-2026-08-31.log
-rw-r--r--  1 root root   1.7K Sep  1 03:10 conditional-azazello-2026-09-01.log
-rw-r--r--  1 root root   1.7K Sep  2 03:10 conditional-azazello-2026-09-02.log
-rw-r--r--  1 root root   1.8K Sep  3 03:10 conditional-azazello-2026-09-03.log
-rw-r--r--  1 root root   1.8K Sep  4 03:10 conditional-azazello-2026-09-04.log
-rw-r--r--  1 root root   1.8K Sep  5 03:10 conditional-azazello-2026-09-05.log
-rw-r--r--  1 root root   1.8K Sep  6 03:10 conditional-azazello-2026-09-06.log
-rw-r--r--  1 root root   1.8K Sep  7 03:10 conditional-azazello-2026-09-07.log
-rw-r--r--  1 root root   1.8K Sep  8 03:10 conditional-azazello-2026-09-08.log
-rw-r--r--  1 root root   1.8K Sep  9 03:10 conditional-azazello-2026-09-09.log
-rw-r--r--  1 root root   1.8K Sep 10 03:10 conditional-azazello-2026-09-10.log
-rw-r--r--  1 root root   1.8K Sep 11 03:10 conditional-azazello-2026-09-11.log
-rw-r--r--  1 root root   1.8K Sep 12 03:10 conditional-azazello-2026-09-12.log
-rw-r--r--  1 root root   1.8K Sep 13 03:10 conditional-azazello-2026-09-13.log
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
reboot_required: yes
libc6
```
