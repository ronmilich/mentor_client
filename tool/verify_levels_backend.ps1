$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    if (Test-Path -LiteralPath '.dart_tool/levels-smoke-receipt.json') {
        throw 'A previous test receipt exists. Run node tool/cleanup_levels_smoke.cjs before starting a new run.'
    }
    try {
        dart run tool/verify_levels_backend.dart
        if ($LASTEXITCODE -ne 0) { throw 'Live Levels verification failed.' }
    } finally {
        node tool/cleanup_levels_smoke.cjs
        if ($LASTEXITCODE -ne 0) { throw 'Test-data cleanup failed; see the smoke-test receipt.' }
    }
} finally { Pop-Location }
