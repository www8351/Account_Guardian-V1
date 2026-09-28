# deploy-pk.ps1
# PK deploy, the peak path witness build, (c1) and (b1) per the owner rulings PK-1 to PK-15 of 2026-09-28, under the 2026-09-06 deploy hand shape. THE OWNER RUNS THIS. The executor never runs it.
# Two Copy-Item lines from the worktree into the Terminal data folder, each followed by Get-FileHash of the landed path.
# No deletes, no renames, no variables, no functions. Every path literal.
# Expected md5 of each file as compiled in the worktree on 2026-09-28, standing rule 7: recorded, not identity.
#   AccountGuardian.ex5        9ABD2D8C3252112719D860D768B74965  130916 bytes
#   AgPhase2StateVectors.ex5   32FADBE3EE1432B5693AF3BAA498797E   79746 bytes

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\pk-build-20260928\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\pk-build-20260928\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
