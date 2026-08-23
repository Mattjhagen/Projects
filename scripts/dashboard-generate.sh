#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/dashboard-generate.sh

Render a static HTML agent status dashboard to an untracked file.
Manual invocation only: no server, no inbound ports, no auto-refresh.

Environment overrides:
  DASHBOARD_REPO           owner/name repository to query (default Mattjhagen/Projects)
  DASHBOARD_PROJECT_DIR    repository root (default: git toplevel)
  DASHBOARD_STATE_DIR      agent-state root (default: <project>/.agent-state)
  DASHBOARD_OUTPUT         output HTML path (default: <state>/dashboard/index.html)
  DASHBOARD_REPORT_FETCH   ssh | local (default ssh; "local" reads DASHBOARD_STATE_DIR
                           directly and exists for offline testing)
  DASHBOARD_REMOTE_DIR     remote project path used over ssh (default /home/matt/Projects)
  DASHBOARD_GH_TIMEOUT     seconds allowed per GitHub call (default 10)
  DASHBOARD_SSH_TIMEOUT    seconds allowed per ssh report fetch (default 10)
  DASHBOARD_PR_LIMIT       open pull requests scanned for the security gate (default 5)

Exit codes:
  0  every source was fetched successfully
  1  one or more sources were unavailable; the dashboard still renders
     explicit unavailable/stale markers for those sources
  2  fatal error: invalid configuration or the output failed the
     forbidden-pattern gate; no dashboard is written
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) usage >&2; exit 2 ;;
esac

REPO="${DASHBOARD_REPO:-Mattjhagen/Projects}"
PROJECT_DIR="${DASHBOARD_PROJECT_DIR:-}"
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
STATE_DIR="${DASHBOARD_STATE_DIR:-$PROJECT_DIR/.agent-state}"
OUTPUT="${DASHBOARD_OUTPUT:-$STATE_DIR/dashboard/index.html}"
REPORT_FETCH="${DASHBOARD_REPORT_FETCH:-ssh}"
REMOTE_DIR="${DASHBOARD_REMOTE_DIR:-/home/matt/Projects}"
GH_TIMEOUT="${DASHBOARD_GH_TIMEOUT:-10}"
SSH_TIMEOUT="${DASHBOARD_SSH_TIMEOUT:-10}"
PR_LIMIT="${DASHBOARD_PR_LIMIT:-5}"

case "$REPORT_FETCH" in
  ssh|local) ;;
  *) echo "Invalid DASHBOARD_REPORT_FETCH: $REPORT_FETCH (expected ssh or local)" >&2; exit 2 ;;
esac
case "$GH_TIMEOUT" in ''|*[!0-9]*) echo "Invalid DASHBOARD_GH_TIMEOUT" >&2; exit 2 ;; esac
case "$SSH_TIMEOUT" in ''|*[!0-9]*) echo "Invalid DASHBOARD_SSH_TIMEOUT" >&2; exit 2 ;; esac
case "$PR_LIMIT" in ''|*[!0-9]*) echo "Invalid DASHBOARD_PR_LIMIT" >&2; exit 2 ;; esac

AGENT_IDS=(pm-t310 dev-r510 security-r410)
AGENT_ROLES=("Project Manager" "Senior Developer" "Cybersecurity Expert")
AGENT_LABELS=(agent:pm agent:developer agent:security)
AGENT_ALIASES=(agent-pm agent-dev agent-security)

failures=0
declare -a SOURCE_HEALTH=()

note_source() {
  SOURCE_HEALTH+=("$1")
}

