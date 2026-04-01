param(
    [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"

Set-Location -Path (Split-Path -Parent $PSScriptRoot)

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

if (-not $SkipCompile) {
    Invoke-Step "Compile hailiao-api" "mvn -q -pl hailiao-api -am -DskipTests compile"
    Invoke-Step "Compile hailiao-admin" "mvn -q -pl hailiao-admin -am -DskipTests compile"
}

Invoke-Step "Run hailiao-common full module tests" "mvn -q -pl hailiao-common -am test"
Invoke-Step "Run hailiao-api full module tests" "mvn -q -pl hailiao-api -am test"
Invoke-Step "Run hailiao-admin full module tests" "mvn -q -pl hailiao-admin -am test"

Write-Host ""
Write-Host "Full verification completed." -ForegroundColor Green
