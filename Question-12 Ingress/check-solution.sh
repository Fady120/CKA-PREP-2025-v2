#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get service echo-service -n echo-sound
check_exists kubectl get ingress echo -n echo-sound

check_eq "$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.type}' 2>/dev/null || true)" "NodePort" "echo-service is NodePort"
check_eq "$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || true)" "8080" "Service port is 8080"
check_eq "$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null || true)" "8080" "Target port is 8080"

np="$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || true)"
check_regex "$np" '^[0-9]+$' "NodePort is assigned"

check_eq "$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || true)" "example.org" "Ingress host is example.org"
check_eq "$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null || true)" "/echo" "Ingress path is /echo"
check_eq "$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].pathType}' 2>/dev/null || true)" "Prefix" "Ingress pathType is Prefix"
check_eq "$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || true)" "echo-service" "Ingress backend is echo-service"
check_eq "$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null || true)" "8080" "Ingress backend port is 8080"

finish
