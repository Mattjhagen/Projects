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

case "$AGENT_ROLE:$AGENT_ID" in
  pm:pm-t310|developer:dev-r510|security:security-r410) ;;
  *) echo "Invalid AGENT_ROLE and AGENT_ID pair" >&2; exit 1 ;;
esac

for dependency in git gh opencode; do
  command -v "$dependency" >/dev/null || { echo "Missing dependency: $dependency" >&2; exit 1; }
done

[[ -d "$PROJECT_DIR/.git" ]] || { echo "Not a Git repository: $PROJECT_DIR" >&2; exit 1; }

gh auth status >/dev/null
gh repo view "$REPOSITORY" >/dev/null

if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]]; then
  echo "Worktree is not clean: $PROJECT_DIR" >&2
  exit 1
fi

echo "identity=$AGENT_ID"
echo "role=$AGENT_ROLE"
echo "repository=$REPOSITORY"
echo "branch=$(git -C "$PROJECT_DIR" branch --show-current)"
echo "opencode=$(opencode --version)"
echo "health=ok"
