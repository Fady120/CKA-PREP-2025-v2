#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get gateway web-gateway
check_exists kubectl get httproute web-route

check_eq "$(kubectl get gateway web-gateway -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null || true)" "nginx-class" "GatewayClass is nginx-class"
check_eq "$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].hostname}' 2>/dev/null || true)" "gateway.web.k8s.local" "Gateway hostname is correct"
check_eq "$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].protocol}' 2>/dev/null || true)" "HTTPS" "Gateway listener protocol is HTTPS"
check_eq "$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].port}' 2>/dev/null || true)" "443" "Gateway listener port is 443"
check_eq "$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].tls.mode}' 2>/dev/null || true)" "Terminate" "Gateway TLS mode is Terminate"
check_eq "$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].tls.certificateRefs[0].name}' 2>/dev/null || true)" "web-tls" "Gateway uses secret web-tls"

check_eq "$(kubectl get httproute web-route -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null || true)" "web-gateway" "HTTPRoute points to web-gateway"
check_eq "$(kubectl get httproute web-route -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null || true)" "gateway.web.k8s.local" "HTTPRoute hostname is correct"
check_eq "$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].matches[0].path.type}' 2>/dev/null || true)" "PathPrefix" "HTTPRoute path match type is PathPrefix"
check_eq "$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].matches[0].path.value}' 2>/dev/null || true)" "/" "HTTPRoute path is /"
check_eq "$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null || true)" "web-service" "HTTPRoute backend service is web-service"
check_eq "$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].backendRefs[0].port}' 2>/dev/null || true)" "80" "HTTPRoute backend port is 80"

finish
