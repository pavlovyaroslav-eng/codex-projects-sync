# Inventory snapshot: hometele

Generated: 2026-08-26T04:20:01+03:00  
Host: hometele  
FQDN: hometele.com.ru  
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

 Static hostname: hometele
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: 5aeb8798d802b4adc245030f2d81c352
         Boot ID: d93132f5fe2b49afa50c96c1f35d92e5
  Virtualization: kvm
Operating System: Ubuntu 24.04.4 LTS
          Kernel: Linux 6.8.0-138-generic
    Architecture: x86-64
 Hardware Vendor: Red Hat
  Hardware Model: KVM
Firmware Version: 1.16.0-4.module_el8.9.0+3659+9c8643f3
   Firmware Date: Tue 2014-04-01
    Firmware Age: 12y 4month 3w 4d

Linux hometele 6.8.0-138-generic #138-Ubuntu SMP PREEMPT_DYNAMIC Fri Jul 31 22:41:49 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux

 04:20:01 up 5 days, 59 min,  0 user,  load average: 0.00, 0.00, 0.00
```

## Network addresses
```text
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens3             UP             185.71.196.110/24 fe80::5054:ff:fe86:dd22/64 
awg79            UNKNOWN        10.8.1.2/32 fe80::6d07:68c9:fc57:f7f6/64 
tun93            UNKNOWN        10.93.0.12/24 fe80::5df0:2067:7af5:b5ba/64 
tun79            UNKNOWN        10.79.0.2 peer 10.79.0.1/32 fe80::2905:1758:1cad:f266/64 
tun92            UNKNOWN        10.92.0.1/24 fe80::87db:16e6:a0ff:37b6/64 
tun88            UNKNOWN        10.88.0.1/24 fe80::3759:1f7:78a:4b2d/64 
tun90            UNKNOWN        10.90.0.1/24 fe80::c12d:6344:517c:a59e/64 
tun89            UNKNOWN        10.89.0.1/24 fe80::cd85:a47d:4d83:8414/64 
tun91            UNKNOWN        10.91.0.1/24 fe80::b835:94eb:8cdd:8f95/64 
wg-home          UNKNOWN        10.77.77.1/24 
```

## Routes
```text
default via 185.71.196.1 dev ens3 onlink 
10.77.77.0/24 dev wg-home proto kernel scope link src 10.77.77.1 
10.79.0.1 dev tun79 proto kernel scope link src 10.79.0.2 
10.88.0.0/24 dev tun88 proto kernel scope link src 10.88.0.1 
10.89.0.0/24 dev tun89 proto kernel scope link src 10.89.0.1 
10.90.0.0/24 dev tun90 proto kernel scope link src 10.90.0.1 
10.91.0.0/24 dev tun91 proto kernel scope link src 10.91.0.1 
10.92.0.0/24 dev tun92 proto kernel scope link src 10.92.0.1 
10.93.0.0/24 dev tun93 proto kernel scope link src 10.93.0.12 
10.93.0.10 via 10.93.0.1 dev tun93 
185.71.196.0/24 dev ens3 proto kernel scope link src 185.71.196.110 
192.168.1.39 dev wg-home scope link 

