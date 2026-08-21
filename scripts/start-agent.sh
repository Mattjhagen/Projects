#!/usr/bin/env bash
set -euo pipefail

config_file="${AGENT_CONFIG_FILE:-$HOME/.config/projects-agent.env}"
[[ -r "$config_file" ]] || { echo "Missing readable config: $config_file" >&2; exit 1; }
# shellcheck disable=SC1090
source "$config_file"

: "${AGENT_ID:?AGENT_ID is required}"
: "${PROJECT_DIR:?PROJECT_DIR is required}"

report_script="$PROJECT_DIR/scripts/agent-report.sh"
printf '%s\n' 'Interactive OpenCode session started. The agent must publish a structured report before exiting.' |
  "$report_script" STATUS running 'Interactive agent session is running'

cd "$PROJECT_DIR"
set +e
opencode
opencode_status="$?"
set -e

latest_report="$PROJECT_DIR/.agent-state/$AGENT_ID/latest.md"
if [[ "$opencode_status" -ne 0 ]]; then
  printf '%s\n' "Interactive OpenCode exited with status $opencode_status." |
    "$report_script" BLOCKED failed 'Interactive agent session failed'
elif grep -Fq 'State: running' "$latest_report"; then
  printf '%s\n' 'Interactive session ended without a structured final agent report.' |
    "$report_script" STATUS needs-review 'Interactive session ended; report needs review'
fi

exit "$opencode_status"
