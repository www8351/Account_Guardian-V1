# make-manifest.ps1
# Writes installer\manifest.txt, the checksum list the installer verifies before
# it compiles anything. Each line is the md5 of one shipped file exactly as git
# stores it at the given revision, with LF line endings, which is also how a
# GitHub ZIP download delivers it, then two spaces, then the path.
#
# Run it from the repository root after install.ps1 and install.cmd are
# committed, then commit the manifest it writes:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\make-manifest.ps1
# It reads git objects and writes the one output file. Nothing else.

param(
    [string]$Revision = 'HEAD',
    [string]$OutputPath = 'installer\manifest.txt'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# The files a customer receives and the installer checks. The vectors scripts
# under MQL5/Scripts are not shipped.
$shippedFiles = @(
    'MQL5/Experts/AccountGuardian/AccountGuardian.mq5',
    'MQL5/Include/AccountGuardian/Clock.mqh',
    'MQL5/Include/AccountGuardian/Log.mqh',
    'MQL5/Include/AccountGuardian/Persist.mqh',
    'MQL5/Include/AccountGuardian/Pnl.mqh',
    'MQL5/Include/AccountGuardian/State.mqh',
    'MQL5/Include/AccountGuardian/Sweep.mqh',
    'MQL5/Include/AccountGuardian/SweepPolicy.mqh',
    'installer/install.cmd',
    'installer/install.ps1'
)

function Get-GitBlobBytes {
    param([string]$BlobRevision, [string]$RelativePath)
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'git'
    $startInfo.Arguments = 'cat-file blob "' + $BlobRevision + ':' + $RelativePath + '"'
    $startInfo.WorkingDirectory = (Get-Location).Path
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $gitProcess = [System.Diagnostics.Process]::Start($startInfo)
    $buffer = New-Object System.IO.MemoryStream
    $gitProcess.StandardOutput.BaseStream.CopyTo($buffer)
    $errorText = $gitProcess.StandardError.ReadToEnd()
    $gitProcess.WaitForExit()
    if ($gitProcess.ExitCode -ne 0) { throw ('git cat-file failed for ' + $RelativePath + ': ' + $errorText.Trim()) }
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

$manifestLines = @()
foreach ($relativePath in $shippedFiles) {
    $blobBytes = Get-GitBlobBytes -BlobRevision $Revision -RelativePath $relativePath
    $manifestLines += ((Get-ByteArrayMd5 -Bytes $blobBytes) + '  ' + $relativePath)
}
if ([System.IO.Path]::IsPathRooted($OutputPath)) { $outputFullPath = $OutputPath } else { $outputFullPath = Join-Path (Get-Location).Path $OutputPath }
$manifestText = ($manifestLines -join "`n") + "`n"
[System.IO.File]::WriteAllText($outputFullPath, $manifestText, [System.Text.Encoding]::ASCII)
Write-Host ('Revision: ' + $Revision)
Write-Host ('Written: ' + $outputFullPath)
foreach ($manifestLine in $manifestLines) { Write-Host $manifestLine }
