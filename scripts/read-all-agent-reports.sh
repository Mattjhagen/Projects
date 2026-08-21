#!/usr/bin/env bash
set -euo pipefail

hosts=(agent-pm agent-dev agent-security)

for host in "${hosts[@]}"; do
  printf '\n===== %s =====\n' "$host"
  if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" \
    'cd /home/matt/Projects && scripts/show-agent-report.sh'; then
    echo "Unable to read report from $host" >&2
  fi
done
