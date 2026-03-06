#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/common.sh"
need_cmd kubectl

check_exists kubectl get storageclass local-storage

check_eq "$(kubectl get sc local-storage -o jsonpath='{.provisioner}' 2>/dev/null || true)" "rancher.io/local-path" "Provisioner is rancher.io/local-path"
check_eq "$(kubectl get sc local-storage -o jsonpath='{.volumeBindingMode}' 2>/dev/null || true)" "WaitForFirstConsumer" "VolumeBindingMode is WaitForFirstConsumer"
check_eq "$(kubectl get sc local-storage -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null || true)" "true" "local-storage is default"

defaults="$(kubectl get sc -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}' 2>/dev/null | awk -F= '$2=="true"{print $1}')"
default_count="$(wc -w <<<"$defaults" | tr -d ' ')"
if [[ "$default_count" == "1" && "$defaults" == "local-storage" ]]; then
  pass "local-storage is the only default StorageClass"
else
  fail "local-storage should be the only default StorageClass (current: ${defaults:-none})"
fi

finish
