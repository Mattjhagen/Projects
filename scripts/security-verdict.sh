#!/usr/bin/env bash
set -euo pipefail

pull_request="${1:?Usage: security-verdict.sh PR_NUMBER pass|fail SUMMARY}"
verdict="${2:?Usage: security-verdict.sh PR_NUMBER pass|fail SUMMARY}"
summary="${3:?Usage: security-verdict.sh PR_NUMBER pass|fail SUMMARY}"
config_file="${AGENT_CONFIG_FILE:-$HOME/.config/projects-agent.env}"

[[ -r "$config_file" ]] || { echo "Missing readable config: $config_file" >&2; exit 1; }
# shellcheck disable=SC1090
source "$config_file"

: "${AGENT_ROLE:?AGENT_ROLE is required}"
: "${AGENT_ID:?AGENT_ID is required}"
: "${REPOSITORY:?REPOSITORY is required}"
: "${PROJECT_DIR:?PROJECT_DIR is required}"

[[ "$AGENT_ROLE:$AGENT_ID" == "security:security-r410" ]] || {
  echo "Security verdicts may only be published by the R410 security host" >&2
  exit 1
}

case "$verdict" in
  pass) status_state="success"; review_state="approved" ;;
  fail) status_state="failure"; review_state="changes-required" ;;
  *) echo "Verdict must be pass or fail" >&2; exit 1 ;;
esac

details="$(cat)"
head_sha="$(gh pr view "$pull_request" --repo "$REPOSITORY" --json headRefOid --jq '.headRefOid')"
pr_url="$(gh pr view "$pull_request" --repo "$REPOSITORY" --json url --jq '.url')"
pr_state="$(gh pr view "$pull_request" --repo "$REPOSITORY" --json state --jq '.state')"
status_description="${summary:0:140}"

[[ "$pr_state" == "OPEN" ]] || { echo "Pull request #$pull_request is not open" >&2; exit 1; }

comment="[$AGENT_ID] REVIEW

Pull request: #$pull_request
Verdict: $review_state
Reviewed commit: $head_sha
Summary: $summary

Evidence:
$details"

gh pr comment "$pull_request" --repo "$REPOSITORY" --body "$comment"
gh api --method POST "repos/$REPOSITORY/statuses/$head_sha" \
  -f state="$status_state" -f context='agent/security-review' \
  -f description="$status_description" -f target_url="$pr_url" >/dev/null

printf '%s\n' "$details" |
  "$PROJECT_DIR/scripts/agent-report.sh" REVIEW "$review_state" \
  "$summary" "$pull_request" "$pr_url"

echo "Published $verdict security verdict for PR #$pull_request at $head_sha"
