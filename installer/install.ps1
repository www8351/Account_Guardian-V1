# AccountGuardian installer for MetaTrader 5 on Windows.
# Start it with install.cmd in this same folder.
#
# What it does, in this order:
#   1. Nine checks, all before anything is installed: Windows and PowerShell,
#      MetaTrader 5 found for this Windows account, the terminal to install into,
#      its data folder and program folder, the terminal closed, an existing
#      install, write access and free space, MetaEditor present, and the
#      downloaded files against installer\manifest.txt.
#   2. Compiles MQL5\Experts\AccountGuardian\AccountGuardian.mq5 in this
#      downloaded folder with the chosen terminal's own MetaEditor.
#   3. Copies the one compiled file, AccountGuardian.ex5, into the terminal's
#      MQL5\Experts\AccountGuardian folder, creating that folder if it is absent.
#   4. Prints the steps to attach the advisor to a chart.
# Every step is appended to installer\install-log.txt beside this script.
#
# What it never does: delete, rename or move any file; change any Windows or
# terminal setting; start, close or stop the terminal; use the network; attach
# the advisor to a chart; write any other file into the terminal's data folder.
# The only program it starts is the terminal's own metaeditor64.exe, to compile.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$installerFolder = $PSScriptRoot
$downloadRoot = Split-Path -Parent $installerFolder
$recordPath = Join-Path $installerFolder 'install-log.txt'
$manifestPath = Join-Path $installerFolder 'manifest.txt'
$compileLogPath = Join-Path $installerFolder 'compile.log'
$sourceFile = Join-Path $downloadRoot 'MQL5\Experts\AccountGuardian\AccountGuardian.mq5'
$includeRoot = Join-Path $downloadRoot 'MQL5'
$compiledFile = Join-Path $downloadRoot 'MQL5\Experts\AccountGuardian\AccountGuardian.ex5'
$minimumFreeBytes = 20MB
$compileTimeoutMilliseconds = 300000

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Write-InstallerRecordLine {
    param([string]$Text)
    Add-Content -LiteralPath $recordPath -Value $Text -Encoding UTF8
}

function Write-InstallerDetail {
    param([string]$Text)
    Write-Host ('    ' + $Text)
    Write-InstallerRecordLine ('    ' + $Text)
}

function Write-InstallerMessage {
    param([string]$English, [string]$Hebrew, [string]$Color = 'Gray')
    Write-Host ''
    Write-Host $English -ForegroundColor $Color
    Write-Host $Hebrew -ForegroundColor $Color
    Write-InstallerRecordLine ''
    Write-InstallerRecordLine $English
    Write-InstallerRecordLine $Hebrew
}

function Exit-InstallerWithStop {
    param([string]$English, [string]$Hebrew, [string[]]$Details = @())
    Write-InstallerMessage -English $English -Hebrew $Hebrew -Color 'Yellow'
    foreach ($detailLine in $Details) { Write-InstallerDetail $detailLine }
    Write-InstallerRecordLine ('Stopped at ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ', exit code 1.')
    exit 1
}

function Get-LineFeedNormalizedMd5 {
    param([string]$FilePath)
    $rawBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $byteEncoding = [System.Text.Encoding]::GetEncoding(28591)
    $normalizedText = $byteEncoding.GetString($rawBytes).Replace("`r`n", "`n")
    $normalizedBytes = $byteEncoding.GetBytes($normalizedText)
    $hasher = [System.Security.Cryptography.MD5]::Create()
    try {
        $digest = $hasher.ComputeHash($normalizedBytes)
    } finally {
        $hasher.Dispose()
    }
    return ([System.BitConverter]::ToString($digest)).Replace('-', '')
}

function Read-OriginProgramFolder {
    param([string]$OriginFile)
    $rawBytes = [System.IO.File]::ReadAllBytes($OriginFile)
    if ($rawBytes.Length -ge 2 -and $rawBytes[0] -eq 0xFF -and $rawBytes[1] -eq 0xFE) {
        $text = [System.Text.Encoding]::Unicode.GetString($rawBytes, 2, $rawBytes.Length - 2)
    } elseif ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
        $text = [System.Text.Encoding]::UTF8.GetString($rawBytes, 3, $rawBytes.Length - 3)
    } elseif ($rawBytes.Length -ge 2 -and $rawBytes[1] -eq 0) {
        $text = [System.Text.Encoding]::Unicode.GetString($rawBytes)
    } else {
        $text = [System.Text.Encoding]::Default.GetString($rawBytes)
    }
    $firstLine = ($text -split "`r?`n")[0]
    return $firstLine.Trim().Trim([char]0).Trim()
}

function Test-DirectoryWriteAccess {
    param([string]$DirectoryPath)
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $accountSids = @($identity.User.Value)
    foreach ($groupSid in $identity.Groups) { $accountSids += $groupSid.Value }
    $accessList = Get-Acl -LiteralPath $DirectoryPath
    $accessRules = $accessList.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])
    $createRight = [int][System.Security.AccessControl.FileSystemRights]::CreateFiles
    $allowed = $false
    $denied = $false
    foreach ($accessRule in $accessRules) {
        if ($accessRule.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::InheritOnly) { continue }
        if ($accountSids -notcontains $accessRule.IdentityReference.Value) { continue }
        if (([int]$accessRule.FileSystemRights -band $createRight) -ne $createRight) { continue }
        if ($accessRule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny) {
            $denied = $true
        } else {
            $allowed = $true
        }
    }
    return ($allowed -and -not $denied)
}

