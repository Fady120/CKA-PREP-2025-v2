#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

taints="$(kubectl get node node01 -o jsonpath='{range .spec.taints[*]}{.key}={.value}:{.effect}{"\n"}{end}' 2>/dev/null || true)"
if grep -qx 'PERMISSION=granted:NoSchedule' <<<"$taints"; then
  pass "node01 has the required taint"
else
  fail "node01 should have taint PERMISSION=granted:NoSchedule"
fi

check_exists kubectl get pod nginx

check_eq "$(kubectl get pod nginx -o jsonpath='{.spec.tolerations[?(@.key=="PERMISSION")].value}' 2>/dev/null || true)" "granted" "Pod nginx tolerates value granted"
check_eq "$(kubectl get pod nginx -o jsonpath='{.spec.tolerations[?(@.key=="PERMISSION")].effect}' 2>/dev/null || true)" "NoSchedule" "Pod nginx toleration effect is NoSchedule"

node_name="$(kubectl get pod nginx -o jsonpath='{.spec.nodeName}' 2>/dev/null || true)"
check_eq "$node_name" "node01" "Pod nginx is scheduled on node01"

phase="$(kubectl get pod nginx -o jsonpath='{.status.phase}' 2>/dev/null || true)"
check_regex "$phase" '^(Running|Succeeded)$' "Pod nginx is scheduled successfully"

finish
