#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

policies="$(kubectl get networkpolicy -A --no-headers 2>/dev/null | wc -l | tr -d ' ')"
if (( policies >= 1 )); then
  pass "At least one NetworkPolicy exists"
else
  fail "No NetworkPolicy found"
fi

np_data="$(kubectl get networkpolicy -n backend -o go-template='{{range .items}}{{printf "%s|%s|%s|%s\n" .metadata.name (index .spec.podSelector.matchLabels "app") (index (index .spec.ingress 0).from 0).namespaceSelector.matchLabels "kubernetes.io/metadata.name" (index (index (index .spec.ingress 0).from 1).podSelector.matchLabels "app")}}{{end}}' 2>/dev/null || true)"
if [[ -n "$np_data" ]]; then
  pass "Backend namespace has a NetworkPolicy"
else
  fail "Expected a NetworkPolicy in backend namespace"
fi

matched=0
while IFS='|' read -r name app nslabel podlabel; do
  [[ -z "$name" ]] && continue
  if [[ "$app" == "backend" && "$nslabel" == "frontend" ]] || [[ "$app" == "backend" && "$podlabel" == "frontend" ]]; then
    matched=1
  fi
done <<< "$np_data"

if (( matched == 1 )); then
  pass "A least-permissive backend policy allowing frontend traffic was found"
else
  fail "Could not verify the expected frontend->backend policy"
fi

finish