function Get-RunningTerminalCount {
    param([string]$ProgramFolder)
    $count = 0
    foreach ($processName in @('terminal64', 'metaeditor64')) {
        $expectedPath = Join-Path $ProgramFolder ($processName + '.exe')
        foreach ($runningProcess in @(Get-Process -Name $processName -ErrorAction SilentlyContinue)) {
            $processPath = $null
            try { $processPath = $runningProcess.Path } catch { $processPath = $null }
            if ($processPath -and [string]::Equals($processPath, $expectedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                $count++
            }
        }
    }
    return $count
}

try {
    if (-not (Test-Path -LiteralPath $installerFolder -PathType Container)) { throw 'installer folder not found' }
    Write-InstallerRecordLine ''
    Write-InstallerRecordLine ('==== AccountGuardian installer run started ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' local time ====')
} catch {
    Write-Host ''
    Write-Host 'The installer cannot write its record file in the downloaded folder. Extract the whole ZIP file into a folder you can write to, then run install.cmd again. Nothing was installed.' -ForegroundColor Yellow
    Write-Host 'תוכנית ההתקנה אינה יכולה לכתוב את קובץ הרישום שלה בתיקייה שהורדה. חלץ את כל קובץ ה`ZIP` לתיקייה שמותר לך לכתוב בה, והפעל שוב את `install.cmd`. דבר לא הותקן.' -ForegroundColor Yellow
    Write-Host ('    ' + $recordPath)
    exit 1
}

try {
    Write-InstallerMessage `
        -English 'AccountGuardian installer. It checks this computer, compiles the advisor with the MetaEditor of your own MetaTrader 5, and copies one file into the terminal you choose.' `
        -Hebrew 'תוכנית ההתקנה של `AccountGuardian`. היא בודקת את המחשב הזה, מהדרת את היועץ בעזרת `MetaEditor` של מטא טריידר 5 שלך, ומעתיקה קובץ אחד אל הטרמינל שתבחר.' `
        -Color 'Cyan'
    Write-InstallerMessage -English 'Every step is written to this record file:' -Hebrew 'כל שלב נרשם בקובץ הרישום הזה:'
    Write-InstallerDetail $recordPath
    Write-InstallerDetail ('Downloaded folder: ' + $downloadRoot)
    Write-InstallerDetail ('Windows user: ' + $env:USERNAME)

    # Check 1: Windows and PowerShell.
    $operatingSystem = [System.Environment]::OSVersion
    $shellVersion = $PSVersionTable.PSVersion
    $shellTooOld = ($shellVersion.Major -lt 5) -or (($shellVersion.Major -eq 5) -and ($shellVersion.Minor -lt 1))
    if (($operatingSystem.Platform -ne [System.PlatformID]::Win32NT) -or $shellTooOld) {
        Exit-InstallerWithStop `
            -English 'This installer runs only on Windows with Windows PowerShell 5.1 or later. Nothing was installed.' `
            -Hebrew 'תוכנית ההתקנה פועלת רק על חלונות עם `Windows PowerShell 5.1` ומעלה. דבר לא הותקן.' `
            -Details @(('Windows: ' + $operatingSystem.VersionString), ('PowerShell: ' + $shellVersion.ToString()))
    }
    Write-InstallerMessage -English 'Check 1 of 9, Windows and PowerShell: passed.' -Hebrew 'בדיקה 1 מתוך 9, חלונות ו`PowerShell`: עברה.' -Color 'Green'
    Write-InstallerDetail ('Windows: ' + $operatingSystem.VersionString)
    Write-InstallerDetail ('PowerShell: ' + $shellVersion.ToString() + ' ' + $PSVersionTable.PSEdition)

    # Check 2: MetaTrader 5 found, through the origin.txt of each data folder.
    $terminalRoot = Join-Path $env:APPDATA 'MetaQuotes\Terminal'
    $terminals = @()
    if (Test-Path -LiteralPath $terminalRoot -PathType Container) {
        foreach ($dataFolderItem in @(Get-ChildItem -LiteralPath $terminalRoot -Directory)) {
            $originFile = Join-Path $dataFolderItem.FullName 'origin.txt'
            if (Test-Path -LiteralPath $originFile -PathType Leaf) {
                $terminals += New-Object PSObject -Property @{
                    DataFolder = $dataFolderItem.FullName
                    ProgramFolder = (Read-OriginProgramFolder -OriginFile $originFile)
                }
            }
        }
    }
    if ($terminals.Count -eq 0) {
        Exit-InstallerWithStop `
            -English 'MetaTrader 5 was not found for this Windows account. The installer finds MetaTrader 5 through the data folders it creates under the folder below, and such a folder exists only after MetaTrader 5 has been opened at least once on this Windows account. Installing MetaTrader 5 is not enough. Open it once, close it, and run this installer again. Nothing was installed, and nothing outside the downloaded folder was changed.' `
            -Hebrew 'מטא טריידר 5 לא נמצא בחשבון החלונות הזה. תוכנית ההתקנה מאתרת את מטא טריידר 5 דרך תיקיות הנתונים שהוא יוצר בתוך התיקייה שלהלן, ותיקייה כזו קיימת רק אחרי שמטא טריידר 5 נפתח לפחות פעם אחת בחשבון החלונות הזה. התקנה בלבד אינה מספיקה. פתח אותו פעם אחת, סגור אותו, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן, ושום דבר מחוץ לתיקייה שהורדה לא שונה.' `
            -Details @($terminalRoot)
    }
    Write-InstallerMessage `
        -English ('Check 2 of 9, MetaTrader 5 found. Number of terminals on this Windows account: ' + $terminals.Count + '.') `
        -Hebrew ('בדיקה 2 מתוך 9, מטא טריידר 5 נמצא. מספר הטרמינלים בחשבון החלונות הזה: ' + $terminals.Count + '.') `
        -Color 'Green'
    for ($terminalIndex = 0; $terminalIndex -lt $terminals.Count; $terminalIndex++) {
        Write-InstallerDetail ('[' + ($terminalIndex + 1) + '] program folder: ' + $terminals[$terminalIndex].ProgramFolder)
        Write-InstallerDetail ('    data folder:    ' + $terminals[$terminalIndex].DataFolder)
    }

    # Check 3: the terminal to install into.
    if ($terminals.Count -eq 1) {
        $chosen = $terminals[0]
        Write-InstallerMessage -English 'Check 3 of 9, terminal chosen: the only one found.' -Hebrew 'בדיקה 3 מתוך 9, נבחר טרמינל: היחיד שנמצא.' -Color 'Green'
    } else {
        Write-InstallerMessage `
            -English 'Several terminals were found. Type the number of the terminal to install into, then press Enter.' `
            -Hebrew 'נמצאו כמה טרמינלים. הקלד את המספר של הטרמינל שאליו תתבצע ההתקנה, ולחץ `Enter`.'
        $chosen = $null
        for ($attempt = 1; ($attempt -le 3) -and ($null -eq $chosen); $attempt++) {
            $answer = Read-Host -Prompt 'Number / מספר'
            Write-InstallerRecordLine ('    typed: ' + $answer)
            $number = 0
            if ([int]::TryParse(([string]$answer).Trim(), [ref]$number) -and ($number -ge 1) -and ($number -le $terminals.Count)) {
                $chosen = $terminals[$number - 1]
                Write-InstallerMessage -English ('Check 3 of 9, terminal chosen: number ' + $number + '.') -Hebrew ('בדיקה 3 מתוך 9, נבחר טרמינל: מספר ' + $number + '.') -Color 'Green'
            } else {
                Write-InstallerMessage -English 'That is not one of the listed numbers.' -Hebrew 'זה אינו אחד מהמספרים שברשימה.'
            }
        }
        if ($null -eq $chosen) {
            Exit-InstallerWithStop -English 'No terminal was chosen. Nothing was installed.' -Hebrew 'לא נבחר טרמינל. דבר לא הותקן.'
        }
    }
    $dataFolder = $chosen.DataFolder
    $programFolder = $chosen.ProgramFolder
    Write-InstallerDetail ('Program folder: ' + $programFolder)
    Write-InstallerDetail ('Data folder: ' + $dataFolder)

    # Check 4: the data folder and the program folder.
    $expertsFolder = Join-Path $dataFolder 'MQL5\Experts'
    $terminalProgram = Join-Path $programFolder 'terminal64.exe'
    if (-not (Test-Path -LiteralPath $expertsFolder -PathType Container)) {
        Exit-InstallerWithStop `
            -English 'The chosen data folder has no MQL5\Experts folder. This usually means the terminal runs in portable mode and keeps its files inside its program folder. Portable installs are outside what this installer does. The manual route: in the terminal choose File, then Open Data Folder; copy the folders MQL5\Experts\AccountGuardian and MQL5\Include\AccountGuardian from this download into the matching folders there; open AccountGuardian.mq5 in MetaEditor and compile it; restart the terminal. Nothing was installed.' `
            -Hebrew 'בתיקיית הנתונים שנבחרה אין תיקייה `MQL5\Experts`. בדרך כלל פירוש הדבר שהטרמינל פועל במצב נייד ושומר את קבציו בתוך תיקיית התוכנה שלו. התקנה במצב נייד אינה חלק ממה שתוכנית ההתקנה הזו עושה. הדרך הידנית: בטרמינל בחר `File` ואז `Open Data Folder`; העתק את התיקיות `MQL5\Experts\AccountGuardian` ו`MQL5\Include\AccountGuardian` מההורדה הזו אל התיקיות המקבילות שם; פתח את `AccountGuardian.mq5` בעורך `MetaEditor` והדר אותו; הפעל מחדש את הטרמינל. דבר לא הותקן.' `
            -Details @($expertsFolder)
    }
    if (-not (Test-Path -LiteralPath $terminalProgram -PathType Leaf)) {
        Exit-InstallerWithStop `
            -English 'The program folder named by this terminal''s origin.txt does not hold terminal64.exe. The terminal may have been moved or removed. Open the terminal once from where it is now, or choose another terminal, then run the installer again. Nothing was installed.' `
            -Hebrew 'תיקיית התוכנה שהקובץ `origin.txt` של הטרמינל הזה נוקב בה אינה מכילה את `terminal64.exe`. ייתכן שהטרמינל הועבר או הוסר. פתח את הטרמינל פעם אחת מהמקום שבו הוא נמצא עכשיו, או בחר טרמינל אחר, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.' `
            -Details @($terminalProgram)
    }
    Write-InstallerMessage -English 'Check 4 of 9, data folder and program folder: passed.' -Hebrew 'בדיקה 4 מתוך 9, תיקיית הנתונים ותיקיית התוכנה: עברה.' -Color 'Green'

    # Check 5: the chosen terminal is not running.
    $runningCount = Get-RunningTerminalCount -ProgramFolder $programFolder
    if ($runningCount -gt 0) {
        Exit-InstallerWithStop `
            -English 'MetaTrader 5 or its MetaEditor is running from the chosen program folder. Close the terminal and MetaEditor, then run this installer again. The installer never closes them for you. Nothing was installed.' `
            -Hebrew 'מטא טריידר 5 או עורך ה`MetaEditor` שלו פועלים מתוך תיקיית התוכנה שנבחרה. סגור את הטרמינל ואת `MetaEditor`, והפעל שוב את תוכנית ההתקנה. תוכנית ההתקנה לעולם אינה סוגרת אותם בשבילך. דבר לא הותקן.' `
            -Details @($programFolder)
    }
    Write-InstallerMessage -English 'Check 5 of 9, terminal closed: passed.' -Hebrew 'בדיקה 5 מתוך 9, הטרמינל סגור: עברה.' -Color 'Green'

    # Check 6: an existing install, and anything unknown at the target.
    $targetFolder = Join-Path $expertsFolder 'AccountGuardian'
    $targetFile = Join-Path $targetFolder 'AccountGuardian.ex5'
    $isUpgrade = $false
    if (Test-Path -LiteralPath $targetFolder) {
        if (-not (Test-Path -LiteralPath $targetFolder -PathType Container)) {
            Exit-InstallerWithStop `
                -English 'Where the installer puts its folder there is a file it does not know, listed below. The installer does not overwrite, move or delete it. Move it away yourself, or delete it if you know what it is, then run the installer again. Nothing was installed.' `
                -Hebrew 'במקום שבו תוכנית ההתקנה יוצרת את התיקייה שלה יש קובץ שהיא אינה מכירה, והוא מופיע להלן. תוכנית ההתקנה אינה דורסת, מעבירה או מוחקת אותו. העבר אותו בעצמך, או מחק אותו אם אתה יודע מהו, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.' `
                -Details @($targetFolder)
        }
        $unknownEntries = @()
        foreach ($entry in @(Get-ChildItem -LiteralPath $targetFolder -Force)) {
            if ($entry.PSIsContainer -or ($entry.Name -ne 'AccountGuardian.ex5')) { $unknownEntries += $entry.FullName }
        }
        if ($unknownEntries.Count -gt 0) {
            Exit-InstallerWithStop `
                -English 'The folder the advisor is installed into holds something the installer does not know, listed below. The installer does not overwrite, move or delete it. Move it out of that folder yourself, or delete it if you know what it is, then run the installer again. Nothing was installed.' `
                -Hebrew 'התיקייה שאליה היועץ מותקן מכילה משהו שתוכנית ההתקנה אינה מכירה, והוא מופיע להלן. תוכנית ההתקנה אינה דורסת, מעבירה או מוחקת אותו. העבר אותו בעצמך אל מחוץ לתיקייה, או מחק אותו אם אתה יודע מהו, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.' `
                -Details $unknownEntries
        }
        if (Test-Path -LiteralPath $targetFile -PathType Leaf) { $isUpgrade = $true }
    }
    if ($isUpgrade) {
        $existingFile = Get-Item -LiteralPath $targetFile
        $existingHash = Get-FileHash -Algorithm MD5 -LiteralPath $targetFile
        Write-InstallerMessage `
            -English 'Check 6 of 9, existing install: AccountGuardian.ex5 is already installed and will be replaced by the new build. This is an upgrade.' `
            -Hebrew 'בדיקה 6 מתוך 9, התקנה קיימת: הקובץ `AccountGuardian.ex5` כבר מותקן ויוחלף בבנייה החדשה. זהו שדרוג.' `
            -Color 'Green'
        Write-InstallerDetail ('Installed file: ' + $targetFile)
        Write-InstallerDetail ('Installed md5: ' + $existingHash.Hash + ', ' + $existingFile.Length + ' bytes, written ' + $existingFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
    } else {
        Write-InstallerMessage -English 'Check 6 of 9, existing install: none. This is a fresh install.' -Hebrew 'בדיקה 6 מתוך 9, התקנה קיימת: אין. זו התקנה חדשה.' -Color 'Green'
    }
    $earlierTraces = @()
    foreach ($tracePath in @((Join-Path $dataFolder 'MQL5\Include\AccountGuardian'), (Join-Path $dataFolder 'MQL5\Scripts\AccountGuardian'), (Join-Path $expertsFolder 'AccountGuardian.mq5'), (Join-Path $expertsFolder 'AccountGuardian.ex5'))) {
        if (Test-Path -LiteralPath $tracePath) { $earlierTraces += $tracePath }
    }
    if ($earlierTraces.Count -gt 0) {
        Write-InstallerMessage `
            -English 'Found in the data folder from an earlier manual install. The installer leaves these untouched:' `
            -Hebrew 'נמצאו בתיקיית הנתונים מהתקנה ידנית קודמת. תוכנית ההתקנה משאירה אותם ללא שינוי:'
        foreach ($tracePath in $earlierTraces) { Write-InstallerDetail $tracePath }
    }

    # Check 7: write access and free space.
    if (Test-Path -LiteralPath $targetFolder -PathType Container) { $writeProbeFolder = $targetFolder } else { $writeProbeFolder = $expertsFolder }
    $writeProbeFolders = @($writeProbeFolder, (Split-Path -Parent $compiledFile), $installerFolder)
    foreach ($probeFolder in $writeProbeFolders) {
        if (-not (Test-DirectoryWriteAccess -DirectoryPath $probeFolder)) {
            Exit-InstallerWithStop `
                -English 'Windows does not allow this account to write to the folder below. Nothing was installed.' `
                -Hebrew 'חלונות אינו מתיר לחשבון הזה לכתוב לתיקייה שלהלן. דבר לא הותקן.' `
                -Details @($probeFolder)
        }
    }
    if ($isUpgrade) {
        $existingItem = Get-Item -LiteralPath $targetFile
        if ($existingItem.IsReadOnly) {
            Exit-InstallerWithStop `
                -English 'The installed AccountGuardian.ex5 is marked read only, so it cannot be replaced. Clear its read only mark in its file properties, then run the installer again. Nothing was installed.' `
                -Hebrew 'הקובץ המותקן `AccountGuardian.ex5` מסומן לקריאה בלבד, ולכן אי אפשר להחליף אותו. הסר את הסימון לקריאה בלבד במאפייני הקובץ, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.' `
                -Details @($targetFile)
        }
    }
    foreach ($spacePath in @($dataFolder, $downloadRoot)) {
        $driveRoot = [System.IO.Path]::GetPathRoot($spacePath)
        $driveInfo = New-Object System.IO.DriveInfo($driveRoot)
        Write-InstallerDetail ('Free space on ' + $driveRoot + ': ' + [math]::Floor($driveInfo.AvailableFreeSpace / 1MB) + ' MB')
        if ($driveInfo.AvailableFreeSpace -lt $minimumFreeBytes) {
            Exit-InstallerWithStop `
                -English 'There is not enough free disk space on the drive below. At least 20 MB are needed. Nothing was installed.' `
                -Hebrew 'אין מספיק מקום פנוי בכונן שלהלן. נדרשים לפחות 20 מגה בייט. דבר לא הותקן.' `
                -Details @($driveRoot)
        }
    }
    Write-InstallerMessage -English 'Check 7 of 9, write access and free space: passed.' -Hebrew 'בדיקה 7 מתוך 9, הרשאת כתיבה ומקום פנוי: עברה.' -Color 'Green'

    # Check 8: MetaEditor in the program folder.
    $metaEditor = Join-Path $programFolder 'metaeditor64.exe'
    if (-not (Test-Path -LiteralPath $metaEditor -PathType Leaf)) {
        Exit-InstallerWithStop `
            -English 'MetaEditor, metaeditor64.exe, was not found in the terminal''s program folder. The installer compiles the advisor with the terminal''s own MetaEditor. Repair or reinstall MetaTrader 5, then run the installer again. Nothing was installed.' `
            -Hebrew 'העורך `MetaEditor`, הקובץ `metaeditor64.exe`, לא נמצא בתיקיית התוכנה של הטרמינל. תוכנית ההתקנה מהדרת את היועץ בעזרת `MetaEditor` של הטרמינל עצמו. תקן או התקן מחדש את מטא טריידר 5, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.' `
            -Details @($metaEditor)
    }
    Write-InstallerMessage -English 'Check 8 of 9, MetaEditor found: passed.' -Hebrew 'בדיקה 8 מתוך 9, העורך `MetaEditor` נמצא: עברה.' -Color 'Green'
    Write-InstallerDetail ('MetaEditor: ' + $metaEditor)

    # Check 9: the downloaded files against installer\manifest.txt.
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
        Exit-InstallerWithStop `
            -English 'The downloaded folder is incomplete. Extract the whole ZIP file into one folder first, then run install.cmd from the installer folder inside it. Nothing was installed.' `
            -Hebrew 'התיקייה שהורדה אינה שלמה. חלץ קודם את כל קובץ ה`ZIP` לתיקייה אחת, ואז הפעל את `install.cmd` מתוך תיקיית `installer` שבתוכה. דבר לא הותקן.' `
            -Details @($manifestPath, $sourceFile)
    }
    $manifestEntries = @()
    foreach ($manifestLine in @(Get-Content -LiteralPath $manifestPath)) {
        if ($manifestLine.Trim().Length -eq 0) { continue }
        if ($manifestLine -notmatch '^([0-9A-Fa-f]{32})\s+(\S.*)$') {
            Exit-InstallerWithStop `
                -English 'The checksum list installer\manifest.txt is damaged. Download the ZIP file again, extract all of it, and run the installer again. Nothing was installed.' `
                -Hebrew 'רשימת טביעות הבדיקה `installer\manifest.txt` פגומה. הורד שוב את קובץ ה`ZIP`, חלץ את כולו, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.' `
                -Details @($manifestLine)
        }
        $manifestEntries += New-Object PSObject -Property @{ Hash = $Matches[1].ToUpperInvariant(); RelativePath = $Matches[2].Trim() }
    }
    if ($manifestEntries.Count -eq 0) {
        Exit-InstallerWithStop `
            -English 'The checksum list installer\manifest.txt is empty. Download the ZIP file again, extract all of it, and run the installer again. Nothing was installed.' `
            -Hebrew 'רשימת טביעות הבדיקה `installer\manifest.txt` ריקה. הורד שוב את קובץ ה`ZIP`, חלץ את כולו, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.'
    }
    $manifestFailures = @()
    foreach ($manifestEntry in $manifestEntries) {
        $entryPath = Join-Path $downloadRoot ($manifestEntry.RelativePath.Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
            $manifestFailures += ('MISSING  ' + $manifestEntry.RelativePath)
            Write-InstallerRecordLine ('    MISSING  ' + $manifestEntry.RelativePath)
            continue
        }
        $actualHash = Get-LineFeedNormalizedMd5 -FilePath $entryPath
        if ($actualHash -eq $manifestEntry.Hash) {
            Write-InstallerRecordLine ('    OK       ' + $actualHash + '  ' + $manifestEntry.RelativePath)
        } else {
            $manifestFailures += ('MISMATCH ' + $actualHash + ' expected ' + $manifestEntry.Hash + '  ' + $manifestEntry.RelativePath)
            Write-InstallerRecordLine ('    MISMATCH ' + $actualHash + ' expected ' + $manifestEntry.Hash + '  ' + $manifestEntry.RelativePath)
        }
    }
    if ($manifestFailures.Count -gt 0) {
        Exit-InstallerWithStop `
            -English 'The downloaded files do not match the checksums shipped with them. The download may be damaged or changed. Download the ZIP file again, extract all of it, and run the installer again. Nothing was installed.' `
            -Hebrew 'הקבצים שהורדו אינם תואמים לטביעות הבדיקה שנשלחו איתם. ייתכן שההורדה פגומה או שונתה. הורד שוב את קובץ ה`ZIP`, חלץ את כולו, והפעל שוב את תוכנית ההתקנה. דבר לא הותקן.' `
            -Details $manifestFailures
    }
    Write-InstallerMessage `
        -English ('Check 9 of 9, downloaded files match their checksums: passed, ' + $manifestEntries.Count + ' files.') `
        -Hebrew ('בדיקה 9 מתוך 9, הקבצים שהורדו תואמים לטביעות הבדיקה שלהם: עברה. מספר הקבצים: ' + $manifestEntries.Count + '.') `
        -Color 'Green'

    # Compile in the downloaded folder. The process exit code is recorded and
    # not used: the Result line of the log and a fresh ex5 are what count.
    Write-InstallerMessage -English 'Compiling the advisor with MetaEditor. This takes a few seconds.' -Hebrew 'מהדר את היועץ בעזרת `MetaEditor`. זה לוקח שניות ספורות.'
    $compileStart = Get-Date
    $compileArguments = '/compile:"' + $sourceFile + '" /include:"' + $includeRoot + '" /log:"' + $compileLogPath + '"'
    Write-InstallerDetail ('Command: "' + $metaEditor + '" ' + $compileArguments)
    $compileProcess = Start-Process -FilePath $metaEditor -ArgumentList $compileArguments -PassThru -WindowStyle Hidden
    $processHandle = $compileProcess.Handle
    if (-not $compileProcess.WaitForExit($compileTimeoutMilliseconds)) {
        Exit-InstallerWithStop `
            -English 'MetaEditor did not finish within five minutes. Close MetaEditor if it is open, then run the installer again. Nothing was copied into the terminal.' `
            -Hebrew 'העורך `MetaEditor` לא סיים בתוך חמש דקות. סגור את `MetaEditor` אם הוא פתוח, והפעל שוב את תוכנית ההתקנה. דבר לא הועתק אל הטרמינל.'
    }
    Write-InstallerDetail ('MetaEditor exit code, recorded and not used: ' + $compileProcess.ExitCode)
    $compileLogItem = $null
    if (Test-Path -LiteralPath $compileLogPath -PathType Leaf) { $compileLogItem = Get-Item -LiteralPath $compileLogPath }
    if (($null -eq $compileLogItem) -or ($compileLogItem.LastWriteTime -lt $compileStart.AddSeconds(-2))) {
        Exit-InstallerWithStop `
            -English 'MetaEditor did not write a new compile log. Nothing was copied into the terminal.' `
            -Hebrew 'העורך `MetaEditor` לא כתב יומן הידור חדש. דבר לא הועתק אל הטרמינל.' `
            -Details @($compileLogPath)
    }
    $compileLines = @(Get-Content -LiteralPath $compileLogPath -Encoding Unicode)
    foreach ($compileLine in $compileLines) {
        if ($compileLine -match 'including') { Write-InstallerRecordLine ('    ' + $compileLine.Trim()) }
    }
    $resultLine = $null
    foreach ($compileLine in $compileLines) {
        if ($compileLine -match 'Result:\s*(\d+)\s+errors?,\s*(\d+)\s+warnings?') { $resultLine = $compileLine.Trim() }
    }
    if ($null -eq $resultLine) {
        Exit-InstallerWithStop `
            -English 'The compile log has no Result line. Nothing was copied into the terminal.' `
            -Hebrew 'ביומן ההידור אין שורת `Result`. דבר לא הועתק אל הטרמינל.' `
            -Details @($compileLogPath)
    }
    $null = $resultLine -match 'Result:\s*(\d+)\s+errors?,\s*(\d+)\s+warnings?'
    $errorCount = [int]$Matches[1]
    $warningCount = [int]$Matches[2]
    Write-InstallerDetail $resultLine
    if ($errorCount -gt 0) {
        $errorLines = @()
        foreach ($compileLine in $compileLines) {
            if (($compileLine -match '\berror\b') -and ($compileLine -notmatch 'Result:')) { $errorLines += $compileLine.Trim() }
        }
        $errorLines += $resultLine
        Exit-InstallerWithStop `
            -English 'The compile reported errors, listed below. Nothing was copied into the terminal.' `
            -Hebrew 'ההידור דיווח על שגיאות, והן מופיעות להלן. דבר לא הועתק אל הטרמינל.' `
            -Details $errorLines
    }
    if ($warningCount -gt 0) {
        foreach ($compileLine in $compileLines) {
            if ($compileLine -match '\bwarning\b') { Write-InstallerDetail $compileLine.Trim() }
        }
    }
    $compiledItem = $null
    if (Test-Path -LiteralPath $compiledFile -PathType Leaf) { $compiledItem = Get-Item -LiteralPath $compiledFile }
    if (($null -eq $compiledItem) -or ($compiledItem.LastWriteTime -lt $compileStart.AddSeconds(-2))) {
        Exit-InstallerWithStop `
            -English 'MetaEditor reported no errors but wrote no new AccountGuardian.ex5. Nothing was copied into the terminal.' `
            -Hebrew 'העורך `MetaEditor` לא דיווח על שגיאות אך לא כתב קובץ `AccountGuardian.ex5` חדש. דבר לא הועתק אל הטרמינל.' `
            -Details @($compiledFile)
    }
    $builtHash = Get-FileHash -Algorithm MD5 -LiteralPath $compiledFile
    Write-InstallerMessage -English 'Compile finished with no errors.' -Hebrew 'ההידור הסתיים ללא שגיאות.' -Color 'Green'
    Write-InstallerDetail ('Compiled file: ' + $compiledFile)
    Write-InstallerDetail ('Compiled md5: ' + $builtHash.Hash + ', ' + $compiledItem.Length + ' bytes, written ' + $compiledItem.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))

    # The one write into the data folder, after one more running check.
    if ((Get-RunningTerminalCount -ProgramFolder $programFolder) -gt 0) {
        Exit-InstallerWithStop `
            -English 'MetaTrader 5 or its MetaEditor was started while the installer ran. Close them, then run the installer again. Nothing was copied into the terminal.' `
            -Hebrew 'מטא טריידר 5 או העורך `MetaEditor` שלו הופעלו בזמן שתוכנית ההתקנה רצה. סגור אותם, והפעל שוב את תוכנית ההתקנה. דבר לא הועתק אל הטרמינל.' `
            -Details @($programFolder)
    }
    if (-not (Test-Path -LiteralPath $targetFolder -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $targetFolder
        Write-InstallerDetail ('Created folder: ' + $targetFolder)
    }
    Copy-Item -LiteralPath $compiledFile -Destination $targetFile -Force
    $landedHash = Get-FileHash -Algorithm MD5 -LiteralPath $targetFile
    $landedItem = Get-Item -LiteralPath $targetFile
    if ($landedHash.Hash -ne $builtHash.Hash) {
        Exit-InstallerWithStop `
            -English 'The copied file does not match the compiled file. Run the installer again.' `
            -Hebrew 'הקובץ שהועתק אינו תואם לקובץ שהודר. הפעל שוב את תוכנית ההתקנה.' `
            -Details @(('Landed md5: ' + $landedHash.Hash), ('Compiled md5: ' + $builtHash.Hash))
    }
    Write-InstallerMessage -English 'Copied the compiled advisor into the terminal. The md5 of the copied file:' -Hebrew 'היועץ המהודר הועתק אל הטרמינל. טביעת ה`md5` של הקובץ שהועתק:' -Color 'Green'
    Write-InstallerDetail ('Landed file: ' + $targetFile)
    Write-InstallerDetail ('Landed md5: ' + $landedHash.Hash + ', ' + $landedItem.Length + ' bytes')

    # The attach is by hand. The steps, in order.
    Write-InstallerMessage -English 'Now attach the advisor by hand, in this order:' -Hebrew 'עכשיו חבר את היועץ ידנית, בסדר הזה:' -Color 'Cyan'
    Write-InstallerMessage -English '1. Open MetaTrader 5, the terminal you chose above.' -Hebrew '1. פתח את מטא טריידר 5, הטרמינל שבחרת למעלה.'
    Write-InstallerMessage -English '2. Log in to your trading account.' -Hebrew '2. התחבר לחשבון המסחר שלך.'
    Write-InstallerMessage -English '3. Make sure the Algo Trading button in the toolbar is on, shown green.' -Hebrew '3. ודא שהכפתור `Algo Trading` בסרגל הכלים פועל ומוצג בירוק.'
    Write-InstallerMessage -English '4. In the Navigator window, under Expert Advisors, open the AccountGuardian folder and drag AccountGuardian onto one chart. Any symbol, any timeframe, one chart only.' -Hebrew '4. בחלון `Navigator`, תחת `Expert Advisors`, פתח את התיקייה `AccountGuardian` וגרור את `AccountGuardian` אל גרף אחד. כל סימול, כל מסגרת זמן, גרף אחד בלבד.'
    Write-InstallerMessage -English '5. In the inputs dialog, review the two daily loss limits. The defaults are the largest value of each list, 5.50 percent and 200 in account currency. Set your own, then press OK.' -Hebrew '5. בחלון הקלטים, עבור על שתי מגבלות ההפסד היומי. ברירות המחדל הן הערך הגדול ביותר בכל רשימה: 5.50 אחוז, וסכום של 200 במטבע החשבון. קבע את הערכים שלך, ולחץ `OK`.'
    Write-InstallerMessage -English '6. Open the Experts tab at the bottom of the terminal and read two lines, init|build= and limits accepted|. Only after you have read limits accepted, restart the terminal if you want to.' -Hebrew '6. פתח את הלשונית `Experts` בתחתית הטרמינל וקרא שתי שורות, `init|build=` ו`limits accepted|`. רק אחרי שקראת את `limits accepted`, הפעל מחדש את הטרמינל אם תרצה.'
    if ($isUpgrade) {
        Write-InstallerMessage `
            -English 'UPGRADE: if AccountGuardian is already on a chart, it keeps running the old build until it is attached again. Remove it from its chart, attach it again, and read init|build= and limits accepted in the Experts tab BEFORE any terminal restart. A refused start unloads the advisor, and a restart after that comes up with no guardian at all.' `
            -Hebrew 'שדרוג: אם `AccountGuardian` כבר נמצא על גרף, הוא ממשיך להריץ את הבנייה הישנה עד שהוא מחובר מחדש. הסר אותו מהגרף שלו, חבר אותו שוב, וקרא את `init|build=` ואת `limits accepted` בלשונית `Experts` לפני כל הפעלה מחדש של הטרמינל. עלייה שנדחתה פורקת את היועץ, והפעלה מחדש אחרי כן עולה בלי שומר בכלל.' `
            -Color 'Yellow'
    }
    Write-InstallerMessage `
        -English 'WARNING, THE FIRST ATTACH: the advisor measures the whole day from 01:00 server time, trades made before it was attached included. If the account is already past today''s limit, the advisor locks at once, and every position on the account is closed and every pending order deleted, other advisors'' and the phone''s included. Try it on a demo account first.' `
        -Hebrew 'אזהרה, החיבור הראשון: היועץ מודד את היום כולו מהשעה 01:00 בשעון השרת, כולל עסקאות שנעשו לפני שחובר. אם החשבון כבר עבר היום את המגבלה, היועץ ננעל מיד, וכל פוזיציה בחשבון נסגרת וכל פקודה ממתינה נמחקת, כולל של יועצים אחרים ושל הטלפון. נסה אותו קודם על חשבון דמו.' `
        -Color 'Yellow'
    Write-InstallerMessage -English 'The installer has finished. It changed one file in the terminal''s data folder:' -Hebrew 'תוכנית ההתקנה הסתיימה. היא שינתה קובץ אחד בתיקיית הנתונים של הטרמינל:' -Color 'Cyan'
    Write-InstallerDetail $targetFile
    Write-InstallerRecordLine ('Finished at ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ', exit code 0.')
    exit 0
} catch {
    Write-InstallerMessage `
        -English 'The installer stopped on an unexpected error, shown below. Every step this record lists as done was done; nothing after it was.' `
        -Hebrew 'תוכנית ההתקנה נעצרה בשגיאה לא צפויה, המוצגת להלן. כל שלב שהרישום הזה מציין כבוצע אכן בוצע; דבר אחריו לא בוצע.' `
        -Color 'Red'
    Write-InstallerDetail ($_.Exception.Message)
    Write-InstallerRecordLine ('Stopped at ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ', exit code 2.')
    exit 2
}
