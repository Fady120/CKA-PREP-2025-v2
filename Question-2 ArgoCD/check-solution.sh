#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl
need_cmd helm

check_exists kubectl get namespace argocd

repo_url="$(helm repo list 2>/dev/null | awk '$1=="argocd"{print $2}')"
check_eq "$repo_url" "https://argoproj.github.io/argo-helm" "Helm repo argocd is configured correctly"

file="/root/argo-helm.yaml"
[[ -f "$file" ]] && pass "$file exists" || fail "$file exists"

check_file_contains "$file" '^namespace: argocd$' "Rendered manifest targets namespace argocd"
check_file_contains "$file" 'helm\.sh/chart: argo-cd-7\.7\.3' "Rendered manifest is chart version 7.7.3"

if [[ -f "$file" ]]; then
  if grep -Eq '^kind: CustomResourceDefinition$' "$file"; then
    fail "Rendered manifest should not include CRDs"
  else
    pass "Rendered manifest does not include CRDs"
  fi
fi

finish
