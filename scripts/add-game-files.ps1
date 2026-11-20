<#
.SYNOPSIS
  Puts your own Steam Half-Life game files into the IPA that GitHub built.

.DESCRIPTION
  GitHub builds HalfLife-engine.ipa (engine + iOS game code, no Valve data).
  This writes HalfLife.ipa: the same app with your Steam "valve" folder inside,
  so Half-Life is built in. Nothing is uploaded anywhere.

  Skipped: PC builds of the game code (the IPA already has iOS ones), PC saves,
  and per-PC settings (config.cfg etc.), so the phone starts with clean defaults.

  Uses Windows' built-in tar.exe, which keeps the Unix permissions of the files
  the Mac build wrote (the engine binary must stay executable).

.EXAMPLE
  .\add-game-files.ps1 -Ipa "$HOME\Downloads\HalfLife-engine.ipa"
#>
param(
    [Parameter(Mandatory = $true)] [string] $Ipa,
    [string] $HalfLife = "C:\Program Files (x86)\Steam\steamapps\common\Half-Life",
    [string] $Out
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$Ipa = (Resolve-Path $Ipa).Path
$valve = Join-Path $HalfLife 'valve'
if (-not (Test-Path (Join-Path $valve 'liblist.gam'))) {
    throw "No Half-Life game files found at $valve (pass -HalfLife <your Half-Life folder>)"
}
if (-not $Out) { $Out = Join-Path (Split-Path $Ipa) 'HalfLife.ipa' }
$Out = [System.IO.Path]::GetFullPath($Out)
if ($Out -eq $Ipa) { throw "-Out must be a different file from -Ipa" }
$tar = Join-Path $env:SystemRoot 'System32\tar.exe'
if (-not (Test-Path $tar)) { throw "Windows tar.exe not found (needs Windows 10 1803 or newer)" }

# What is already in the IPA: the .app folder name, and files we must not duplicate.
$existing = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$zip = [System.IO.Compression.ZipFile]::OpenRead($Ipa)
try {
    foreach ($e in $zip.Entries) { [void]$existing.Add($e.FullName) }
    $appEntry = $zip.Entries | Where-Object { $_.FullName -match '^Payload/[^/]+\.app/' } | Select-Object -First 1
    if (-not $appEntry) { throw "$Ipa is not an iOS app (no Payload/*.app inside)" }
    $appDir = ($appEntry.FullName -split '/')[0..1] -join '/'
} finally { $zip.Dispose() }

# Stage a filtered copy of valve at <stage>\Payload\<app>.app\valve
$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("hl1-ios-" + [guid]::NewGuid().ToString('N'))
$dest = Join-Path $stage ($appDir -replace '/', '\') | Join-Path -ChildPath 'valve'
try {
    Write-Host "Copying game files from $valve ..."
    & robocopy.exe $valve $dest /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 `
        /XD dlls cl_dlls SAVE `
        /XF *.dll *.so *.dylib *.exe *.pdb config.cfg autoexec.cfg custom.hpk voice_ban.dt steam_autocloud.vdf | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }

    # Files only (no folder entries), skipping anything the iOS build already put there.
    $prefix = $stage.TrimEnd('\') + '\'
    $list = foreach ($f in Get-ChildItem -LiteralPath $dest -Recurse -File) {
        $name = $f.FullName.Substring($prefix.Length) -replace '\\', '/'
        if (-not $existing.Contains($name)) { $name }
    }
    if (-not $list) { throw "No game files were staged from $valve" }
    $listFile = Join-Path $stage 'files.txt'
    # LF line endings: tar.exe would keep a CR from CRLF as part of each name
    [System.IO.File]::WriteAllText($listFile, (($list -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))

    Write-Host ("Writing {0} with {1} game files (takes a minute or two)..." -f $Out, $list.Count)
    if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out }
    # -n -T adds just the listed files; @$Ipa then copies every entry of the original
    # app as-is. Options must come before "@archive" or tar.exe treats them as file names.
    Push-Location -LiteralPath $stage
    try { & $tar --format zip -c -f $Out -n -T $listFile "@$Ipa" }
    finally { Pop-Location }
    if ($LASTEXITCODE -ne 0) { throw "tar.exe failed with exit code $LASTEXITCODE" }
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}

"Done: {0} ({1:N0} MB)" -f $Out, ((Get-Item -LiteralPath $Out).Length / 1MB)
