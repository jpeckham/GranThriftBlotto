$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $lune = if (Test-Path '.tools/lune.exe') { (Resolve-Path '.tools/lune.exe').Path } else { 'lune' }
    & $lune run tests/run.luau
    if ($LASTEXITCODE -ne 0) { throw 'Gameplay tests failed' }
    & $lune run tests/syntax.luau
    if ($LASTEXITCODE -ne 0) { throw 'Luau compilation failed' }
    if (Test-Path '.tools/selene.exe') {
        & '.tools/selene.exe' src
        if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed' }
    }
} finally { Pop-Location }
