# export-release.ps1
# Builds the folder that feeds the separate release repository, from one
# committed revision of this repository.
#
# It carries only these, taken byte for byte from git at the revision:
#   every file named in installer/manifest.txt (the shipped MQL5 sources,
#   installer/install.cmd and installer/install.ps1), installer/manifest.txt
#   itself, README.md, LICENSE and .gitattributes, and the *.svg and *.gif
#   files of docs/media, if any, so the README shows its images;
# and it writes a .gitignore for the release repository. Nothing else from
# this repository is exported.
#
# Then it checks the exported files twice and fails on either:
#   1. every file named in the manifest hashes to its manifest md5;
#   2. no exported file matches any pattern in scripts\secrecy-patterns.txt,
#      searched case insensitively, one regular expression per line.
# On a failure the exported folder is left as it is for review and is not
# to be published.
#
# Usage, from the repository root, with a destination outside this repository
# that does not exist yet or is empty:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\export-release.ps1 -Destination D:\release\AccountGuardian
# Optional: -Revision <tag or commit>, default HEAD.
# It never deletes, renames or moves anything.

param(
    [Parameter(Mandatory = $true)][string]$Destination,
    [string]$Revision = 'HEAD'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$patternFile = Join-Path $PSScriptRoot 'secrecy-patterns.txt'

function Invoke-GitCapture {
    param([string]$ArgumentText)
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'git'
    $startInfo.Arguments = $ArgumentText
    $startInfo.WorkingDirectory = $repositoryRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $gitProcess = [System.Diagnostics.Process]::Start($startInfo)
    $buffer = New-Object System.IO.MemoryStream
    $gitProcess.StandardOutput.BaseStream.CopyTo($buffer)
    $errorText = $gitProcess.StandardError.ReadToEnd()
    $gitProcess.WaitForExit()
    if ($gitProcess.ExitCode -ne 0) { throw ('git ' + $ArgumentText + ' failed: ' + $errorText.Trim()) }
    return ,$buffer.ToArray()
}

function Get-ByteArrayMd5 {
    param([byte[]]$Bytes)
    $hasher = [System.Security.Cryptography.MD5]::Create()
    try {
        $digest = $hasher.ComputeHash($Bytes)
    } finally {
        $hasher.Dispose()
    }
    return ([System.BitConverter]::ToString($digest)).Replace('-', '')
}

function Write-ExportedFile {
    param([string]$RelativePath, [byte[]]$Bytes)
    $targetPath = Join-Path $destinationFull ($RelativePath.Replace('/', '\'))
    $targetParent = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $targetParent
    }
    [System.IO.File]::WriteAllBytes($targetPath, $Bytes)
    Write-Host ('exported  ' + (Get-ByteArrayMd5 -Bytes $Bytes) + '  ' + $Bytes.Length.ToString().PadLeft(7) + '  ' + $RelativePath)
}

# The destination: outside this repository, absent or empty.
if ([System.IO.Path]::IsPathRooted($Destination)) { $destinationFull = [System.IO.Path]::GetFullPath($Destination) } else { $destinationFull = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Destination)) }
$repositoryFull = [System.IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\') + '\'
if (($destinationFull.TrimEnd('\') + '\').StartsWith($repositoryFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw ('The destination is inside this repository. Choose a folder outside it: ' + $destinationFull)
}
if (Test-Path -LiteralPath $destinationFull) {
    if (-not (Test-Path -LiteralPath $destinationFull -PathType Container)) { throw ('The destination is a file: ' + $destinationFull) }
    if (@(Get-ChildItem -LiteralPath $destinationFull -Force).Count -gt 0) { throw ('The destination is not empty. Choose a new or empty folder: ' + $destinationFull) }
} else {
    $null = New-Item -ItemType Directory -Path $destinationFull
}
if (-not (Test-Path -LiteralPath $patternFile -PathType Leaf)) { throw ('Pattern file not found: ' + $patternFile) }

$commitBytes = Invoke-GitCapture -ArgumentText ('rev-parse --verify "' + $Revision + '^{commit}"')
$commitHash = [System.Text.Encoding]::ASCII.GetString($commitBytes).Trim()
Write-Host ('Revision ' + $Revision + ' is commit ' + $commitHash)
Write-Host ('Destination ' + $destinationFull)

# The file list comes from the manifest at the revision.
$manifestBytes = Invoke-GitCapture -ArgumentText ('cat-file blob "' + $commitHash + ':installer/manifest.txt"')
$manifestEntries = @()
foreach ($manifestLine in ([System.Text.Encoding]::ASCII.GetString($manifestBytes) -split "`r?`n")) {
    if ($manifestLine.Trim().Length -eq 0) { continue }
    if ($manifestLine -notmatch '^([0-9A-Fa-f]{32})\s+(\S.*)$') { throw ('Manifest line not understood: ' + $manifestLine) }
    $manifestEntries += New-Object PSObject -Property @{ Hash = $Matches[1].ToUpperInvariant(); RelativePath = $Matches[2].Trim() }
}
if ($manifestEntries.Count -eq 0) { throw 'The manifest at the revision is empty.' }

$exportPaths = @()
foreach ($manifestEntry in $manifestEntries) { $exportPaths += $manifestEntry.RelativePath }
$exportPaths += @('installer/manifest.txt', 'README.md', 'LICENSE', '.gitattributes')
foreach ($relativePath in $exportPaths) {
    $blobBytes = Invoke-GitCapture -ArgumentText ('cat-file blob "' + $commitHash + ':' + $relativePath + '"')
    Write-ExportedFile -RelativePath $relativePath -Bytes $blobBytes
}
$mediaListBytes = Invoke-GitCapture -ArgumentText ('ls-tree -r --name-only "' + $commitHash + '" -- docs/media')
foreach ($mediaPath in ([System.Text.Encoding]::UTF8.GetString($mediaListBytes) -split "`r?`n")) {
    if ($mediaPath -notmatch '^docs/media/[^/]+\.(svg|gif)$') { continue }
    $mediaBytes = Invoke-GitCapture -ArgumentText ('cat-file blob "' + $commitHash + ':' + $mediaPath + '"')
    Write-ExportedFile -RelativePath $mediaPath -Bytes $mediaBytes
}
$ignoreText = "# Build output and the installer's own run files`n*.ex5`ninstaller/install-log.txt`ninstaller/compile.log`n"
Write-ExportedFile -RelativePath '.gitignore' -Bytes ([System.Text.Encoding]::ASCII.GetBytes($ignoreText))

# Check 1: the exported bytes against the manifest.
$manifestFailures = 0
foreach ($manifestEntry in $manifestEntries) {
    $exportedPath = Join-Path $destinationFull ($manifestEntry.RelativePath.Replace('/', '\'))
    $exportedHash = Get-ByteArrayMd5 -Bytes ([System.IO.File]::ReadAllBytes($exportedPath))
    if ($exportedHash -ne $manifestEntry.Hash) {
        Write-Host ('MANIFEST MISMATCH ' + $exportedHash + ' expected ' + $manifestEntry.Hash + '  ' + $manifestEntry.RelativePath) -ForegroundColor Red
        $manifestFailures++
    }
}
Write-Host ('Manifest check: ' + ($manifestEntries.Count - $manifestFailures) + ' of ' + $manifestEntries.Count + ' files match.')

# Check 2: the secrecy search over every exported file.
$patterns = @()
foreach ($patternLine in @(Get-Content -LiteralPath $patternFile)) {
    if ($patternLine.Trim().Length -gt 0) { $patterns += $patternLine.Trim() }
}
$secrecyHits = 0
foreach ($exportedItem in @(Get-ChildItem -LiteralPath $destinationFull -Recurse -File -Force)) {
    $lineNumber = 0
    foreach ($textLine in @(Get-Content -LiteralPath $exportedItem.FullName -Encoding UTF8)) {
        $lineNumber++
        foreach ($pattern in $patterns) {
            if ([regex]::IsMatch($textLine, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                $relativeName = $exportedItem.FullName.Substring($destinationFull.TrimEnd('\').Length + 1)
                Write-Host ('SECRECY HIT ' + $relativeName + ':' + $lineNumber + ' pattern ' + $pattern) -ForegroundColor Red
                $secrecyHits++
            }
        }
    }
}
Write-Host ('Secrecy search: ' + $secrecyHits + ' hits over ' + $patterns.Count + ' patterns.')

if (($manifestFailures -gt 0) -or ($secrecyHits -gt 0)) {
    Write-Host 'EXPORT FAILED. The folder is left as it is for review. Do not publish it.' -ForegroundColor Red
    exit 1
}
Write-Host ('EXPORT PASSED from commit ' + $commitHash + '. The folder is ready to be committed into the release repository.') -ForegroundColor Green
exit 0
