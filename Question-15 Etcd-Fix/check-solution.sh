#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"

manifest="/etc/kubernetes/manifests/kube-apiserver.yaml"
[[ -f "$manifest" ]] && pass "$manifest exists" || fail "$manifest exists"

if [[ -f "$manifest" ]]; then
  if grep -q -- '--etcd-servers=https://127.0.0.1:2379' "$manifest"; then
    pass "kube-apiserver manifest points to etcd port 2379"
  else
    fail "kube-apiserver manifest should point to https://127.0.0.1:2379"
  fi
fi

if command -v kubectl >/dev/null 2>&1; then
  phase="$(kubectl -n kube-system get pod -l component=kube-apiserver -o jsonpath='{.items[0].status.phase}' 2>/dev/null || true)"
  check_eq "$phase" "Running" "kube-apiserver static pod is Running"
fi

finish
