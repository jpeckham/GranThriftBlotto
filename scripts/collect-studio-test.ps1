param([Parameter(Mandatory)][string]$Session)
$ErrorActionPreference = 'Stop'
$metadata = Get-Content -Raw -LiteralPath $Session | ConvertFrom-Json
$process = Get-Process -Id $metadata.processId -ErrorAction SilentlyContinue
if ($process -and $process.StartTime.ToUniversalTime().ToString('o') -eq $metadata.startedAt) {
    Write-Output "Native $($metadata.suite) test is still running (PID $($metadata.processId))."
    return
}
$line = (Select-String -LiteralPath $metadata.output -Pattern '^GTB_MULTIPLAYER_RUNNER ' | Select-Object -Last 1).Line
if (-not $line) { throw 'Studio exited without a native test result; inspect the saved output and Studio logs.' }
$result = $line.Substring('GTB_MULTIPLAYER_RUNNER '.Length) | ConvertFrom-Json
$repo = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $repo "docs/verification/native-$($metadata.suite)-$((Get-Date).ToString('yyyy-MM-dd')).json"
New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
$evidence = [ordered]@{date=(Get-Date).ToString('yyyy-MM-dd');suite=$metadata.suite;clients=$metadata.clients;
    runId=$metadata.runId;studioVersion=$metadata.studioVersion;placeSha256=$metadata.placeSha256;result=$result.result;
    runnerSucceeded=$result.ok;limitations=@('participants are positioned by test fixtures','live Marketplace and production DataStore are not exercised')
} | ConvertTo-Json -Depth 30
[System.IO.File]::WriteAllText($destination, $evidence.Replace([string][char]13, '') + [char]10)
if (-not $result.ok -or -not $result.result.passed) { throw "Native test failed: $($result.result.error). Evidence: $destination" }
Write-Output "Native $($metadata.suite): $(@($result.result.checks).Count) checks passed. Evidence: $destination"
