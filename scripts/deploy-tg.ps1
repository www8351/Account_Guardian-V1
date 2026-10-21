# deploy-tg.ps1
# TG deploy, the Telegram alerts build, TG-1 (B) of 2026-10-20, to the demo terminal of TG-10 (A), under the 2026-09-06 deploy hand shape. THE OWNER RUNS THIS. The executor never runs it.
# Format pass B3 of 2026-10-21: the EA's compiled sources are unchanged from fix pass B2, so the EA's file is not copied and the running guardian is not touched.
# Two Copy-Item lines from the worktree build-telegram-alerts-format into the Terminal data folder, each followed by Get-FileHash of the landed path.
# No deletes, no renames, no variables, no functions. Every path literal. The alerts service lands straight into the existing MQL5\Services, TG-16 (A); no folder is created.
# Expected md5 of each file as compiled in the worktree on 2026-10-21 from source commit d380a98, format pass B3, standing rule 7: recorded, not identity.
#   AccountGuardianAlerts.ex5    5B0336CCABDAE31280E4F49DA6D605C2  143900 bytes
#   AgPhase2StateVectors.ex5     7B4806B0D3CFC096D6D6DB313BEA6549  311864 bytes
# Before running: stop the running AccountGuardianAlerts instance (Navigator, Services, right click, Stop), so the service file is not in use. The terminal and the guardian keep running.

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\build-telegram-alerts-format\MQL5\Services\AccountGuardian\AccountGuardianAlerts.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\build-telegram-alerts-format\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
