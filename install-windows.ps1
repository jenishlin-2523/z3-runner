# Z3 Demo Runner — Windows install. Run in PowerShell AS ADMINISTRATOR, from the runner folder, logged in as the
# Windows user that ran `claude` and logged in (the Claude login belongs to that user).
#
#   powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
#
# It (1) checks Node, Claude Code and the .env, (2) stops the PC from sleeping, (3) registers a Task Scheduler task
# "Z3 Demo Runner" that starts at log-on and restarts itself if it ever exits. Re-run it any time; it replaces the task.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

Write-Host "== 1. checks ==" -ForegroundColor Cyan
$node = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $node) { throw "Node.js is not installed. Get the LTS installer from https://nodejs.org and run this again." }
if (-not (Test-Path "$here\.env")) { throw "Copy .env.example to .env and fill in BACKEND_URL and WORKER_TOKEN first." }
& $node "$here\z3-runner.mjs" --doctor
if ($LASTEXITCODE -ne 0) { throw "Fix the items marked above, then run this script again." }

Write-Host "== 2. never sleep ==" -ForegroundColor Cyan
powercfg /change standby-timeout-ac 0 | Out-Null
powercfg /change hibernate-timeout-ac 0 | Out-Null
powercfg /change disk-timeout-ac 0 | Out-Null
powercfg /hibernate off 2>$null | Out-Null
Write-Host "sleep, hibernate and disk power-down are off while on mains power (the screen may still turn off)."

Write-Host "== 3. start-up task ==" -ForegroundColor Cyan
$taskName = 'Z3 Demo Runner'
$user = "$env:USERDOMAIN\$env:USERNAME"
# cmd wrapper so output is appended to runner.log
$cmd = "/c `"`"$node`" `"$here\z3-runner.mjs`" >> `"$here\runner.log`" 2>&1`""
$action   = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument $cmd -WorkingDirectory $here
$trigger  = New-ScheduledTaskTrigger -AtLogOn -User $user
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
            -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 4
Write-Host "task '$taskName' registered for $user and started. Log: $here\runner.log"

Write-Host ""
Write-Host "One thing left for a true 24/7 machine: make Windows log this user in automatically after a restart" -ForegroundColor Yellow
Write-Host "(Win+R -> netplwiz -> untick 'Users must enter a user name and password'), and set the BIOS to power on after a power cut."
Write-Host "Then open any lead in the portal -> Demo tab: it should say 'Office runner online'."
