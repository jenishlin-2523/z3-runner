# Set-up prompt for Claude Code on the office PC

Open PowerShell on the office PC, run `claude`, and paste everything inside the box below as one message.

```
You are setting up this Windows PC as the "Z3 Demo Runner": a 24/7 build machine for my company's portal (Z Portal).
I am not a developer, so do the work yourself, explain each step in one or two plain sentences, and only stop when
you need me to do something by hand (I list those moments below).

WHAT THE RUNNER IS
A small Node.js program (z3-runner.mjs, no dependencies). It asks my server "any demo job?" every few seconds over
HTTPS, builds the demo website with Claude Code using the Claude subscription login on this PC, checks the result and
uploads it. It only makes OUTBOUND calls. Nothing listens on this PC. Source: https://github.com/jenishlin-2523/z3-runner
(public, no sign-in needed).

RULES — these matter more than finishing quickly
1. Never ask me to paste the worker token into this chat, and never print, read aloud, log or commit the contents of
   C:\z3-runner\.env. I will type the token into Notepad myself. To check it, use only `node z3-runner.mjs --doctor`,
   which prints the token's LENGTH, not the token.
2. Do not edit z3-runner.mjs or install-windows.ps1. If something in them looks wrong, stop and tell me exactly what
   you saw so I can pass it to the developer who maintains them.
3. Do not open firewall ports, set up port forwarding, install remote-access tools, turn off antivirus or Windows
   Update, or change anything unrelated to this task.
4. Do not set ANTHROPIC_API_KEY anywhere. Builds must use the subscription login.
5. Before each step that needs administrator rights, tell me a Windows "Do you want to allow…" box is coming so I can
   click Yes.

STEPS
1. Check the basics and tell me what you found:
   - `node -v` must be v20 or newer. If missing: `winget install OpenJS.NodeJS.LTS`.
   - `git --version`. If missing: `winget install Git.Git`.
   - `claude --version` must work (it does if you are reading this).
   - I must be an administrator on this PC: `whoami /groups` must contain S-1-5-32-544. If it does not, stop and tell me.
   - `[Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User')` and the same with 'Machine' must both be empty.
     If either is set, tell me and ask before removing it.
   If you installed Node or Git, tell me to close this window, open a new PowerShell, run `claude` and paste this
   prompt again, because the old window cannot see the new programs.

2. Get the runner:
   - If C:\z3-runner does not exist: `git clone https://github.com/jenishlin-2523/z3-runner.git C:\z3-runner`
   - If it exists and is this repository: `git -C C:\z3-runner pull`. If it exists and is something else, stop and ask.

3. Settings file:
   - If C:\z3-runner\.env does not exist, copy .env.example to .env.
   - Open it for me: `notepad C:\z3-runner\.env`, then tell me:
     "Paste the token right after WORKER_TOKEN= with no spaces or quotes, press Ctrl+S, close Notepad, then type done."
     (I get the token from my other PC with: ssh root@200.141.9.11 "cat /opt/zportal/.demo_worker_token")
   - Wait for me to type done. Do not read the file afterwards.

4. Check: run `node z3-runner.mjs --doctor` inside C:\z3-runner and show me the lines. All must be ✔.
   - "token rejected (401)" = I pasted it wrongly. Open Notepad again for me and repeat.
   - "WORKER_TOKEN … missing" or a wrong length (it should be 64 characters) = same fix.
   - "Claude Code CLI found" is ✘ = find the real path with `(Get-Command claude).Source`, and ask me to let you set
     CLAUDE_BIN to that full path. For this one change only, append/replace the CLAUDE_BIN line with a command that does
     not print the file, for example:
     (Get-Content C:\z3-runner\.env) -replace '^CLAUDE_BIN=.*$', ('CLAUDE_BIN=' + (Get-Command claude).Source) | Set-Content C:\z3-runner\.env -Encoding utf8
     Then run the doctor again.
   - Portal not reachable = check the internet connection with `Test-NetConnection z3portal.200-141-9-11.sslip.io -Port 443`.

5. Install as a start-up task (needs administrator rights — warn me first). Run:
   Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "Set-Location C:\z3-runner; .\install-windows.ps1 *>&1 | Tee-Object -FilePath C:\z3-runner\install.log"'
   Then read C:\z3-runner\install.log and tell me what happened. The script switches off sleep on mains power and
   registers the task "Z3 Demo Runner" for my Windows user (starts at sign-in, restarts itself if it stops).

6. Prove it is running:
   - `Get-ScheduledTask -TaskName 'Z3 Demo Runner' | Get-ScheduledTaskInfo` and the task State should be Running.
   - Show me the last 15 lines of C:\z3-runner\runner.log. I expect "runner starting" and no repeating errors.
   - Exactly one runner process: `Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object CommandLine -like '*z3-runner.mjs*' | Select-Object ProcessId, CommandLine`
   - Ask me to open the portal on any device: CRM → any lead → Demo tab. It should say "Office runner online".

7. Make it survive restarts — these are MY jobs; walk me through them one at a time and wait for me:
   a. Automatic sign-in: Win+R → netplwiz → select my user → untick "Users must enter a user name and password" →
      OK → type my Windows password. If the tick box is missing: Settings → Accounts → Sign-in options → turn off
      "For improved security, only allow Windows Hello sign-in", then reopen netplwiz.
   b. BIOS: set "Restore on AC power loss" (or "After power failure") to Power On. Tell me this is done at boot with
      Del or F2 and that I can do it later.
   c. Settings → Windows Update → Advanced options → Active hours: set to my office hours so updates restart the PC
      at night, not during the day.
   d. Restart the PC now, sign-in should happen by itself. After it is back, I will open `claude` again and ask you
      to repeat step 6.

8. Finish with a short report: what was installed, the versions, whether every doctor line was ✔, the task state,
   what I still have to do by hand, and anything that looked wrong. Do not include the token or the .env contents.

LATER (tell me these exist, do not do them now)
- Update the runner: `git -C C:\z3-runner pull`, then Task Scheduler → Z3 Demo Runner → End, then Run.
- A build fails with "log in": open PowerShell as this same Windows user, run `claude`, log in again.
- Test the plumbing without AI: set GENERATOR=stub in .env, restart the task, request a demo, set it back to claude.
```

## What you do by hand

| When | What |
|---|---|
| Before starting | Install Node.js LTS, Git for Windows and Claude Code; run `claude` and log in with the subscription account |
| Step 3 | Paste the worker token into Notepad (get it on your own PC: `ssh root@200.141.9.11 "cat /opt/zportal/.demo_worker_token"`) |
| Step 5 | Click **Yes** on the Windows administrator box |
| Step 7 | Automatic sign-in, BIOS power-on, Windows Update active hours, one restart |