html_escape() {
  local s="$1"
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  s=${s//\"/&quot;}
  s=${s//\'/&#39;}
  printf '%s' "$s"
}

run_timeout() {
  local secs="$1"
  shift
  timeout "$secs" "$@"
}

# Fetch the most recently updated open issue carrying a given agent label.
# Output: TSV number, title, url, updatedAt, comma-separated label names.
fetch_current_issue_tsv() {
  local label="$1" out
  out="$(run_timeout "$GH_TIMEOUT" gh issue list --repo "$REPO" --label "$label" --state open \
    --json number,title,url,updatedAt,labels --limit 50 2>/dev/null \
    | jq -r 'sort_by(.updatedAt) | reverse | .[0]
             | if . == null then empty else
                 [(.number | tostring), .title, .url, .updatedAt,
                  ([.labels[].name] | join(","))] | @tsv end')" || return 1
  [[ -n "$out" ]] || return 0
  printf '%s' "$out"
}

# Fetch open pull requests as TSV lines: number, title, url, head oid.
fetch_open_prs_tsv() {
  run_timeout "$GH_TIMEOUT" gh pr list --repo "$REPO" --state open \
    --json number,title,url,headRefOid,updatedAt --limit "$PR_LIMIT" 2>/dev/null \
    | jq -r 'sort_by(.updatedAt) | reverse
             | .[] | [(.number | tostring), .title, .url, .headRefOid] | @tsv'
}

# Fetch the combined commit status plus the agent/security-review context.
# Output: TSV overall_state, security_state
fetch_commit_status_tsv() {
  local sha="$1"
  run_timeout "$GH_TIMEOUT" gh api "repos/$REPO/commits/$sha/status" 2>/dev/null \
    | jq -r '"\(.state)\t\(([.statuses[] | select(.context == "agent/security-review")][0].state // "missing"))"'
}

fetch_report_text() {
  local id="$1" alias="$2" path text
  case "$REPORT_FETCH" in
    local)
      path="$STATE_DIR/$id/latest.md"
      [[ -r "$path" ]] || return 1
      head -c 200000 "$path"
      ;;
    ssh)
      # shellcheck disable=SC2029  # client-side expansion of REMOTE_DIR is intentional
      text="$(run_timeout "$SSH_TIMEOUT" ssh -o BatchMode=yes -o ConnectTimeout=10 "$alias" \
        "cd '$REMOTE_DIR' && scripts/show-agent-report.sh" 2>/dev/null)" || return 1
      [[ -n "$text" ]] || return 1
      case "$text" in
        "No report has been published"*) return 1 ;;
      esac
      printf '%s\n' "$text"
      ;;
  esac
}

report_field() {
  local text="$1" key="$2"
  printf '%s\n' "$text" | sed -nE "s/^-[[:space:]]*${key}:[[:space:]]*(.*)$/\1/p" | head -n 1
}

report_summary_line() {
  local text="$1"
  printf '%s\n' "$text" \
    | tr -d '\r' \
    | awk '/^## Summary[[:space:]]*$/ {flag=1; next} /^## / {flag=0} flag && /[^[:space:]]/ {print; exit}'
}

pick_prefixed_label() {
  local csv="$1" prefix="$2" entry
  IFS=',' read -ra entries <<<"$csv"
  for entry in "${entries[@]}"; do
    case "$entry" in
      "$prefix"*) printf '%s' "$entry"; return 0 ;;
    esac
  done
  printf '%s' ""
}

badge() {
  local kind="$1" text="$2" esc
  esc="$(html_escape "$text")"
  printf '<span class="badge badge-%s">%s</span>' "$kind" "$esc"
}

unavailable_badge() {
  printf '<span class="badge badge-unavailable">unavailable/stale</span>'
}

friendly_role() {
  case "$1" in
    pm) printf '%s' "Project Manager" ;;
    developer) printf '%s' "Senior Developer" ;;
    security) printf '%s' "Cybersecurity Expert" ;;
    *) printf '%s' "$1" ;;
  esac
}

handoff_issue_ref() {
  local issue="$1"
  if [[ "$issue" =~ ^[0-9]+$ ]]; then
    printf '#%s' "$issue"
  else
    printf '%s' "$issue"
  fi
}

# Forbidden-pattern categories checked over the finished document.
# Matched content is never printed; only the category is reported.
gate_scan() {
  local file="$1" pattern
  local -a patterns=(
    'ghp_[A-Za-z0-9]{20,}'
    'github_pat_[A-Za-z0-9_]{20,}'
    'AKIA[0-9A-Z]{16}'
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'xox[baprs]-[A-Za-z0-9-]{10,}'
    'Bearer [A-Za-z0-9._~+/=-]{24,}'
    '\b(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3})\b'
  )
  for pattern in "${patterns[@]}"; do
    # Never echo matching content: it may itself be the secret.
    if grep -Eq -- "$pattern" "$file"; then
      echo "Output rejected by forbidden-pattern gate" >&2
      return 1
    fi
  done
  return 0
}

OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"
chmod 700 "$OUTPUT_DIR"
TMP_OUT="$(mktemp "$OUTPUT_DIR/.dashboard.XXXXXX")"

generated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# --- GitHub source -----------------------------------------------------------

