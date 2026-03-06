#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get pvc mariadb -n mariadb
check_exists kubectl get deployment mariadb -n mariadb

pvc_sc="$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.storageClassName}' 2>/dev/null || true)"
[[ -z "$pvc_sc" ]] && pass "PVC mariadb has no storageClassName" || fail "PVC mariadb should not set storageClassName (got: $pvc_sc)"

check_eq "$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null || true)" "ReadWriteOnce" "PVC access mode is ReadWriteOnce"
check_eq "$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null || true)" "250Mi" "PVC requested storage is 250Mi"
check_eq "$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}' 2>/dev/null || true)" "Bound" "PVC is Bound"
check_eq "$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.volumeName}' 2>/dev/null || true)" "mariadb-pv" "PVC is bound to mariadb-pv"

check_eq "$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null || true)" "mariadb" "Deployment uses PVC mariadb"
ready="$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
check_regex "$ready" '^[1-9][0-9]*$' "Deployment has ready replicas"

finish
