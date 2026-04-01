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
Invoke-Step "Flutter model smoke" "flutter test test/models/model_dto_test.dart"
Invoke-Step "Flutter provider smoke" "flutter test test/providers/blacklist_provider_test.dart test/providers/friend_provider_test.dart test/providers/group_provider_test.dart test/providers/message_provider_test.dart test/providers/auth_provider_test.dart"
Invoke-Step "Flutter screen smoke" "flutter test test/screens/login_screen_test.dart test/screens/register_screen_test.dart test/screens/home_screen_test.dart test/screens/chat_screen_test.dart"

Write-Host ""
Write-Host "Flutter smoke verification completed." -ForegroundColor Green
