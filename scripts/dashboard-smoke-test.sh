#!/usr/bin/env bash
set -euo pipefail

# Offline smoke test for scripts/dashboard-generate.sh.
# Uses fixture reports and a stubbed gh so no network access occurs.

root="$(git rev-parse --show-toplevel)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/bin" "$work/state/pm-t310" "$work/state/dev-r510" "$work/state/security-r410" "$work/out"

pass=0
fail=0

record() {
  local desc="$1"
  if [[ "$2" -eq 0 ]]; then
    pass=$((pass + 1))
    printf 'PASS: %s\n' "$desc"
  else
    fail=$((fail + 1))
    printf 'FAIL: %s\n' "$desc" >&2
  fi
}

assert_contains() {
  local file="$1" needle="$2" desc="$3"
  if grep -Fq -- "$needle" "$file"; then
    record "$desc (contains: $needle)" 0
  else
    record "$desc (contains: $needle)" 1
  fi
}

write_report() {
  local dir="$1" updated="$2" type="$3" state="$4" issue="$5" url="$6" summary="$7" role="${8:-unknown}"
  cat >"$work/state/$dir/latest.md" <<REPORT
# Agent status: $dir

- Updated: $updated
- Role: $role
- Type: $type
- State: $state
- Issue: $issue
- URL: $url

## Summary

$summary
REPORT
}

write_report pm-t310 \
  "2026-08-21T09:00:00Z" STATUS waiting 7 \
  "https://github.com/Mattjhagen/Projects/issues/7" \
  "Scoped dashboard MVP; parent waiting on children." pm

write_report dev-r510 \
  "2026-08-22T11:30:00Z" HANDOFF review 8 \
  "https://github.com/Mattjhagen/Projects/issues/8" \
  "Generator implemented; awaiting security review." developer

write_report security-r410 \
  "2026-08-20T08:00:00Z" BLOCKED blocked 16 \
  "https://github.com/Mattjhagen/Projects/issues/16" \
  "Blocking finding recorded against legacy pull request." security

cat >"$work/bin/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"; shift || true
case "$cmd" in
  issue)
    label=""; prev=""
    for a in "$@"; do
      [[ "$prev" == "--label" ]] && label="$a"
      prev="$a"
    done
    case "$label" in
      agent:pm)
        printf '%s\n' '[{"number":7,"title":"Intake: agent status dashboard","url":"https://github.com/Mattjhagen/Projects/issues/7","updatedAt":"2026-08-21T09:00:00Z","labels":[{"name":"agent:pm"},{"name":"status:blocked"},{"name":"type:feature"}]}]'
        ;;
      agent:developer)
        printf '%s\n' '[{"number":8,"title":"[Dev] Build agent status dashboard MVP","url":"https://github.com/Mattjhagen/Projects/issues/8","updatedAt":"2026-08-22T11:30:00Z","labels":[{"name":"agent:developer"},{"name":"status:in-progress"},{"name":"type:feature"}]}]'
        ;;
      *)
        printf '%s\n' '[]'
        ;;
    esac
    ;;
  pr)
    cat <<'JSON'
[
  {"number":31,"title":"Walkthrough docs","url":"https://github.com/Mattjhagen/Projects/pull/31","headRefOid":"1111111111111111111111111111111111111111","updatedAt":"2026-08-22T12:00:00Z"},
  {"number":29,"title":"Pipeline validation","url":"https://github.com/Mattjhagen/Projects/pull/29","headRefOid":"2222222222222222222222222222222222222222","updatedAt":"2026-08-22T10:00:00Z"}
]
JSON
    ;;
  api)
    sha=""
    if [[ "${1:-}" =~ commits/([0-9a-f]+)/status ]]; then
      sha="${BASH_REMATCH[1]}"
    fi
    case "$sha" in
      1111*) printf '%s\n' '{"state":"success","statuses":[{"context":"agent/security-review","state":"success"},{"context":"validate","state":"success"}]}' ;;
      *) printf '%s\n' '{"state":"pending","statuses":[{"context":"agent/security-review","state":"pending"}]}' ;;
    esac
    ;;
  *)
    echo "stub gh: unsupported subcommand: $cmd" >&2
    exit 64
    ;;
esac
STUB
chmod +x "$work/bin/gh"

run_generator() {
  PATH="$work/bin:$PATH" DASHBOARD_REPORT_FETCH=local \
    DASHBOARD_STATE_DIR="$work/state" DASHBOARD_OUTPUT="$work/out/index.html" \
    DASHBOARD_REPO="Mattjhagen/Projects" \
    bash "$root/scripts/dashboard-generate.sh"
}

echo "== smoke: all sources available =="
rc=0
run_generator || rc=$?
record "generator exits zero when every source is available" "$rc"

html="$work/out/index.html"
if [[ -s "$html" ]]; then
  record "dashboard file written and non-empty" 0
else
  record "dashboard file written and non-empty" 1
fi

for needle in pm-t310 dev-r510 security-r410 \
  "Project Manager" "Senior Developer" "Cybersecurity Expert" \
  "#7" "#8" "#16" "#31" "#29" \
  "2026-08-21T09:00:00Z" "2026-08-22T11:30:00Z" "2026-08-20T08:00:00Z" \
  "Scoped dashboard MVP" "Generator implemented" "Blocking finding" \
  ">BLOCKED<" "HANDOFF" "STATUS" \
  "agent/security-review: success" "agent/security-review: pending"; do
  assert_contains "$html" "$needle" "required field rendered"
done

assert_contains "$html" "issues/7" "current issue links present"

if grep -Eq 'unavailable/stale' "$html"; then
  record "no unavailable markers when all sources healthy" 1
else
  record "no unavailable markers when all sources healthy" 0
fi

echo "== smoke: one host report missing =="
rm -f "$work/state/dev-r510/latest.md"
rc=0
run_generator || rc=$?
if [[ "$rc" -ne 0 ]]; then
  record "missing source forces non-zero exit" 0
else
  record "missing source forces non-zero exit" 1
fi

html2="$work/out/index.html"
if [[ -s "$html2" ]]; then
  record "dashboard still written despite missing source" 0
else
  record "dashboard still written despite missing source" 1
fi
assert_contains "$html2" "unavailable/stale" "missing source marked explicitly"
assert_contains "$html2" "pm-t310" "healthy agents still rendered"
assert_contains "$html2" "security-r410" "third agent still rendered"

echo "== smoke: forbidden-pattern gate =="
good_sum="$(md5sum "$html" | cut -d' ' -f1)"
write_report security-r410 \
  "2026-08-20T08:00:00Z" BLOCKED blocked 16 \
  "https://github.com/Mattjhagen/Projects/issues/16" \
  "Leaked token ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ123456 in summary." security
rc=0
run_generator || rc=$?
if [[ "$rc" -eq 2 ]]; then
  record "forbidden pattern aborts generation with exit 2" 0
else
  record "forbidden pattern aborts generation with exit 2" 1
fi
new_sum="$(md5sum "$html" | cut -d' ' -f1)"
if [[ "$new_sum" == "$good_sum" ]]; then
  record "rejected output is never published (previous snapshot untouched)" 0
else
  record "rejected output is never published (previous snapshot untouched)" 1
fi

printf '\nSmoke test results: %d passed, %d failed\n' "$pass" "$fail"
if [[ "$fail" -eq 0 ]]; then
  exit 0
fi
exit 1