github_ok=1
declare -a GITHUB_ROWS=()
for i in "${!AGENT_IDS[@]}"; do
  id="${AGENT_IDS[$i]}"
  label="${AGENT_LABELS[$i]}"
  tsv=""
  fetch_ok=1
  if ! tsv="$(fetch_current_issue_tsv "$label")"; then
    fetch_ok=0
  fi
  if [[ "$fetch_ok" -eq 1 && -z "$tsv" ]]; then
    GITHUB_ROWS+=("<li><strong>${id}</strong>: no open ${label} issue (GitHub)</li>")
  elif [[ "$fetch_ok" -eq 1 ]]; then
    IFS=$'\t' read -r num title url updated labels <<<"$tsv"
    status_label="$(pick_prefixed_label "$labels" 'status:')"
    type_label="$(pick_prefixed_label "$labels" 'type:')"
    esc_title="$(html_escape "$title")"
    esc_status="$(html_escape "${status_label:-unknown}")"
    esc_type="$(html_escape "${type_label:-unknown}")"
    esc_updated="$(html_escape "$updated")"
    GITHUB_ROWS+=("<li><strong>${id}</strong>: <a href=\"${url}\">#${num}</a> ${esc_title} &mdash; ${esc_status} / ${esc_type}, updated ${esc_updated} (GitHub)</li>")
  else
    github_ok=0
    failures=$((failures + 1))
    GITHUB_ROWS+=("<li><strong>${id}</strong>: $(unavailable_badge) (GitHub)</li>")
  fi
done

declare -a PR_ROWS=()
prs_fetch_ok=1
prs_tsv="$(fetch_open_prs_tsv)" || prs_fetch_ok=0
if [[ "$prs_fetch_ok" -eq 1 && -z "$prs_tsv" ]]; then
  PR_ROWS+=("<tr><td colspan=\"4\">No open pull requests.</td></tr>")
elif [[ "$prs_fetch_ok" -eq 1 ]]; then
  while IFS=$'\t' read -r pr_num pr_title pr_url pr_sha; do
    [[ -n "$pr_num" ]] || continue
    status_tsv="$(fetch_commit_status_tsv "$pr_sha")" || status_tsv=""
    if [[ -n "$status_tsv" ]]; then
      IFS=$'\t' read -r overall sec <<<"$status_tsv"
      esc_overall="$(html_escape "${overall:-unknown}")"
      esc_sec="$(html_escape "${sec:-missing}")"
      esc_pr_title="$(html_escape "$pr_title")"
      PR_ROWS+=("<tr><td><a href=\"${pr_url}\">#${pr_num}</a> ${esc_pr_title}</td><td>$(html_escape "${pr_sha:0:12}")</td><td>${esc_overall}</td><td>agent/security-review: ${esc_sec}</td></tr>")
    else
      github_ok=0
      failures=$((failures + 1))
      PR_ROWS+=("<tr><td><a href=\"${pr_url}\">#${pr_num}</a></td><td>$(html_escape "${pr_sha:0:12}")</td><td colspan=\"2\">$(unavailable_badge)</td></tr>")
    fi
  done <<<"$prs_tsv"
else
  github_ok=0
  failures=$((failures + 1))
  PR_ROWS+=("<tr><td colspan=\"4\">$(unavailable_badge) (pull request statuses)</td></tr>")
fi

if ((github_ok)); then
  note_source "github: ok"
else
  note_source "github: unavailable"
fi

# --- Host report source ------------------------------------------------------

declare -a AGENT_ROWS=()
for i in "${!AGENT_IDS[@]}"; do
  id="${AGENT_IDS[$i]}"
  fallback_role="${AGENT_ROLES[$i]}"
  alias_name="${AGENT_ALIASES[$i]}"
  report="$(fetch_report_text "$id" "$alias_name")" || report=""
  if [[ -n "$report" ]]; then
    r_updated="$(report_field "$report" 'Updated')"
    r_role="$(report_field "$report" 'Role')"
    r_type="$(report_field "$report" 'Type')"
    r_state="$(report_field "$report" 'State')"
    r_issue="$(report_field "$report" 'Issue')"
    r_url="$(report_field "$report" 'URL')"
    r_summary="$(report_summary_line "$report")"
    if [[ -n "$r_updated" && -n "$r_type" ]]; then
      role="$(friendly_role "${r_role:-unknown}")"
      blocker_kind="ok"
      blocker_text="ok"
      case "${r_state^^}" in
        *BLOCKED*)
          blocker_kind="blocked"
          blocker_text="BLOCKED"
          ;;
      esac
      esc_role="$(html_escape "$role")"
      esc_type="$(html_escape "${r_type:-unknown}")"
      esc_state="$(html_escape "${r_state:-unknown}")"
      esc_updated="$(html_escape "$r_updated")"
      esc_summary="$(html_escape "${r_summary:-no summary line}")"
      if [[ "$blocker_kind" == "blocked" ]]; then
        blocker_html="$(badge blocked "$blocker_text")"
      else
        blocker_html="$(badge ok "$blocker_text")"
      fi
      if [[ -n "$r_url" ]]; then
        handoff_html="<a href=\"${r_url}\">$(html_escape "$(handoff_issue_ref "${r_issue:-none}")")</a> $(html_escape "$r_type")"
      else
        handoff_html="$(html_escape "$(handoff_issue_ref "${r_issue:-none}")") $(html_escape "$r_type")"
      fi
      note_source "report ${id}: ok (${r_updated})"
    else
      role="$fallback_role"
      esc_role="$(html_escape "$role")"
      esc_type=""
      esc_state=""
      esc_updated=""
      esc_summary=""
      blocker_html="$(unavailable_badge)"
      handoff_html="$(unavailable_badge)"
      failures=$((failures + 1))
      note_source "report ${id}: malformed"
    fi
  else
    role="$fallback_role"
    esc_role="$(html_escape "$role")"
    esc_type=""
    esc_state=""
    esc_updated=""
    esc_summary=""
    blocker_html="$(unavailable_badge)"
    handoff_html="$(unavailable_badge)"
    failures=$((failures + 1))
    note_source "report ${id}: unavailable/stale"
  fi

  gh_cell="$(unavailable_badge)"
  for row in "${GITHUB_ROWS[@]}"; do
    [[ "$row" == *"<strong>${id}</strong>"* ]] && gh_cell="$row"
  done

  AGENT_ROWS+=("      <tr><td>${id}</td><td>${esc_role}</td><td>${esc_type}${esc_type:+ / }${esc_state}</td><td>${gh_cell}</td><td>${esc_updated}</td><td>${esc_summary}</td><td>${blocker_html}</td><td>${handoff_html}</td></tr>")
