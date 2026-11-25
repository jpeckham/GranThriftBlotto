$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $lune = if (Test-Path '.tools/lune.exe') { (Resolve-Path '.tools/lune.exe').Path } else { 'lune' }
    $rojo = if (Test-Path '.tools/rojo.exe') { (Resolve-Path '.tools/rojo.exe').Path } else { 'rojo' }
    New-Item -ItemType Directory -Force -Path 'build' | Out-Null
    & $rojo build -o build/GranThriftBlotto.rbxlx
    if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed' }
    & $lune run scripts/bake.luau
    if ($LASTEXITCODE -ne 0) { throw 'Place packaging failed' }
} finally { Pop-Location }
