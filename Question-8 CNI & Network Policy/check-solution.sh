#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

# Repo notes expect Calico via tigera-operator; the uploaded PDF also points to Calico
# as the intended CNI for this question.
check_exists kubectl get namespace tigera-operator

pods_report="$(kubectl get pods -n tigera-operator --no-headers 2>/dev/null || true)"
if [[ -n "$pods_report" ]]; then
  pass "tigera-operator namespace has pods"
else
  fail "Expected Calico operator pods in tigera-operator namespace"
fi

ready_pods="$(kubectl get pods -n tigera-operator --no-headers 2>/dev/null | awk '$2 ~ /^[0-9]+\/[0-9]+$/ && $2 == $3 && $3 !~ /^0\// {c++} END{print c+0}')"
if (( ready_pods > 0 )); then
  pass "At least one tigera-operator pod is Ready"
else
  fail "No Ready pods found in tigera-operator namespace"
fi

if kubectl get ns calico-system >/dev/null 2>&1 || kubectl get ds -A | grep -qi calico; then
  pass "Calico dataplane components appear to be installed"
else
  info "calico-system namespace was not found"
  fail "Could not confirm Calico dataplane components"
fi

nodes_ready="$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 ~ /Ready/ {c++} END{print c+0}')"
if (( nodes_ready > 0 )); then
  pass "At least one node is Ready"
else
  fail "No Ready nodes found"
fi

if ls /etc/cni/net.d/* >/dev/null 2>&1; then
  if grep -Rqi 'calico' /etc/cni/net.d 2>/dev/null; then
    pass "CNI config under /etc/cni/net.d references Calico"
  else
    fail "CNI config exists, but Calico was not detected in /etc/cni/net.d"
  fi
else
  info "/etc/cni/net.d not readable from this node"
fi

finish
