#!/usr/bin/env bash
set -euo pipefail

message_type="${1:?Usage: agent-report.sh TYPE STATE SUMMARY [ISSUE] [URL]}"
state="${2:?Usage: agent-report.sh TYPE STATE SUMMARY [ISSUE] [URL]}"
summary="${3:?Usage: agent-report.sh TYPE STATE SUMMARY [ISSUE] [URL]}"
issue="${4:-none}"
url="${5:-none}"
config_file="${AGENT_CONFIG_FILE:-$HOME/.config/projects-agent.env}"

[[ -r "$config_file" ]] || { echo "Missing readable config: $config_file" >&2; exit 1; }
# shellcheck disable=SC1090
source "$config_file"

: "${AGENT_ROLE:?AGENT_ROLE is required}"
: "${AGENT_ID:?AGENT_ID is required}"
: "${PROJECT_DIR:?PROJECT_DIR is required}"

case "$AGENT_ROLE:$AGENT_ID" in
  pm:pm-t310|developer:dev-r510|security:security-r410|pm:pm-cloud|developer:dev-cloud|security:sec-cloud) ;;
  *) echo "Invalid AGENT_ROLE and AGENT_ID pair" >&2; exit 1 ;;
esac

case "$message_type" in
  CLAIM|STATUS|QUESTION|DECISION|BLOCKED|HANDOFF|REVIEW|COMPLETE) ;;
  *) echo "Invalid message type: $message_type" >&2; exit 1 ;;
esac

details="$(cat)"
timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
report_dir="$PROJECT_DIR/.agent-state/$AGENT_ID"
history_dir="$report_dir/history"
mkdir -p "$history_dir"
chmod 700 "$PROJECT_DIR/.agent-state" "$report_dir" "$history_dir"

temporary_report="$(mktemp "$report_dir/.latest.XXXXXX")"
{
  printf '# Agent status: %s\n\n' "$AGENT_ID"
  printf -- '- Updated: %s\n' "$timestamp"
  printf -- '- Role: %s\n' "$AGENT_ROLE"
  printf -- '- Type: %s\n' "$message_type"
  printf -- '- State: %s\n' "$state"
  printf -- '- Issue: %s\n' "$issue"
  printf -- '- URL: %s\n\n' "$url"
  printf '## Summary\n\n%s\n' "$summary"
  if [[ -n "$details" ]]; then
    printf '\n## Details\n\n%s\n' "$details"
  fi
} >"$temporary_report"

chmod 600 "$temporary_report"
mv "$temporary_report" "$report_dir/latest.md"
cp "$report_dir/latest.md" "$history_dir/${timestamp//:/-}.md"
chmod 600 "$history_dir/${timestamp//:/-}.md"
printf 'Report updated: %s\n' "$report_dir/latest.md"
