#!/usr/bin/env bash
set -uo pipefail

FAILURES=0

pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; FAILURES=$((FAILURES+1)); }
info() { printf 'INFO: %s\n' "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 2; }
}

check_eq() {
  local got="$1" expected="$2" msg="$3"
  if [[ "$got" == "$expected" ]]; then
    pass "$msg"
  else
    fail "$msg (expected: $expected, got: ${got:-<empty>})"
  fi
}

check_regex() {
  local got="$1" regex="$2" msg="$3"
  if [[ "$got" =~ $regex ]]; then
    pass "$msg"
  else
    fail "$msg (value: ${got:-<empty>})"
  fi
}

check_file_contains() {
  local file="$1" regex="$2" msg="$3"
  if [[ -f "$file" ]] && grep -Eq "$regex" "$file"; then
    pass "$msg"
  else
    fail "$msg"
  fi
}

check_exists() {
  if "$@" >/dev/null 2>&1; then
    pass "$*"
  else
    fail "$*"
  fi
}

finish() {
  if (( FAILURES == 0 )); then
    echo
    echo "OVERALL RESULT: PASS"
    exit 0
  else
    echo
    echo "OVERALL RESULT: FAIL ($FAILURES checks failed)"
    exit 1
  fi
}
