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

$adminTests = @(
    "AdminManageControllerTest",
    "AuthControllerTest",
    "OperationLogManageControllerTest",
    "UserManagementControllerTest",
    "GroupManageControllerTest",
    "ReportManageControllerTest",
    "ContentAuditManageControllerTest",
    "UserManageControllerTest",
    "OrderManageControllerTest",
    "VipManageControllerTest",
    "PrettyNumberManageControllerTest",
    "DashboardControllerTest",
    "StatisticsControllerTest",
    "SystemConfigManageControllerTest",
    "MessageMonitorControllerTest"
) -join ","

$apiTests = @(
    "AuthControllerTest",
    "UserControllerTest",
    "GroupControllerTest",
    "FriendControllerTest",
    "GroupJoinRequestControllerTest",
    "MessageControllerTest",
    "ConversationControllerTest",
    "BlacklistControllerTest",
    "MessageExtControllerTest",
    "UserOnlineControllerTest",
    "ReportControllerTest",
    "ContentAuditControllerTest",
    "FileUploadControllerTest",
    "VideoCallControllerTest",
    "GroupMemberControllerTest",
    "GroupRobotControllerTest"
) -join ","

$commonTests = @(
    "ConversationServiceTest",
    "BlacklistServiceTest",
    "UserServiceTest",
    "MessageServiceTest",
    "FriendServiceTest",
    "GroupJoinRequestServiceTest",
    "GroupMemberServiceTest",
    "UserOnlineServiceTest",
    "FileUploadServiceTest",
    "ReportServiceTest",
    "ContentAuditServiceTest",
    "VideoCallServiceTest",
    "AdminUserServiceTest",
    "OperationLogServiceTest",
    "StatisticsServiceTest",
    "OrderServiceTest",
    "VipMemberServiceTest",
    "PrettyNumberServiceTest",
    "SystemConfigServiceTest",
    "GroupChatServiceTest",
    "GroupRobotServiceTest",
    "UserSessionServiceTest",
    "WebSocketNotificationServiceTest",
    "OssStorageServiceTest",
    "MessageCacheServiceTest"
) -join ","

if (-not $SkipCompile) {
    Invoke-Step "Compile hailiao-api" "mvn -q -pl hailiao-api -am -DskipTests compile"
    Invoke-Step "Compile hailiao-admin" "mvn -q -pl hailiao-admin -am -DskipTests compile"
}

Invoke-Step "Run hailiao-common targeted tests" "mvn -q -pl hailiao-common -am ""-Dtest=$commonTests"" -DfailIfNoTests=false test"
Invoke-Step "Run hailiao-api targeted tests" "mvn -q -pl hailiao-api -am ""-Dtest=$apiTests"" -DfailIfNoTests=false test"
Invoke-Step "Run hailiao-admin targeted tests" "mvn -q -pl hailiao-admin -am ""-Dtest=$adminTests"" -DfailIfNoTests=false test"

Write-Host ""
Write-Host "Targeted verification completed." -ForegroundColor Green
