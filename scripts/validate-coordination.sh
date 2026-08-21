#!/usr/bin/env bash
set -euo pipefail

required=(
  README.md
  AGENTS.md
  agents/project-manager.md
  agents/senior-developer.md
  agents/cybersecurity-expert.md
  docs/ARCHITECTURE.md
  docs/MESSAGE_PROTOCOL.md
  docs/SECURITY_POLICY.md
  docs/RUNBOOK.md
  docs/AUTOMATED_WORKFLOW.md
  config/t310.env.example
  config/r510.env.example
  config/r410.env.example
  .github/ISSUE_TEMPLATE/agent-task.yml
  .github/pull_request_template.md
  systemd/opencode-agent.service
  systemd/opencode-agent.timer
  scripts/agent-report.sh
  scripts/show-agent-report.sh
  scripts/start-agent.sh
  scripts/read-all-agent-reports.sh
  scripts/submit-task.sh
  scripts/security-verdict.sh
)

for path in "${required[@]}"; do
  [[ -s "$path" ]] || { echo "Missing or empty required file: $path" >&2; exit 1; }
done

for script in scripts/*.sh; do
  bash -n "$script"
done

grep -Fq '[pm-t310]' AGENTS.md
grep -Fq '[dev-r510]' AGENTS.md
grep -Fq '[security-r410]' AGENTS.md

grep -Fxq 'AGENT_ROLE=pm' config/t310.env.example
grep -Fxq 'AGENT_ROLE=developer' config/r510.env.example
grep -Fxq 'AGENT_ROLE=security' config/r410.env.example

if grep -REn '100\.(65\.34\.60|103\.3\.35|123\.142\.27)' \
  --exclude-dir=.git --exclude='validate-coordination.sh' .; then
  echo "Private infrastructure address found in tracked content" >&2
  exit 1
fi

echo "Coordination files are valid"
