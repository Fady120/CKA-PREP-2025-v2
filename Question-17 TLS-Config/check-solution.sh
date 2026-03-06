#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl
need_cmd curl

cm_name="nginx-config"
ns="nginx-static"
svc="nginx-service"

check_exists kubectl get configmap "$cm_name" -n "$ns"
check_exists kubectl get service "$svc" -n "$ns"

cm_dump="$(kubectl get configmap "$cm_name" -n "$ns" -o yaml 2>/dev/null || true)"
if grep -q 'TLSv1.3' <<<"$cm_dump"; then
  pass "ConfigMap contains TLSv1.3"
else
  fail "ConfigMap should contain TLSv1.3"
fi

if grep -q 'TLSv1.2' <<<"$cm_dump"; then
  fail "ConfigMap should not contain TLSv1.2"
else
  pass "ConfigMap no longer contains TLSv1.2"
fi

svc_ip="$(kubectl get svc "$svc" -n "$ns" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"
check_regex "$svc_ip" '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' "Service has a cluster IP"

if grep -Eq "[[:space:]]ckaquestion\.k8s\.local([[:space:]]|$)" /etc/hosts && grep -Eq "^$svc_ip[[:space:]].*ckaquestion\.k8s\.local([[:space:]]|$)" /etc/hosts; then
  pass "/etc/hosts maps ckaquestion.k8s.local to service IP"
else
  fail "/etc/hosts should map ckaquestion.k8s.local to $svc_ip"
fi

ready="$(kubectl get deployment nginx-static -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
check_regex "$ready" '^[1-9][0-9]*$' "nginx-static deployment has ready replicas"

if curl -skv --tls-max 1.2 https://ckaquestion.k8s.local >/dev/null 2>&1; then
  fail "TLS 1.2 connection should fail"
else
  pass "TLS 1.2 connection fails as expected"
fi

if curl -skv --tlsv1.3 https://ckaquestion.k8s.local >/dev/null 2>&1; then
  pass "TLS 1.3 connection succeeds"
else
  fail "TLS 1.3 connection should succeed"
fi

finish
