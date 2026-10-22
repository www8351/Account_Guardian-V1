# deploy-ml.ps1
# ML deploy, the Manual Lockout build, rulings ML-1 to ML-27 of 2026-10-22, to the demo terminal of TG-10 (A), under the 2026-09-06 deploy hand shape as ML-25 (A) extends it. THE OWNER RUNS THIS. The executor never runs it.
# Three Copy-Item lines from the worktree into the Terminal data folder, each followed by Get-FileHash of the landed path, in the order of ML-25 (A): the alerts service first (F5 of the plan), then the EA, then the vectors script.
# No deletes, no renames, no variables, no functions. Every path literal. No folder is created.
# Expected md5 of each file as compiled in the worktree on 2026-10-23 from source commit a1987e268a01b144db637009eea8435a6d1c67f3, standing rule 7: recorded, not identity.
#   AccountGuardianAlerts.ex5    71DF7552F4150EF18F142248C51090E3  152150 bytes
#   AccountGuardian.ex5          6CF4A8381A6E6BFD587F15AEC64EB947  291076 bytes
#   AgPhase2StateVectors.ex5     ADDE2D2F03ED2D475C58343A8F333A6B  379102 bytes
# Before running: stop the running AccountGuardianAlerts instance (Navigator, Services, right click, Stop), so the service file is not in use. The terminal and the guardian keep running; whether the guardian reloads from its new file by itself or is attached again by hand, its init line names build=ML (row ML-D).
# After running: start the service again (Navigator, Services, right click, Start).

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\feature-manual-lockout\MQL5\Services\AccountGuardian\AccountGuardianAlerts.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\feature-manual-lockout\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\feature-manual-lockout\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
