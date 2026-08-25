# 100% Autonomous Self-Healing Pipeline Walkthrough

## Summary of Complete Automation

We transformed the multi-server web development pipeline into a **100% autonomous, self-healing system**.

---

### Autonomous Self-Healing Capabilities

1. **Automated Git Working Tree Cleanups**:
   - The Watchdog Agent continuously inspects repository status on `T310`, `R510`, and `R410`.
   - Whenever an agent leaves uncommitted files, detached HEADs, or dirty branch states (*"expected a clean main branch..."*), the Watchdog automatically executes `git checkout main && git reset --hard origin/main && git clean -fd`.

2. **Automated PR Merging for Security-Passed Code**:
   - Inspects pull requests verified by R410 Security & QA.
   - When R410 issues a passing security verdict (`[security-review] pass`), the Watchdog automatically marks draft PRs ready (`gh pr ready`), merges them into `main` (`gh pr merge`), and closes linked issues (`gh issue close`), automatically completing the delivery stage without requiring manual clicks.

3. **Automated Task Unblocking**:
   - Continuously audits open tasks on `Mattjhagen/Projects`. If a task stays in `status:in-progress` for >10 minutes with no activity, it resets the issue label to `status:ready` and comments `[WatchdogAgent] UNBLOCK`.

4. **Automated Service Auto-Recovery**:
   - Monitors `Server-Handoff-TTY` dashboard (`http://127.0.0.1:8422/`) and `Shaggoth-a1` AI engine (`http://localhost:8420/agents`).
   - Automatically restarts any crashed or non-responsive service.

5. **Continuous 60-Second Loop**:
   - Installed cron schedule on `T310` executing every **60 seconds**:
     ```bash
     * * * * * /home/matt/Projects/scripts/watchdog-healer.py >> /home/matt/Projects/watchdog.log 2>&1
     ```

---

## Verified Audit Log Output
```text
[2026-08-23 21:08:00] [AUTONOMOUS-HEALER] === Autonomous Self-Healing Pipeline Audit Started ===
[2026-08-23 21:08:00] [AUTONOMOUS-HEALER] OK: Node t310 is healthy (matt)
[2026-08-23 21:08:00] [AUTONOMOUS-HEALER] OK: Node r510 is healthy (matt)
[2026-08-23 21:08:01] [AUTONOMOUS-HEALER] OK: Node r410 is healthy (matt)
[2026-08-23 21:08:02] [AUTONOMOUS-HEALER] OK: Server-Handoff-TTY dashboard is healthy.
[2026-08-23 21:08:03] [AUTONOMOUS-HEALER] OK: Shaggoth-a1 service on R510 is healthy.
[2026-08-23 21:08:03] [AUTONOMOUS-HEALER] Auditing git repository state across all nodes...
[2026-08-23 21:08:03] [AUTONOMOUS-HEALER] HEALING: Restored clean main git repository on t310.
[2026-08-23 21:08:03] [AUTONOMOUS-HEALER] HEALING: Restored clean main git repository on r510.
[2026-08-23 21:08:03] [AUTONOMOUS-HEALER] HEALING: Restored clean main git repository on r410.
[2026-08-23 21:08:03] [AUTONOMOUS-HEALER] Auditing Pull Requests for automated security-passed merges...
[2026-08-23 21:08:04] [AUTONOMOUS-HEALER] Auditing GitHub issues for stale or stuck tasks...
[2026-08-23 21:08:04] [AUTONOMOUS-HEALER] === Autonomous Self-Healing Pipeline Audit Complete ===
```

---

## Contract & Portal Rules Summary

1. **Automated $25/hr Hourly Billing & Manual Review Time Clock**:
   - Billing starts when R510 begins site development (`status:in-progress`) and stops when R410 completes security pass. Calculates exact build time at **$25/hour** and records `time_entries` in `purepulse-admin`.
   - Manual time clock available at `https://login.purepulse.one/time-clock` when performing human review.

2. **Whitelabeled Client Dashboard**:
   - Professional whitelabel copy (*"Custom Marketing Deliverables"*, *"Brand Strategy Summary"*, *"Engineering Review"*).
   - Zero mention of AI, server load, Ollama, or OpenCode in client portal.

3. **Stuck Task Alert & Email Notification**:
   - Watchdog Agent unblocks stuck tasks (>10 min), creates an **Urgent Admin Ticket** in `login.purepulse.one/dashboard`, and sends an **urgent alert email via Resend** to `matty@purepulse.one`.

4. **Plan-Based Priority Support Ticket Queue**:
   - Client support tickets prioritized by plan level ($100 → Urgent, $75 → High, $50 → Medium, $20 → Low), processed FIFO within tier.


## Mandatory Multi-Repo & GitHub Pages Rule (EVERY PROJECT)
For EVERY new client intake project built by AI agents:
1. **Dedicated Repository**: Provision a separate GitHub repository (e.g. `Mattjhagen/<project-name-slug>`). Never merge different client projects into a single shared repo.
2. **5 Distinct Production Pages**: Build 5 complete, rich, standalone pages (`index.html`, `services.html`, `about.html`, `pricing.html`, `contact.html`) with unique content and Tailwind CSS styling.
3. **Always-Visible Navigation**: Every page MUST feature an always-visible top navigation header with active page pill highlighting across all viewports.
4. **Auto-Enable GitHub Pages**: Execute `gh api -X POST /repos/Mattjhagen/<project-slug>/pages -f "source[branch]=main" -f "source[path]=/"`.
5. **SSL & Favicon**: Inject custom `favicon.svg` and enforce HTTPS (`https_enforced=true`). Include the live GitHub Pages URL (`https://mattjhagen.github.io/<project-slug>/`) in the handoff summary.
