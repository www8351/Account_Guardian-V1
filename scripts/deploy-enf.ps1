# deploy-enf.ps1
# ENF deploy, owner ruling ENF-27(a) of 2026-09-16, under the 2026-09-06 deploy hand shape. THE OWNER RUNS THIS. The executor never runs it.
# Two Copy-Item lines from the worktree into the Terminal data folder, each followed by Get-FileHash of the landed path.
# No deletes, no renames, no variables, no functions. Every path literal.
# Expected md5 of each file as compiled in the worktree on 2026-09-16, standing rule 7: recorded, not identity.
#   AccountGuardian.ex5        CD1325F9821EF2369C4CC0CE4BD51ED7  130404 bytes
#   AgPhase2StateVectors.ex5   E7B469222CCFA421F104448715BFD1F9   77488 bytes

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\enforcement-build-20260916\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\enforcement-build-20260916\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
