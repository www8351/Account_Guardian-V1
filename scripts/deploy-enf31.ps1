# deploy-enf31.ps1
# ENF-31 deploy, the ENF-31 build with the ENF-DEF-1 (b) fix, owner rulings of 2026-09-23, under the 2026-09-06 deploy hand shape. THE OWNER RUNS THIS. The executor never runs it.
# Two Copy-Item lines from the worktree into the Terminal data folder, each followed by Get-FileHash of the landed path.
# No deletes, no renames, no variables, no functions. Every path literal.
# Expected md5 of each file as compiled in the worktree on 2026-09-28, standing rule 7: recorded, not identity.
#   AccountGuardian.ex5        6E753E10B3B0367DDED83658B322C0A1  131754 bytes
#   AgPhase2StateVectors.ex5   BA9755CF5E525D52F2BE392179D12DD1   77400 bytes

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\enf31-build-20260928\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath 'C:\Users\www83\Downloads\AI\AccountGuardian\.claude\worktrees\enf31-build-20260928\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
