#!/bin/bash

# Flush all existing rules
iptables -F
iptables -X
iptables -Z
ip6tables -F
ip6tables -X
ip6tables -Z

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Open ports 33658, 5258, and 887 for ALL IPs (be cautious!)
iptables -A INPUT -p tcp --dport 2031 -j ACCEPT
iptables -A INPUT -p tcp --dport 5258 -j ACCEPT  # your custom SSH
iptables -A INPUT -p tcp --dport 2030 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 2031 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 5258 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 2030 -j ACCEPT

# Fetch Cloudflare IPs
CLOUDFLARE_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CLOUDFLARE_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

# Allow HTTP/HTTPS from Cloudflare IPv4
for ip in $CLOUDFLARE_IPV4; do
    iptables -A INPUT -p tcp -s $ip --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp -s $ip --dport 443 -j ACCEPT
done

# Allow HTTP/HTTPS from Cloudflare IPv6
for ip in $CLOUDFLARE_IPV6; do
    ip6tables -A INPUT -p tcp -s $ip --dport 80 -j ACCEPT
    ip6tables -A INPUT -p tcp -s $ip --dport 443 -j ACCEPT
done

# Log and drop everything else
iptables -A INPUT -j LOG --log-prefix "Blocked: " --log-level 4
iptables -A INPUT -j DROP
ip6tables -A INPUT -j LOG --log-prefix "Blocked: " --log-level 4
ip6tables -A INPUT -j DROP

echo "Firewall rules applied. Only Cloudflare can access ports 80/443. SSH is open on 5258."