fe80::/64 dev ens3 proto kernel metric 256 pref medium
fe80::/64 dev tun93 proto kernel metric 256 pref medium
fe80::/64 dev tun79 proto kernel metric 256 pref medium
fe80::/64 dev awg79 proto kernel metric 256 pref medium
fe80::/64 dev tun92 proto kernel metric 256 pref medium
fe80::/64 dev tun88 proto kernel metric 256 pref medium
fe80::/64 dev tun90 proto kernel metric 256 pref medium
fe80::/64 dev tun89 proto kernel metric 256 pref medium
fe80::/64 dev tun91 proto kernel metric 256 pref medium
```

## Listening ports
```text
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess                                                                                                     
udp   UNCONN 0      0         127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=794,fd=16))                                                                  
udp   UNCONN 0      0      127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=794,fd=14))                                                                  
udp   UNCONN 0      0           10.8.1.2:34980      0.0.0.0:*    users:(("xray",pid=971,fd=997))                                                                            
udp   UNCONN 0      0           10.8.1.2:48365      0.0.0.0:*    users:(("xray",pid=971,fd=988))                                                                            
udp   UNCONN 0      0           10.8.1.2:53695      0.0.0.0:*    users:(("xray",pid=971,fd=2197))                                                                           
udp   UNCONN 0      0          127.0.0.1:10808      0.0.0.0:*    users:(("xray",pid=971,fd=7))                                                                              
udp   UNCONN 0      0            0.0.0.0:51820      0.0.0.0:*                                                                                                               
udp   UNCONN 0      0            0.0.0.0:21195      0.0.0.0:*    users:(("openvpn",pid=847,fd=5))                                                                           
udp   UNCONN 0      0            0.0.0.0:21196      0.0.0.0:*    users:(("openvpn",pid=870,fd=5))                                                                           
udp   UNCONN 0      0            0.0.0.0:21198      0.0.0.0:*    users:(("openvpn",pid=863,fd=5))                                                                           
udp   UNCONN 0      0            0.0.0.0:21199      0.0.0.0:*    users:(("openvpn",pid=852,fd=5))                                                                           
udp   UNCONN 0      0            0.0.0.0:37619      0.0.0.0:*    users:(("amneziawg-go",pid=837,fd=14))                                                                     
udp   UNCONN 0      0            0.0.0.0:35588      0.0.0.0:*    users:(("openvpn",pid=834,fd=3))                                                                           
udp   UNCONN 0      0           10.8.1.2:59202      0.0.0.0:*    users:(("xray",pid=971,fd=1203))                                                                           
udp   UNCONN 0      0            0.0.0.0:53062      0.0.0.0:*    users:(("openvpn",pid=833,fd=4))                                                                           
udp   UNCONN 0      0           10.8.1.2:48987      0.0.0.0:*    users:(("xray",pid=971,fd=944))                                                                            
udp   UNCONN 0      0               [::]:51820         [::]:*                                                                                                               
udp   UNCONN 0      0               [::]:37619         [::]:*    users:(("amneziawg-go",pid=837,fd=15))                                                                     
tcp   LISTEN 0      4096      127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=794,fd=17))                                                                  
tcp   LISTEN 0      4096       127.0.0.1:10808      0.0.0.0:*    users:(("xray",pid=971,fd=6))                                                                              
tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=794,fd=15))                                                                  
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=1022,fd=7),("nginx",pid=1021,fd=7),("nginx",pid=1020,fd=7),("nginx",pid=1018,fd=7))    
tcp   LISTEN 0      100          0.0.0.0:25         0.0.0.0:*    users:(("master",pid=1609,fd=13))                                                                          
tcp   LISTEN 0      511        127.0.0.1:8443       0.0.0.0:*    users:(("nginx",pid=1022,fd=9),("nginx",pid=1021,fd=9),("nginx",pid=1020,fd=9),("nginx",pid=1018,fd=9))    
tcp   LISTEN 0      4096         0.0.0.0:52000      0.0.0.0:*    users:(("sshd",pid=1941,fd=3),("systemd",pid=1,fd=240))                                                    
tcp   LISTEN 0      32           0.0.0.0:21197      0.0.0.0:*    users:(("openvpn",pid=860,fd=5))                                                                           
tcp   LISTEN 0      4096               *:443              *:*    users:(("xray",pid=971,fd=3))                                                                              
tcp   LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=1022,fd=8),("nginx",pid=1021,fd=8),("nginx",pid=1020,fd=8),("nginx",pid=1018,fd=8))    
tcp   LISTEN 0      511            [::1]:8443          [::]:*    users:(("nginx",pid=1022,fd=10),("nginx",pid=1021,fd=10),("nginx",pid=1020,fd=10),("nginx",pid=1018,fd=10))
tcp   LISTEN 0      4096            [::]:52000         [::]:*    users:(("sshd",pid=1941,fd=4),("systemd",pid=1,fd=241))                                                    
```

## Systemd services of interest
| Service | Active | Enabled | Unit file present |
|---|---:|---:|---:|
| `xray` | active | enabled | yes |
| `x-ui` | inactive | not-found | no |
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
| `docker` | inactive | not-found | no |
| `cron` | active | enabled | yes |
| `crond` | inactive | not-found | no |
| `ssh` | active | disabled | yes |
| `sshd` | inactive | not-found | no |

## Package versions of interest
```text
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
80/tcp                     ALLOW IN    Anywhere                   # HTTP ACME and redirect
52000/tcp                  ALLOW IN    Anywhere                  
21195/udp                  ALLOW IN    Anywhere                   # OpenVPN home-router UDP
21196/udp                  ALLOW IN    Anywhere                   # OpenVPN tplink-ax73 UDP
21197/tcp                  ALLOW IN    Anywhere                   # OpenVPN tplink-ax73-simple TCP
21198/udp                  ALLOW IN    Anywhere                   # OpenVPN tplink-ax73-udp UDP
21199/udp                  ALLOW IN    Anywhere                   # OpenVPN tplink-ax73-gcm UDP
51820/udp                  ALLOW IN    Anywhere                   # WireGuard Hometele HomeAssistant
51822/udp                  ALLOW IN    91.242.163.206             # wg79test azazello only
443/tcp (v6)               ALLOW IN    Anywhere (v6)              # Xray VLESS Reality TCP
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP ACME and redirect
52000/tcp (v6)             ALLOW IN    Anywhere (v6)             
21195/udp (v6)             ALLOW IN    Anywhere (v6)              # OpenVPN home-router UDP
21196/udp (v6)             ALLOW IN    Anywhere (v6)              # OpenVPN tplink-ax73 UDP
21197/tcp (v6)             ALLOW IN    Anywhere (v6)              # OpenVPN tplink-ax73-simple TCP
21198/udp (v6)             ALLOW IN    Anywhere (v6)              # OpenVPN tplink-ax73-udp UDP
21199/udp (v6)             ALLOW IN    Anywhere (v6)              # OpenVPN tplink-ax73-gcm UDP
51820/udp (v6)             ALLOW IN    Anywhere (v6)              # WireGuard Hometele HomeAssistant

