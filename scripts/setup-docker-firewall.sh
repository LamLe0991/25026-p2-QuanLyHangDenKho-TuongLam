#!/bin/sh
set -e

PORTS="443"

echo "[Docker Firewall] === START ==="

####################################
# Ensure iptables rules exist
####################################
echo "[Docker Firewall] Checking iptables rules..."

if ! iptables -C DOCKER-USER -m set --match-set cloudflare src \
  -p tcp --dport $PORTS -j ACCEPT 2>/dev/null; then

  echo "[Docker Firewall] Adding IPv4 iptables rule..."
  iptables -I DOCKER-USER -m set --match-set cloudflare src -p tcp --dport $PORTS -j ACCEPT
fi

if ! ip6tables -C DOCKER-USER -m set --match-set cloudflare6 src \
  -p tcp --dport $PORTS -j ACCEPT 2>/dev/null; then

  echo "[Docker Firewall] Adding IPv6 iptables rule..."
  ip6tables -I DOCKER-USER -m set --match-set cloudflare6 src -p tcp --dport $PORTS -j ACCEPT
fi

####################################
# Ensure drop rules exist
####################################
if ! iptables -C DOCKER-USER -p tcp --dport $PORTS -j DROP 2>/dev/null; then
  echo "[Docker Firewall] Adding IPv4 iptables DROP rule..."
  iptables -A DOCKER-USER -p tcp --dport $PORTS -j DROP
fi

if ! ip6tables -C DOCKER-USER -p tcp --dport $PORTS -j DROP 2>/dev/null; then
  echo "[Docker Firewall] Adding IPv6 iptables DROP rule..."
  ip6tables -A DOCKER-USER -p tcp --dport $PORTS -j DROP
fi

####################################
# Restart docker safely
####################################
if command -v docker >/dev/null 2>&1; then
  echo "[Docker Firewall] Restarting docker..."
  systemctl restart docker || service docker restart
else
  echo "[Docker Firewall] Docker not found. Skipping restart."
fi

echo "[Docker Firewall] === DONE ==="
