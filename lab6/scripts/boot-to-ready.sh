#!/usr/bin/env bash
set -euo pipefail
label=${1:?Provide label}
host=${2:?Provide host}
start=${3:?Provide start epoch}
deadline=$(( $(date +%s) + 600 ))

until curl -fsS -m 3 "http://${host}/" >/dev/null 2>&1; do
  if (( $(date +%s) >= deadline )); then
    echo "Timed out waiting for http://${host}/" >&2
    exit 1
  fi
  sleep 2
done

echo "${label}: $(( $(date +%s) - start )) seconds"
