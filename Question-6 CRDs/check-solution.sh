#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

resources_file="/root/resources.yaml"
subject_file="/root/subject.yaml"

[[ -f "$resources_file" ]] && pass "$resources_file exists" || fail "$resources_file exists"
[[ -f "$subject_file" ]] && pass "$subject_file exists" || fail "$subject_file exists"

if [[ -f "$resources_file" ]]; then
  live_count="$(kubectl get crd 2>/dev/null | grep -c 'cert-manager' || true)"
  file_count="$(grep -c 'cert-manager' "$resources_file" || true)"
  if (( file_count >= 1 )); then
    pass "resources.yaml contains cert-manager CRDs"
  else
    fail "resources.yaml should contain cert-manager CRDs"
  fi
  if (( live_count == file_count )); then
    pass "resources.yaml count matches live cert-manager CRDs"
  else
    info "Live cert-manager CRDs: $live_count, in file: $file_count"
    fail "resources.yaml does not match current cert-manager CRD count"
  fi
fi

if [[ -f "$subject_file" ]]; then
  if grep -qi 'subject' "$subject_file"; then
    pass "subject.yaml contains certificate.spec.subject documentation"
  else
    fail "subject.yaml should contain subject field documentation"
  fi
fi

finish
