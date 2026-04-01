$ErrorActionPreference = "Stop"

Set-Location -Path (Join-Path (Split-Path -Parent $PSScriptRoot) "hailiao_flutter")

function Invoke-Step {
    param(
        [string]$Title,
        [string]$Command
    )

    Write-Host ""
    Write-Host "==> $Title" -ForegroundColor Cyan
    Write-Host $Command -ForegroundColor DarkGray
    Invoke-Expression $Command
}

Invoke-Step "Flutter pub get" "flutter pub get"
Invoke-Step "Dart format check" "dart format -o none lib test"
Invoke-Step "Dart analyze" "dart analyze lib test"
Invoke-Step "Flutter tests" "flutter test test/models test/providers test/screens"

Write-Host ""
Write-Host "Flutter verification completed." -ForegroundColor Green
