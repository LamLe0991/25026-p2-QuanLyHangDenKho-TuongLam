#!/bin/sh
set -e

CF_IPV4_URL="https://www.cloudflare.com/ips-v4"
CF_IPV6_URL="https://www.cloudflare.com/ips-v6"

IPSET_V4="cloudflare"
IPSET_V6="cloudflare6"

PORTS="80,443"

echo "[Cloudflare Firewall] === START ==="

####################################
# 1. Check ipset installed
####################################
if ! command -v ipset >/dev/null 2>&1; then
  echo "[Cloudflare Firewall] ipset not found. Installing..."
  apt update
  apt install -y ipset
fi

####################################
# 2. Create ipset if not exists
####################################
if ! ipset list "$IPSET_V4" >/dev/null 2>&1; then
  echo "[Cloudflare Firewall] Creating IPv4 ipset..."
  ipset create "$IPSET_V4" hash:net
fi

if ! ipset list "$IPSET_V6" >/dev/null 2>&1; then
  echo "[Cloudflare Firewall] Creating IPv6 ipset..."
  ipset create "$IPSET_V6" hash:net family inet6
fi

####################################
# 3. Update ipset entries (no duplicates)
####################################
echo "[Cloudflare Firewall] Updating Cloudflare IPv4 ranges..."

curl -s $CF_IPV4_URL | while read -r ip; do
  ipset test "$IPSET_V4" "$ip" >/dev/null 2>&1 || ipset add "$IPSET_V4" "$ip"
done

echo "[Cloudflare Firewall] Updating Cloudflare IPv6 ranges..."

curl -s $CF_IPV6_URL | while read -r ip; do
  ipset test "$IPSET_V6" "$ip" >/dev/null 2>&1 || ipset add "$IPSET_V6" "$ip"
done

####################################
# 4. Ensure iptables rules exist
####################################
echo "[Cloudflare Firewall] Checking iptables rules..."

if ! iptables -C INPUT -p tcp -m multiport --dports $PORTS \
  -m set --match-set "$IPSET_V4" src -j ACCEPT 2>/dev/null; then

  echo "[Cloudflare Firewall] Adding IPv4 iptables rule..."
  iptables -I INPUT -p tcp -m multiport --dports $PORTS \
    -m set --match-set "$IPSET_V4" src -j ACCEPT
fi


if ! ip6tables -C INPUT -p tcp -m multiport --dports $PORTS \
  -m set --match-set "$IPSET_V6" src -j ACCEPT 2>/dev/null; then

  echo "[Cloudflare Firewall] Adding IPv6 iptables rule..."
  ip6tables -I INPUT -p tcp -m multiport --dports $PORTS \
    -m set --match-set "$IPSET_V6" src -j ACCEPT
fi

####################################
# 5. Ensure drop rules exist
####################################
echo "[Cloudflare Firewall] Checking drop rules..."

if ! iptables -C INPUT -p tcp -m multiport --dports $PORTS -j DROP 2>/dev/null; then
  echo "[Cloudflare Firewall] Adding IPv4 iptables DROP rule..."
  iptables -A INPUT -p tcp -m multiport --dports $PORTS -j DROP
fi

if ! ip6tables -C INPUT -p tcp -m multiport --dports $PORTS -j DROP 2>/dev/null; then
  echo "[Cloudflare Firewall] Adding IPv6 iptables DROP rule..."
  ip6tables -A INPUT -p tcp -m multiport --dports $PORTS -j DROP
fi

####################################
# 6. Restart docker safely
####################################
if command -v docker >/dev/null 2>&1; then
  echo "[Cloudflare Firewall] Restarting docker..."
  systemctl restart docker || service docker restart
else
  echo "[Cloudflare Firewall] Docker not found. Skipping restart."
fi

echo "[Cloudflare Firewall] === DONE ==="

# To check ipset
# sudo ipset list cloudflare
# sudo ipset list cloudflare6

# To check iptables
# sudo iptables -L | grep cloudflare
# sudo ip6tables -L | grep cloudflare6
