#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get hpa apache-server -n autoscale

check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.scaleTargetRef.kind}' 2>/dev/null || true)" "Deployment" "HPA targets a Deployment"
check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null || true)" "apache-deployment" "HPA targets apache-deployment"
check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.minReplicas}' 2>/dev/null || true)" "1" "HPA minReplicas is 1"
check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || true)" "4" "HPA maxReplicas is 4"
check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.metrics[0].resource.name}' 2>/dev/null || true)" "cpu" "HPA metric is cpu"
check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.metrics[0].resource.target.type}' 2>/dev/null || true)" "Utilization" "HPA target type is Utilization"
check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null || true)" "50" "HPA target averageUtilization is 50"
check_eq "$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}' 2>/dev/null || true)" "30" "HPA downscale stabilization window is 30 seconds"

finish
