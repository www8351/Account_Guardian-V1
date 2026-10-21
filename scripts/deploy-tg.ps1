# deploy-tg.ps1
# TG deploy, the Telegram alerts build, TG-1 (B) of 2026-10-20, to the demo terminal of TG-10 (A), under the 2026-09-06 deploy hand shape. THE OWNER RUNS THIS. The executor never runs it.
# Pass B5 of 2026-10-21, the PNL line and the open trades line: the EA's compiled sources are unchanged from main at 2acbe38, so the EA's file is not copied and the running guardian is not touched.
# Two Copy-Item lines from the worktree build-telegram-alerts-pnl into the Terminal data folder, each followed by Get-FileHash of the landed path.
# No deletes, no renames, no variables, no functions. Every path literal. The alerts service lands straight into the existing MQL5\Services, TG-16 (A); no folder is created.
# Expected md5 of each file as compiled in the worktree on 2026-10-21 from source commit 8248797, pass B5, standing rule 7: recorded, not identity.
#   AccountGuardianAlerts.ex5    9C656165419DF3FFB166BB677591450F  148376 bytes
#   AgPhase2StateVectors.ex5     F196ACF8BB7E0970A7F53721963B42EF  316694 bytes
# Before running: stop the running AccountGuardianAlerts instance (Navigator, Services, right click, Stop), so the service file is not in use. The terminal and the guardian keep running.

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\build-telegram-alerts-pnl\MQL5\Services\AccountGuardian\AccountGuardianAlerts.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\build-telegram-alerts-pnl\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
