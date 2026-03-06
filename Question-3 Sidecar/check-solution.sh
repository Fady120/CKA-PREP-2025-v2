#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get deployment wordpress

check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.volumes[?(@.name=="log")].name}' 2>/dev/null || true)" "log" "Volume log exists"
check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.volumes[?(@.name=="log")].emptyDir}' 2>/dev/null || true)" "map[]" "Volume log is emptyDir"

check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].image}' 2>/dev/null || true)" "busybox:stable" "Sidecar image is busybox:stable"
check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].command[0]}' 2>/dev/null || true)" "/bin/sh" "Sidecar command[0] is /bin/sh"
check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].command[1]}' 2>/dev/null || true)" "-c" "Sidecar command[1] is -c"
check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].command[2]}' 2>/dev/null || true)" "tail -f /var/log/wordpress.log" "Sidecar tails wordpress.log"
check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.name=="log")].mountPath}' 2>/dev/null || true)" "/var/log" "Sidecar mounts /var/log"
check_eq "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="wordpress")].volumeMounts[?(@.name=="log")].mountPath}' 2>/dev/null || true)" "/var/log" "Main container mounts /var/log"

finish
