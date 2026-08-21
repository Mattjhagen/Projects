#!/usr/bin/env bash
set -euo pipefail

config_file="${AGENT_CONFIG_FILE:-$HOME/.config/projects-agent.env}"
[[ -r "$config_file" ]] || { echo "Missing readable config: $config_file" >&2; exit 1; }
# shellcheck disable=SC1090
source "$config_file"

: "${AGENT_ID:?AGENT_ID is required}"
: "${PROJECT_DIR:?PROJECT_DIR is required}"
report="$PROJECT_DIR/.agent-state/$AGENT_ID/latest.md"

if [[ ! -r "$report" ]]; then
  echo "No report has been published by $AGENT_ID"
  exit 0
fi

cat "$report"
