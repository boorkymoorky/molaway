$ErrorActionPreference = 'Stop'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE = 'false'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Push-Location (Join-Path $root 'Windows')
try {
    dotnet run --project Molaway.Core.Tests -c Release
    if ($LASTEXITCODE -ne 0) { throw 'Scheduler tests failed.' }
    $output = Join-Path $root 'build.noindex/windows-x64'
    dotnet publish Molaway.Windows -c Release -r win-x64 --self-contained true -o $output
    if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed.' }
    python scripts/collect-runtime-notices.py $output
    if ($LASTEXITCODE -ne 0) { throw 'Runtime notice collection failed.' }
    $app = Join-Path $output 'Molaway.exe'
    $process = Start-Process $app -ArgumentList '--smoke-test' -PassThru
    if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'WPF smoke test timed out.' }
    if ($process.ExitCode -ne 0) { throw 'WPF smoke test failed.' }
    Write-Output 'Windows build, core tests and WPF smoke test passed.'
} finally { Pop-Location }