Anywhere on tun79          ALLOW FWD   Anywhere on tun88         
Anywhere on tun88          ALLOW FWD   Anywhere on tun79         
Anywhere on tun79          ALLOW FWD   Anywhere on tun89         
Anywhere on tun89          ALLOW FWD   Anywhere on tun79         
Anywhere on tun79          ALLOW FWD   Anywhere on tun90         
Anywhere on tun90          ALLOW FWD   Anywhere on tun79         
Anywhere on tun79          ALLOW FWD   Anywhere on tun91         
Anywhere on tun91          ALLOW FWD   Anywhere on tun79         
Anywhere on tun79          ALLOW FWD   Anywhere on tun92         
Anywhere on tun92          ALLOW FWD   Anywhere on tun79         
Anywhere (v6) on tun79     ALLOW FWD   Anywhere (v6) on tun88    
Anywhere (v6) on tun88     ALLOW FWD   Anywhere (v6) on tun79    
Anywhere (v6) on tun79     ALLOW FWD   Anywhere (v6) on tun89    
Anywhere (v6) on tun89     ALLOW FWD   Anywhere (v6) on tun79    
Anywhere (v6) on tun79     ALLOW FWD   Anywhere (v6) on tun90    
Anywhere (v6) on tun90     ALLOW FWD   Anywhere (v6) on tun79    
Anywhere (v6) on tun79     ALLOW FWD   Anywhere (v6) on tun91    
Anywhere (v6) on tun91     ALLOW FWD   Anywhere (v6) on tun79    
Anywhere (v6) on tun79     ALLOW FWD   Anywhere (v6) on tun92    
Anywhere (v6) on tun92     ALLOW FWD   Anywhere (v6) on tun79    


-P INPUT DROP
-P FORWARD DROP
-P OUTPUT ACCEPT
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
-A INPUT -j ufw-before-logging-input
-A INPUT -j ufw-before-input
-A INPUT -j ufw-after-input
-A INPUT -j ufw-after-logging-input
-A INPUT -j ufw-reject-input
-A INPUT -j ufw-track-input
-A FORWARD -d 10.91.0.0/24 -i tun79 -o tun91 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -d 10.88.0.0/24 -i tun79 -o tun88 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -d 10.89.0.0/24 -i tun79 -o tun89 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 10.89.0.0/24 -i tun89 -o tun79 -j ACCEPT
-A FORWARD -s 10.88.0.0/24 -i tun88 -o tun79 -j ACCEPT
-A FORWARD -d 10.92.0.0/24 -i tun79 -o tun92 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -d 10.90.0.0/24 -i tun79 -o tun90 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 10.91.0.0/24 -i tun91 -o tun79 -j ACCEPT
-A FORWARD -s 10.92.0.0/24 -i tun92 -o tun79 -j ACCEPT
-A FORWARD -s 10.90.0.0/24 -i tun90 -o tun79 -j ACCEPT
-A FORWARD -j ufw-before-logging-forward
-A FORWARD -j ufw-before-forward
-A FORWARD -j ufw-after-forward
-A FORWARD -j ufw-after-logging-forward
-A FORWARD -j ufw-reject-forward
-A FORWARD -j ufw-track-forward
-A FORWARD -i wg-home -j ACCEPT
-A FORWARD -o wg-home -j ACCEPT
-A FORWARD -s 10.77.77.0/24 -i wg-home -o tun79 -j ACCEPT
-A FORWARD -d 10.77.77.0/24 -i tun79 -o wg-home -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A OUTPUT -j ufw-before-logging-output
-A OUTPUT -j ufw-before-output
-A OUTPUT -j ufw-after-output
-A OUTPUT -j ufw-after-logging-output
-A OUTPUT -j ufw-reject-output
-A OUTPUT -j ufw-track-output
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
-A ufw-user-forward -i tun88 -o tun79 -j ACCEPT
-A ufw-user-forward -i tun79 -o tun88 -j ACCEPT
-A ufw-user-forward -i tun89 -o tun79 -j ACCEPT
-A ufw-user-forward -i tun79 -o tun89 -j ACCEPT
-A ufw-user-forward -i tun90 -o tun79 -j ACCEPT
-A ufw-user-forward -i tun79 -o tun90 -j ACCEPT
-A ufw-user-forward -i tun91 -o tun79 -j ACCEPT
-A ufw-user-forward -i tun79 -o tun91 -j ACCEPT
-A ufw-user-forward -i tun92 -o tun79 -j ACCEPT
-A ufw-user-forward -i tun79 -o tun92 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 443 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 80 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 52000 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 21195 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 21196 -j ACCEPT
-A ufw-user-input -p tcp -m tcp --dport 21197 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 21198 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 21199 -j ACCEPT
-A ufw-user-input -p udp -m udp --dport 51820 -j ACCEPT
-A ufw-user-input -s 91.242.163.206/32 -p udp -m udp --dport 51822 -j ACCEPT
-A ufw-user-limit -m limit --limit 3/min -j LOG --log-prefix "[UFW LIMIT BLOCK] "
-A ufw-user-limit -j REJECT --reject-with icmp-port-unreachable
-A ufw-user-limit-accept -j ACCEPT

