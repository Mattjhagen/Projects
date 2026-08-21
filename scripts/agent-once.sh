#!/usr/bin/env bash
set -euo pipefail

config_file="${AGENT_CONFIG_FILE:-$HOME/.config/projects-agent.env}"
[[ -r "$config_file" ]] || { echo "Missing readable config: $config_file" >&2; exit 1; }

# shellcheck disable=SC1090
source "$config_file"

: "${AGENT_ROLE:?AGENT_ROLE is required}"
: "${AGENT_ID:?AGENT_ID is required}"
: "${REPOSITORY:?REPOSITORY is required}"
: "${PROJECT_DIR:?PROJECT_DIR is required}"
automation_enabled="${AUTOMATION_ENABLED:-false}"

case "$AGENT_ROLE:$AGENT_ID" in
  pm:pm-t310|developer:dev-r510|security:security-r410) ;;
  *) echo "Invalid AGENT_ROLE and AGENT_ID pair" >&2; exit 1 ;;
esac

issue="$(gh issue list --repo "$REPOSITORY" --state open \
  --label "agent:$AGENT_ROLE" --label "status:ready" \
  --limit 1 --json number --jq '.[0].number // empty')"

if [[ -z "$issue" ]]; then
  echo "No ready issue for agent:$AGENT_ROLE"
  exit 0
fi

echo "Next ready issue: #$issue"

if [[ "$automation_enabled" != "true" ]]; then
  echo "Automation is disabled; inspect and claim the issue manually."
  exit 0
fi

"$PROJECT_DIR/scripts/claim-issue.sh" "$issue" "$AGENT_ROLE" "$AGENT_ID" "$REPOSITORY"
issue_url="$(gh issue view "$issue" --repo "$REPOSITORY" --json url --jq '.url')"

case "$AGENT_ROLE" in
  pm) role_file="project-manager" ;;
  developer) role_file="senior-developer" ;;
  security) role_file="cybersecurity-expert" ;;
esac

prompt="You are [$AGENT_ID], the $AGENT_ROLE agent. Read AGENTS.md and agents/$role_file.md. Work only on $issue_url. Follow the repository message protocol. Do not merge or deploy."

cd "$PROJECT_DIR"
opencode run "$prompt"
