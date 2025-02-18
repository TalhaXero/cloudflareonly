#!/bin/bash

# Flush existing rules
iptables -F
iptables -X
iptables -Z
ip6tables -F
ip6tables -X
ip6tables -Z

# Default policy: Block all incoming and forwarding traffic
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# Allow loopback interface
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Open ports 33658 and 5258 for ALL IPs
iptables -A INPUT -p tcp --dport 33658 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 33658 -j ACCEPT
iptables -A INPUT -p tcp --dport 5258 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 5258 -j ACCEPT
iptables -A INPUT -p tcp --dport 887 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 887 -j ACCEPT
# Fetch Cloudflare IPv4 and IPv6 addresses
CLOUDFLARE_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CLOUDFLARE_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

# Allow only specific ports for Cloudflare IPv4 addresses
for ip in $CLOUDFLARE_IPV4; do
    iptables -A INPUT -p tcp -s $ip --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp -s $ip --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp -s $ip --dport 22 -j ACCEPT
done

# Allow only specific ports for Cloudflare IPv6 addresses
for ip in $CLOUDFLARE_IPV6; do
    ip6tables -A INPUT -p tcp -s $ip --dport 80 -j ACCEPT
    ip6tables -A INPUT -p tcp -s $ip --dport 443 -j ACCEPT
    ip6tables -A INPUT -p tcp -s $ip --dport 22 -j ACCEPT
done

# Log and drop all other traffic
iptables -A INPUT -j LOG --log-prefix "Blocked: " --log-level 4
iptables -A INPUT -j DROP
ip6tables -A INPUT -j LOG --log-prefix "Blocked: " --log-level 4
ip6tables -A INPUT -j DROP

echo "Firewall rules updated. Ports 33658 & 5258 are open for all. SSH (22) is restricted to Cloudflare."
