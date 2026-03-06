#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get priorityclass high-priority

highest_other="$(kubectl get priorityclass -o go-template='{{range .items}}{{if and (ne .metadata.name "high-priority") (not .globalDefault)}}{{printf "%s %d\n" .metadata.name .value}}{{end}}{{end}}' 2>/dev/null | awk 'BEGIN{m=""} {if(m=="" || $2>m)m=$2} END{print m}')"
hp_value="$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null || true)"

if [[ -n "$highest_other" ]]; then
  expected=$((highest_other - 1))
  check_eq "$hp_value" "$expected" "high-priority value is one less than the highest existing user-defined class"
else
  info "Could not determine other user-defined PriorityClasses precisely"
  [[ -n "$hp_value" ]] && pass "high-priority has a value set" || fail "high-priority must have a value"
fi

check_eq "$(kubectl get deployment busybox-logger -n priority -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null || true)" "high-priority" "Deployment uses high-priority"

finish