done

# --- Render ------------------------------------------------------------------

{
  cat <<HEADER
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Agent status dashboard &mdash; ${REPO}</title>
<style>
body{font-family:system-ui,sans-serif;margin:2rem;color:#1f2328;background:#f6f8fa}
h1{font-size:1.4rem}
section{background:#fff;border:1px solid #d0d7de;border-radius:6px;padding:1rem 1.25rem;margin-bottom:1.25rem}
table{border-collapse:collapse;width:100%;font-size:.9rem}
th,td{border:1px solid #d0d7de;padding:.4rem .55rem;text-align:left;vertical-align:top}
th{background:#f6f8fa}
.badge{display:inline-block;padding:.05rem .5rem;border-radius:999px;font-size:.78rem;border:1px solid}
.badge-ok{background:#dafbe1;border-color:#aceebb}
.badge-blocked{background:#ffebe9;border-color:#ff818266}
.badge-unavailable{background:#fff8c5;border-color:#d4a72c66}
ul{padding-left:1.1rem;margin:.2rem 0}
footer{font-size:.8rem;color:#59636e}
</style>
</head>
<body>
<h1>Agent status dashboard</h1>
<p>Repository: ${REPO} &middot; Generated: ${generated_at} (UTC) &middot; Manual refresh only: re-run <code>scripts/dashboard-generate.sh</code>.</p>
<section>
<h2>Agents</h2>
<table>
<thead><tr><th>Identity</th><th>Role</th><th>Type / State (latest handoff)</th><th>Current issue or PR (live)</th><th>Last report update (UTC)</th><th>Summary</th><th>Blocker</th><th>Latest handoff</th></tr></thead>
<tbody>
HEADER
  for row in "${AGENT_ROWS[@]}"; do
    printf '%s\n' "$row"
  done
  cat <<MIDDLE
</tbody>
</table>
</section>
<section>
<h2>Pull request security gate (live)</h2>
<table>
<thead><tr><th>PR</th><th>Head</th><th>Combined status</th><th>Security context</th></tr></thead>
<tbody>
MIDDLE
  for row in "${PR_ROWS[@]}"; do
    printf '%s\n' "$row"
  done
  cat <<MIDDLE2
</tbody>
</table>
<p>Live GitHub state at generation time; host reports carry their own timestamps so staleness stays visible.</p>
</section>
<section>
<h2>Source health</h2>
<ul>
MIDDLE2
  for item in "${SOURCE_HEALTH[@]}"; do
    printf '<li>%s</li>\n' "$(html_escape "$item")"
  done
  cat <<FOOTER
</ul>
</section>
<footer>Static snapshot rendered by scripts/dashboard-generate.sh. GitHub remains the durable source of truth. All sourced text is HTML-escaped; this file is untracked and never committed.</footer>
</body>
</html>
FOOTER
} >"$TMP_OUT"

if ! gate_scan "$TMP_OUT"; then
  rm -f "$TMP_OUT"
  exit 2
fi

mv "$TMP_OUT" "$OUTPUT"
echo "Dashboard written: $OUTPUT"

if ((failures > 0)); then
  echo "Warning: ${failures} source(s) unavailable; dashboard marks them explicitly." >&2
  exit 1
fi
exit 0
