#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get deployment wordpress

replicas="$(kubectl get deployment wordpress -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
check_eq "$replicas" "3" "Deployment scaled back to 3 replicas"

base_cpu_req="$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)"
base_mem_req="$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)"
base_cpu_lim="$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)"
base_mem_lim="$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)"

for label in base_cpu_req base_mem_req base_cpu_lim base_mem_lim; do
  val="${!label}"
  [[ -n "$val" ]] && pass "Main container has $label set" || fail "Main container missing $label"
done

report="$(kubectl get deployment wordpress -o go-template='{{range .spec.template.spec.containers}}{{printf "C:%s|%s|%s|%s|%s\n" .name .resources.requests.cpu .resources.requests.memory .resources.limits.cpu .resources.limits.memory}}{{end}}{{range .spec.template.spec.initContainers}}{{printf "I:%s|%s|%s|%s|%s\n" .name .resources.requests.cpu .resources.requests.memory .resources.limits.cpu .resources.limits.memory}}{{end}}' 2>/dev/null || true)"

if [[ -z "$report" ]]; then
  fail "Unable to read container resource settings"
else
  while IFS='|' read -r cname cpu_req mem_req cpu_lim mem_lim; do
    [[ -z "$cname" ]] && continue
    check_eq "$cpu_req" "$base_cpu_req" "$cname CPU request matches the base container"
    check_eq "$mem_req" "$base_mem_req" "$cname memory request matches the base container"
    check_eq "$cpu_lim" "$base_cpu_lim" "$cname CPU limit matches the base container"
    check_eq "$mem_lim" "$base_mem_lim" "$cname memory limit matches the base container"
  done <<< "$report"
fi

ready="$(kubectl get deployment wordpress -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
check_eq "$ready" "3" "All 3 replicas are ready"

finish
