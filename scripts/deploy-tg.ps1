# deploy-tg.ps1
# TG deploy, the Telegram alerts build, TG-1 (B) of 2026-10-20, to the demo terminal of TG-10 (A), under the 2026-09-06 deploy hand shape. THE OWNER RUNS THIS. The executor never runs it.
# Three Copy-Item lines from the worktree into the Terminal data folder, each followed by Get-FileHash of the landed path.
# No deletes, no renames, no variables, no functions. Every path literal. The alerts service lands straight into the existing MQL5\Services, TG-16 (A); no folder is created.
# Expected md5 of each file as compiled in the worktree on 2026-10-21 from source commit 8a16f3d, standing rule 7: recorded, not identity.
#   AccountGuardian.ex5          9FF2E779E32E6AA2A861F05A525DCEC9  224644 bytes
#   AccountGuardianAlerts.ex5    DA6CFD8C8DFFB77622F63AAC8E54D45D  127750 bytes
#   AgPhase2StateVectors.ex5     BE3EB994BEEE7845A6F16E900D79CC15  256578 bytes
# Before running: close the terminal, or stop any running AccountGuardianAlerts instance, so the service file is not in use.

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\build-telegram-alerts\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\build-telegram-alerts\MQL5\Services\AccountGuardian\AccountGuardianAlerts.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\build-telegram-alerts\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
