param(
    [ValidateSet('heist','classes','mobile')][string]$Suite = 'heist',
    [ValidateRange(4,8)][int]$Clients = 4,
    [ValidateSet('portrait','landscape')][string]$Orientation = 'portrait',
    [switch]$Visible
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
Push-Location $repo
try {
    if ($Suite -eq 'classes' -and $Clients -gt 6) { throw 'The classes suite adds two late clients; use at most six initial clients.' }
    $name = if ($Suite -eq 'mobile') { "$Suite-$Orientation" } else { $Suite }
    $sessionPath = Join-Path $repo "build/native-$name-session.json"
    if (Test-Path -LiteralPath $sessionPath) {
        $previous = Get-Content -Raw -LiteralPath $sessionPath | ConvertFrom-Json
        $active = Get-Process -Id $previous.processId -ErrorAction SilentlyContinue
        if ($active -and $active.StartTime.ToUniversalTime().ToString('o') -eq $previous.startedAt) {
            throw "The $name suite is already running (PID $($active.Id)); collect that session first."
        }
    }
    $studio = Get-ChildItem -Path "$env:LOCALAPPDATA/Roblox/Versions/*/RobloxStudioBeta.exe" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $studio) { throw 'Install Roblox Studio and sign in before running native tests.' }
    & (Join-Path $PSScriptRoot 'build.ps1')
    $runner = Join-Path $repo "build/native-$name-runner.luau"
    $runId = [guid]::NewGuid().ToString('N')
    $output = Join-Path $repo "build/native-$name-$runId.log"
    $place = Join-Path $repo "build/native-$name.rbxl"
    Copy-Item -LiteralPath (Join-Path $repo 'build/GranThriftBlotto.rbxl') -Destination $place -Force
    & python (Join-Path $PSScriptRoot 'prepare-studio-test.py') --cli --suite $Suite --clients $Clients --orientation $Orientation --output $runner
    if ($LASTEXITCODE -ne 0) { throw 'Native test preparation failed.' }
    # Quote individual paths for Windows' argument parser; these are direct EXE arguments, not shell code.
    $launchArgs = @('--task','RunScript','--localPlaceFile',('"'+$place+'"'),
        '--runScriptFile',('"'+$runner+'"'),'--outputFile',('"'+$output+'"'),'--quitAfterExecution')
    $windowStyle = if ($Visible) { 'Normal' } else { 'Hidden' }
    $process = Start-Process -FilePath $studio.FullName -ArgumentList $launchArgs -WindowStyle $windowStyle -PassThru
    $metadata = [ordered]@{
        suite = $name; runId = $runId; clients = $(if ($Suite -eq 'mobile') { 1 } else { $Clients }); processId = $process.Id
        startedAt = $process.StartTime.ToUniversalTime().ToString('o'); studioVersion = $studio.VersionInfo.ProductVersion
        placeSha256 = (Get-FileHash -LiteralPath $place -Algorithm SHA256).Hash
        output = $output; runner = $runner
    }
    $metadata | ConvertTo-Json | Set-Content -LiteralPath $sessionPath
    [pscustomobject]$metadata
} finally { Pop-Location }
