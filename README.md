# Z3 Demo Runner — the 24/7 office PC

Builds customer demos with Claude Code, using the Claude subscription login on this PC. It only makes **outbound**
calls to the portal. No port forwarding, no public IP, nothing listens on this machine.

```
portal (VPS)                         this PC
  demo job queue   <── "any job?" ──  z3-runner.mjs
                   ── job ────────>   builds with `claude` (file tools only, one folder per job)
                   <── files ──────   checks the result, uploads it for internal preview
  review + approve in the portal  →  published by the portal (this PC holds no hosting credential)
```

## What this PC needs

| | |
|---|---|
| Windows 10/11 (or Linux / macOS) | a dedicated machine, wired network, a UPS if possible |
| Node.js 20 or newer | <https://nodejs.org> → LTS installer |
| Claude Code | <https://claude.com/claude-code> → install, then run `claude` once and **log in with the subscription account** |
| Git for Windows | <https://git-scm.com/download/win> — needed by Claude Code and to pull this repository |
| This repository | clone it to `C:\z3-runner`; update later with `git pull` |

## Set-up (about 20 minutes)

1. Use a PC that is kept only as a server. If anyone also works on it, create a separate Windows account for the runner
   (for example `z3runner`) so it sits next to nobody's mail, browser profiles or documents.
2. Install Node.js and Claude Code. Open a terminal, run `claude`, log in, then type `/exit`.
3. `git clone <this repository> C:\z3-runner`. Copy `.env.example` to `.env` and fill in two values:
   - `BACKEND_URL` — `https://z3portal.200-141-9-11.sslip.io`
   - `WORKER_TOKEN` — on the VPS: `cat /opt/zportal/.demo_worker_token` (keep it private; it is this PC's identity)
4. Check everything: `node z3-runner.mjs --doctor` — every line should show ✔.
5. Install it as a start-up task and stop the PC from sleeping (PowerShell **as Administrator**):
   `powershell -ExecutionPolicy Bypass -File .\install-windows.ps1`
6. In the portal, open any lead → **Demo** tab. It should say "Office runner online".

## Day to day

- Logs: `C:\z3-runner\runner.log`. Work folders: `C:\z3-runner\work\<job>` (deleted after 7 days).
- Stop / start: Task Scheduler → **Z3 Demo Runner** → End / Run. Or `Stop-ScheduledTask` / `Start-ScheduledTask`.
- Pause from the portal side without touching the PC: set CRM setting `demo.paused = true`.
- If a build says "claude exited… log in": open a terminal **as the runner's Windows user**, run `claude`, log in again.
- `GENERATOR=stub` in `.env` builds a plain template demo with no AI. Useful to test the plumbing; reviewers see a
  "template build" badge.

## Safety

- The customer's requirement reaches Claude as a JSON **data** file; the instructions are fixed text written by the runner.
- Claude gets file tools only — no shell, no web access — and works inside one job folder.
- `ANTHROPIC_API_KEY` is removed from Claude's environment, so builds always use the subscription login, never a metered key.
- Before upload the result is scanned: allowed file types only, size limits, no secrets, no internal addresses, no
  external resources, no broken links. Problems trigger up to two automatic fix passes; serious findings block the job.
- Demos are served by the portal from a separate address with a policy that stops them calling out to the internet.
- This PC stores exactly two secrets: its worker token and the Claude login. No database, CRM or WhatsApp credentials.
