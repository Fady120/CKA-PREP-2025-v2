#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get deployment nodeport-deployment -n relative
check_exists kubectl get service nodeport-service -n relative

check_eq "$(kubectl get deployment nodeport-deployment -n relative -o jsonpath='{.spec.template.spec.containers[?(@.name=="nginx")].ports[0].containerPort}' 2>/dev/null || true)" "80" "nginx containerPort is 80"
check_eq "$(kubectl get deployment nodeport-deployment -n relative -o jsonpath='{.spec.template.spec.containers[?(@.name=="nginx")].ports[0].name}' 2>/dev/null || true)" "http" "Container port name is http"
check_eq "$(kubectl get deployment nodeport-deployment -n relative -o jsonpath='{.spec.template.spec.containers[?(@.name=="nginx")].ports[0].protocol}' 2>/dev/null || true)" "TCP" "Container port protocol is TCP"

check_eq "$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.type}' 2>/dev/null || true)" "NodePort" "Service type is NodePort"
check_eq "$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || true)" "80" "Service port is 80"
check_eq "$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null || true)" "80" "Service targetPort is 80"
check_eq "$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].protocol}' 2>/dev/null || true)" "TCP" "Service protocol is TCP"
check_eq "$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || true)" "30080" "NodePort is 30080"

selector="$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.selector.app}' 2>/dev/null || true)"
check_eq "$selector" "nodeport-deployment" "Service selector targets app=nodeport-deployment"

finish