table ip filter {
	chain ufw-before-logging-input {
		ct state new limit rate 3/minute burst 10 packets counter packets 21789 bytes 2218365 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-output {
		ct state new limit rate 3/minute burst 10 packets counter packets 21789 bytes 5094757 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-logging-forward {
		ct state new limit rate 3/minute burst 10 packets counter packets 4946 bytes 302664 log prefix "[UFW AUDIT] "
	}

	chain ufw-before-input {
		iifname "lo" counter packets 10471942 bytes 4807329720 accept
		ct state related,established counter packets 180406460 bytes 228013650364 accept
		ct state invalid counter packets 20324 bytes 1119554 jump ufw-logging-deny
		ct state invalid counter packets 20324 bytes 1119554 drop
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 1672 bytes 89545 accept
		udp sport 67 udp dport 68 counter packets 0 bytes 0 accept
		counter packets 1446310 bytes 151641526 jump ufw-not-local
		ip daddr 224.0.0.251 udp dport 5353 counter packets 0 bytes 0 accept
		ip daddr 239.255.255.250 udp dport 1900 counter packets 0 bytes 0 accept
		counter packets 1446310 bytes 151641526 jump ufw-user-input
	}

	chain ufw-before-output {
		oifname "lo" counter packets 10471942 bytes 4807329720 accept
		ct state related,established counter packets 139297032 bytes 141554866683 accept
		counter packets 1406461 bytes 609330353 jump ufw-user-output
	}

	chain ufw-before-forward {
		ct state related,established counter packets 2478550 bytes 1594117809 accept
		ip protocol icmp icmp type destination-unreachable counter packets 0 bytes 0 accept
		ip protocol icmp icmp type time-exceeded counter packets 0 bytes 0 accept
		ip protocol icmp icmp type parameter-problem counter packets 0 bytes 0 accept
		ip protocol icmp icmp type echo-request counter packets 0 bytes 0 accept
		counter packets 22573 bytes 1360444 jump ufw-user-forward
	}

	chain ufw-after-input {
		udp dport 137 counter packets 48719 bytes 3800082 jump ufw-skip-to-policy-input
		udp dport 138 counter packets 2339 bytes 535631 jump ufw-skip-to-policy-input
		tcp dport 139 counter packets 61 bytes 2744 jump ufw-skip-to-policy-input
		tcp dport 445 counter packets 358 bytes 17012 jump ufw-skip-to-policy-input
		udp dport 67 counter packets 20400 bytes 6283200 jump ufw-skip-to-policy-input
		udp dport 68 counter packets 0 bytes 0 jump ufw-skip-to-policy-input
		fib daddr type broadcast counter packets 128166 bytes 48443375 jump ufw-skip-to-policy-input
	}

	chain ufw-after-output {
	}

	chain ufw-after-forward {
	}

	chain ufw-after-logging-input {
		limit rate 3/minute burst 10 packets counter packets 21789 bytes 985075 log prefix "[UFW BLOCK] "
	}

	chain ufw-after-logging-output {
		limit rate 3/minute burst 10 packets counter packets 21789 bytes 7432709 log prefix "[UFW ALLOW] "
	}

	chain ufw-after-logging-forward {
		limit rate 3/minute burst 10 packets counter packets 4948 bytes 302768 log prefix "[UFW BLOCK] "
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
		ip protocol tcp ct state new counter packets 873451 bytes 52851877 accept
		ip protocol udp ct state new counter packets 525899 bytes 555696399 accept
	}

	chain ufw-track-forward {
	}

	chain INPUT {
		type filter hook input priority filter; policy drop;
		counter packets 192346708 bytes 232973830709 jump ufw-before-logging-input
		counter packets 192346708 bytes 232973830709 jump ufw-before-input
		counter packets 568023 bytes 99564241 jump ufw-after-input
		counter packets 367980 bytes 40482197 jump ufw-after-logging-input
		counter packets 367980 bytes 40482197 jump ufw-reject-input
		counter packets 367980 bytes 40482197 jump ufw-track-input
	}

	chain OUTPUT {
		type filter hook output priority filter; policy accept;
		counter packets 151175435 bytes 146971526756 jump ufw-before-logging-output
		counter packets 151175435 bytes 146971526756 jump ufw-before-output
		counter packets 1406461 bytes 609330353 jump ufw-after-output
		counter packets 1406461 bytes 609330353 jump ufw-after-logging-output
		counter packets 1406461 bytes 609330353 jump ufw-reject-output
		counter packets 1406461 bytes 609330353 jump ufw-track-output
	}

	chain FORWARD {
		type filter hook forward priority filter; policy drop;
		ip daddr 10.91.0.0/24 iifname "tun79" oifname "tun91" ct state related,established counter packets 0 bytes 0 accept
		ip daddr 10.88.0.0/24 iifname "tun79" oifname "tun88" ct state related,established counter packets 0 bytes 0 accept
		ip daddr 10.89.0.0/24 iifname "tun79" oifname "tun89" ct state related,established counter packets 0 bytes 0 accept
		ip saddr 10.89.0.0/24 iifname "tun89" oifname "tun79" counter packets 0 bytes 0 accept
		ip saddr 10.88.0.0/24 iifname "tun88" oifname "tun79" counter packets 0 bytes 0 accept
		ip daddr 10.92.0.0/24 iifname "tun79" oifname "tun92" ct state related,established counter packets 0 bytes 0 accept
		ip daddr 10.90.0.0/24 iifname "tun79" oifname "tun90" ct state related,established counter packets 0 bytes 0 accept
		ip saddr 10.91.0.0/24 iifname "tun91" oifname "tun79" counter packets 0 bytes 0 accept
		ip saddr 10.92.0.0/24 iifname "tun92" oifname "tun79" counter packets 0 bytes 0 accept
		ip saddr 10.90.0.0/24 iifname "tun90" oifname "tun79" counter packets 0 bytes 0 accept
		counter packets 2501123 bytes 1595478253 jump ufw-before-logging-forward
		counter packets 2501123 bytes 1595478253 jump ufw-before-forward
		counter packets 22573 bytes 1360444 jump ufw-after-forward
		counter packets 22573 bytes 1360444 jump ufw-after-logging-forward
		counter packets 22573 bytes 1360444 jump ufw-reject-forward
		counter packets 22573 bytes 1360444 jump ufw-track-forward
		iifname "wg-home" counter packets 22573 bytes 1360444 accept
		oifname "wg-home" counter packets 0 bytes 0 accept
		ip saddr 10.77.77.0/24 iifname "wg-home" oifname "tun79" counter packets 0 bytes 0 accept
		ip daddr 10.77.77.0/24 iifname "tun79" oifname "wg-home" ct state related,established counter packets 0 bytes 0 accept
	}

	chain ufw-logging-deny {
		ct state invalid limit rate 3/minute burst 10 packets counter packets 9550 bytes 551873 log prefix "[UFW AUDIT INVALID] "
		limit rate 3/minute burst 10 packets counter packets 9550 bytes 551873 log prefix "[UFW BLOCK] "
	}

	chain ufw-logging-allow {
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW ALLOW] "
	}

	chain ufw-skip-to-policy-input {
		counter packets 200043 bytes 59082044 drop
	}

	chain ufw-skip-to-policy-output {
		counter packets 0 bytes 0 accept
	}

	chain ufw-skip-to-policy-forward {
		counter packets 0 bytes 0 drop
	}

	chain ufw-not-local {
		fib daddr type local counter packets 1243236 bytes 92470402 return
		fib daddr type multicast counter packets 3484 bytes 111488 return
		fib daddr type broadcast counter packets 199590 bytes 59059636 return
		limit rate 3/minute burst 10 packets counter packets 0 bytes 0 jump ufw-logging-deny
		counter packets 0 bytes 0 drop
	}

	chain ufw-user-input {
		tcp dport 443 counter packets 842803 bytes 50018672 accept
		tcp dport 80 counter packets 35416 bytes 2051806 accept
		tcp dport 52000 counter packets 28 bytes 1456 accept
		udp dport 21195 counter packets 1 bytes 439 accept
		udp dport 21196 counter packets 1 bytes 439 accept
		tcp dport 21197 counter packets 17 bytes 872 accept
		udp dport 21198 counter packets 1 bytes 439 accept
		udp dport 21199 counter packets 1 bytes 439 accept
		udp dport 51820 counter packets 19 bytes 2723 accept
		ip saddr 91.242.163.206 udp dport 51822 counter packets 0 bytes 0 accept
	}

	chain ufw-user-output {
	}

	chain ufw-user-forward {
		iifname "tun88" oifname "tun79" counter packets 0 bytes 0 accept
		iifname "tun79" oifname "tun88" counter packets 0 bytes 0 accept
		iifname "tun89" oifname "tun79" counter packets 0 bytes 0 accept
		iifname "tun79" oifname "tun89" counter packets 0 bytes 0 accept
		iifname "tun90" oifname "tun79" counter packets 0 bytes 0 accept
		iifname "tun79" oifname "tun90" counter packets 0 bytes 0 accept
		iifname "tun91" oifname "tun79" counter packets 0 bytes 0 accept
		iifname "tun79" oifname "tun91" counter packets 0 bytes 0 accept
		iifname "tun92" oifname "tun79" counter packets 0 bytes 0 accept
		iifname "tun79" oifname "tun92" counter packets 0 bytes 0 accept
	}

	chain ufw-user-logging-input {
	}

	chain ufw-user-logging-output {
	}

	chain ufw-user-logging-forward {
	}

	chain ufw-user-limit {
		limit rate 3/minute burst 5 packets counter packets 0 bytes 0 log prefix "[UFW LIMIT BLOCK] "
		counter packets 0 bytes 0 reject
	}

	chain ufw-user-limit-accept {
		counter packets 0 bytes 0 accept
	}
}
table ip6 filter {
	chain ufw6-before-logging-input {
		ct state new limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW AUDIT] "
	}

	chain ufw6-before-logging-output {
		ct state new limit rate 3/minute burst 10 packets counter packets 0 bytes 0 log prefix "[UFW AUDIT] "
	}
```

## WireGuard summary: no keys
```text
interface: wg-home
  listen_port: 51820
  peer_count: 1

```

## Fail2Ban summary
```text
Status
|- Number of jail:	0
`- Jail list:	
```

## Docker containers
```text
docker not found.
```

## Xray config summary: sanitized
```text
config: /usr/local/etc/xray/config.json
inbounds_count: 2
inbound_1: tag=in-ru-reality-443 listen=0.0.0.0 port=443 protocol=vless network=tcp security=reality clients_count=42
  flows: xtls-rprx-vision
  reality_target: -
  reality_server_names: hometele.com.ru, www.hometele.com.ru, www.zoznam.sk
  reality_short_ids_count: 1
inbound_2: tag=local-socks-test listen=127.0.0.1 port=10808 protocol=socks network=- security=- clients_count=0
outbounds_count: 5
outbound: tag=to-azazello protocol=vless
outbound: tag=direct protocol=freedom
outbound: tag=to-czech-openvpn protocol=freedom
outbound: tag=dns-out protocol=dns
outbound: tag=block protocol=blackhole
routing_domain_strategy: IPIfNonMatch
routing_rules_count: 12
dns_servers_count: 3
```

## Nginx summary: listen/server_name only
```text
nginx version: nginx/1.24.0 (Ubuntu)

 listen 127.0.0.1:8443 ssl http2;
 listen 80;
 listen [::1]:8443 ssl http2;
 listen [::]:80;
 server_name hometele.com.ru www.hometele.com.ru;
```

## Postfix summary: selected safe settings only
```text
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, hometele.com.ru, localhost.hometele.com.ru, localhost
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
| `/usr/local/etc/xray/config.json` | regular file | root:root | 644 | 16156 | 2026-08-14 08:46:31 |
| `/etc/xray/config.json` | missing | - | - | - | - |
| `/etc/nginx` | directory | root:root | 755 | 4096 | 2026-08-20 06:10:45 |
| `/etc/fail2ban` | directory | root:root | 755 | 4096 | 2026-07-01 00:10:14 |
| `/etc/postfix` | directory | root:root | 755 | 4096 | 2026-07-03 13:53:14 |
| `/etc/dovecot` | missing | - | - | - | - |
| `/etc/cron.d/server-maintenance` | regular file | root:root | 644 | 334 | 2026-07-17 23:30:08 |
| `/opt/server-maintenance` | directory | root:root | 755 | 4096 | 2026-07-17 23:30:08 |
| `/usr/local/sbin/hometele-vpn-user` | regular file | root:root | 755 | 12322 | 2026-07-27 10:32:01 |
| `/usr/local/sbin/hometele-vpn-ssh-wrapper` | regular file | root:root | 755 | 723 | 2026-07-04 16:14:53 |
| `/usr/local/sbin/www-hometele-vpn` | missing | - | - | - | - |
| `/usr/local/bin/hometele-command-agent.py` | regular file | root:root | 755 | 7535 | 2026-07-02 22:28:04 |
| `/etc/hometele-monitor/command-agent.conf` | regular file | root:root | 600 | 290 | 2026-07-02 22:19:01 |
| `/var/lib/hometele-monitor/command-agent.since` | regular file | root:root | 644 | 48 | 2026-08-26 04:19:50 |
| `/etc/systemd/system/hometele-command-agent.service` | regular file | root:root | 644 | 263 | 2026-07-02 22:19:01 |
| `/etc/systemd/system/hometele-ai.service` | missing | - | - | - | - |
| `/root/.ssh` | directory | root:root | 700 | 4096 | 2026-07-01 00:03:00 |
| `/etc/letsencrypt` | directory | root:root | 755 | 4096 | 2026-08-25 20:42:08 |
| `/root/cert` | missing | - | - | - | - |
| `/etc/x-ui` | missing | - | - | - | - |
| `/etc/3x-ui` | missing | - | - | - | - |

## SSH keys: fingerprints only
```text
```

## Maintenance cron
```text
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Daily conditional maintenance at 03:20 Europe/Moscow
20 3 * * * root /opt/server-maintenance/conditional-maintenance.sh hometele

# Weekly package update on Sunday at 03:30 Europe/Moscow
30 3 * * 0 root /opt/server-maintenance/weekly-apt-upgrade.sh

total 20K
drwxr-xr-x 2 root root 4.0K Jul 17 23:30 .
drwxr-xr-x 5 root root 4.0K Aug  1 22:03 ..
-rwxr-xr-x 1 root root 4.0K Jul 17 23:30 conditional-maintenance.sh
-rwxr-xr-x 1 root root 2.4K Jul  4 15:46 restart-containers-and-services.sh
-rwxr-xr-x 1 root root 1.4K Jul  4 15:46 weekly-apt-upgrade.sh

total 272K
drwxr-xr-x  2 root root   4.0K Aug 26 03:20 .
drwxrwxr-x 16 root syslog 4.0K Aug 23 00:00 ..
-rw-r--r--  1 root root   4.1K Jul  5 03:30 apt-upgrade-2026-07-05.log
-rw-r--r--  1 root root   5.1K Jul 12 03:30 apt-upgrade-2026-07-12.log
-rw-r--r--  1 root root   1.4K Jul 19 03:30 apt-upgrade-2026-07-19.log
-rw-r--r--  1 root root   1.5K Jul 26 03:30 apt-upgrade-2026-07-26.log
-rw-r--r--  1 root root   1.4K Aug  2 03:30 apt-upgrade-2026-08-02.log
-rw-r--r--  1 root root   1.4K Aug  9 03:30 apt-upgrade-2026-08-09.log
-rw-r--r--  1 root root   1.4K Aug 16 03:30 apt-upgrade-2026-08-16.log
-rw-r--r--  1 root root   4.5K Aug 23 03:30 apt-upgrade-2026-08-23.log
-rw-r--r--  1 root root    149 Jul 17 23:30 conditional-hometele-2026-07-17.log
-rw-r--r--  1 root root    138 Jul 18 03:20 conditional-hometele-2026-07-18.log
-rw-r--r--  1 root root    196 Jul 19 03:20 conditional-hometele-2026-07-19.log
-rw-r--r--  1 root root    196 Jul 20 03:20 conditional-hometele-2026-07-20.log
-rw-r--r--  1 root root    196 Jul 21 03:20 conditional-hometele-2026-07-21.log
-rw-r--r--  1 root root    196 Jul 22 03:20 conditional-hometele-2026-07-22.log
-rw-r--r--  1 root root    196 Jul 23 03:20 conditional-hometele-2026-07-23.log
-rw-r--r--  1 root root    196 Jul 24 03:20 conditional-hometele-2026-07-24.log
-rw-r--r--  1 root root    196 Jul 25 03:20 conditional-hometele-2026-07-25.log
-rw-r--r--  1 root root    806 Jul 26 03:20 conditional-hometele-2026-07-26.log
-rw-r--r--  1 root root    806 Jul 27 03:20 conditional-hometele-2026-07-27.log
-rw-r--r--  1 root root    806 Jul 28 03:20 conditional-hometele-2026-07-28.log
-rw-r--r--  1 root root   2.2K Jul 29 03:20 conditional-hometele-2026-07-29.log
-rw-r--r--  1 root root   2.2K Jul 30 03:20 conditional-hometele-2026-07-30.log
-rw-r--r--  1 root root   2.2K Jul 31 03:20 conditional-hometele-2026-07-31.log
-rw-r--r--  1 root root   2.2K Aug  1 03:20 conditional-hometele-2026-08-01.log
-rw-r--r--  1 root root   2.2K Aug  2 03:20 conditional-hometele-2026-08-02.log
-rw-r--r--  1 root root   2.2K Aug  3 03:20 conditional-hometele-2026-08-03.log
-rw-r--r--  1 root root   2.2K Aug  4 03:20 conditional-hometele-2026-08-04.log
-rw-r--r--  1 root root   2.2K Aug  5 03:20 conditional-hometele-2026-08-05.log
-rw-r--r--  1 root root   2.2K Aug  6 03:20 conditional-hometele-2026-08-06.log
-rw-r--r--  1 root root   2.2K Aug  7 03:20 conditional-hometele-2026-08-07.log
-rw-r--r--  1 root root    138 Aug  8 03:20 conditional-hometele-2026-08-08.log
-rw-r--r--  1 root root    196 Aug  9 03:20 conditional-hometele-2026-08-09.log
-rw-r--r--  1 root root    196 Aug 10 03:20 conditional-hometele-2026-08-10.log
-rw-r--r--  1 root root    196 Aug 11 03:20 conditional-hometele-2026-08-11.log
-rw-r--r--  1 root root   2.1K Aug 12 03:20 conditional-hometele-2026-08-12.log
-rw-r--r--  1 root root   2.1K Aug 13 03:20 conditional-hometele-2026-08-13.log
-rw-r--r--  1 root root   2.1K Aug 14 03:20 conditional-hometele-2026-08-14.log
-rw-r--r--  1 root root   2.1K Aug 15 03:20 conditional-hometele-2026-08-15.log
-rw-r--r--  1 root root   2.1K Aug 16 03:20 conditional-hometele-2026-08-16.log
-rw-r--r--  1 root root   2.1K Aug 17 03:20 conditional-hometele-2026-08-17.log
-rw-r--r--  1 root root   2.1K Aug 18 03:20 conditional-hometele-2026-08-18.log
-rw-r--r--  1 root root   2.1K Aug 19 03:20 conditional-hometele-2026-08-19.log
-rw-r--r--  1 root root   2.1K Aug 20 03:20 conditional-hometele-2026-08-20.log
-rw-r--r--  1 root root    138 Aug 21 03:20 conditional-hometele-2026-08-21.log
-rw-r--r--  1 root root    196 Aug 22 03:20 conditional-hometele-2026-08-22.log
-rw-r--r--  1 root root    196 Aug 23 03:20 conditional-hometele-2026-08-23.log
-rw-r--r--  1 root root    196 Aug 24 03:20 conditional-hometele-2026-08-24.log
-rw-r--r--  1 root root    196 Aug 25 03:20 conditional-hometele-2026-08-25.log
-rw-r--r--  1 root root    196 Aug 26 03:20 conditional-hometele-2026-08-26.log
-rw-r--r--  1 root root   2.4K Jul  4 15:47 restart-2026-07-04.log
-rw-r--r--  1 root root   2.4K Jul  5 03:00 restart-2026-07-05.log
-rw-r--r--  1 root root   2.4K Jul  6 03:00 restart-2026-07-06.log
-rw-r--r--  1 root root   2.4K Jul  7 03:00 restart-2026-07-07.log
-rw-r--r--  1 root root   2.5K Jul  8 03:00 restart-2026-07-08.log
-rw-r--r--  1 root root   2.5K Jul  9 03:00 restart-2026-07-09.log
-rw-r--r--  1 root root   2.5K Jul 10 03:00 restart-2026-07-10.log
-rw-r--r--  1 root root   2.5K Jul 11 03:00 restart-2026-07-11.log
-rw-r--r--  1 root root   2.5K Jul 12 03:00 restart-2026-07-12.log
-rw-r--r--  1 root root   2.5K Jul 13 03:00 restart-2026-07-13.log
-rw-r--r--  1 root root   2.5K Jul 14 03:00 restart-2026-07-14.log
-rw-r--r--  1 root root   2.4K Jul 15 03:00 restart-2026-07-15.log
-rw-r--r--  1 root root   2.4K Jul 16 03:00 restart-2026-07-16.log
-rw-r--r--  1 root root   2.4K Jul 17 03:00 restart-2026-07-17.log
```

## Reboot required marker
```text
reboot_required: no
```
