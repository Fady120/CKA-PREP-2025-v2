#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd systemctl
need_cmd sysctl

if systemctl is-enabled cri-docker.service >/dev/null 2>&1; then
  pass "cri-docker.service is enabled"
else
  fail "cri-docker.service should be enabled"
fi

if systemctl is-active cri-docker.service >/dev/null 2>&1; then
  pass "cri-docker.service is active"
else
  fail "cri-docker.service should be active"
fi

pkg_ok=0
dpkg -s cri-dockerd >/dev/null 2>&1 && pkg_ok=1
if (( pkg_ok == 1 )); then
  pass "cri-dockerd package is installed"
else
  fail "cri-dockerd package is not installed"
fi

check_eq "$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || true)" "1" "net.bridge.bridge-nf-call-iptables is 1"
check_eq "$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || true)" "1" "net.ipv6.conf.all.forwarding is 1"
check_eq "$(sysctl -n net.ipv4.ip_forward 2>/dev/null || true)" "1" "net.ipv4.ip_forward is 1"
check_eq "$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || true)" "131072" "net.netfilter.nf_conntrack_max is 131072"

if grep -Eq '^\s*net\.bridge\.bridge-nf-call-iptables\s*=\s*1\s*$' /etc/sysctl.d/*.conf 2>/dev/null; then pass "bridge-nf-call-iptables persisted"; else fail "bridge-nf-call-iptables should be persisted"; fi
if grep -Eq '^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1\s*$' /etc/sysctl.d/*.conf 2>/dev/null; then pass "ipv6 forwarding persisted"; else fail "ipv6 forwarding should be persisted"; fi
if grep -Eq '^\s*net\.ipv4\.ip_forward\s*=\s*1\s*$' /etc/sysctl.d/*.conf 2>/dev/null; then pass "ipv4 forwarding persisted"; else fail "ipv4 forwarding should be persisted"; fi
if grep -Eq '^\s*net\.netfilter\.nf_conntrack_max\s*=\s*131072\s*$' /etc/sysctl.d/*.conf 2>/dev/null; then pass "nf_conntrack_max persisted"; else fail "nf_conntrack_max should be persisted"; fi

finish
