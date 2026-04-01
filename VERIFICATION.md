# Verification Notes

This repository currently has limited automated verification coverage in-tree.

Current state:
- Minimal backend smoke tests are now present under:
  - [hailiao-api](/E:/IM/ImServer/hailiao-api)
  - [hailiao-admin](/E:/IM/ImServer/hailiao-admin)
- Flutter static analysis was previously attempted, but the local environment often timed out.
- Maven compilation was previously attempted, but the local Maven repository path was not writable in this environment.

Minimal smoke tests now available:
- [HailiaoApiApplicationSmokeTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/HailiaoApiApplicationSmokeTest.java)
- [HailiaoAdminApplicationSmokeTest.java](/E:/IM/ImServer/hailiao-admin/src/test/java/com/hailiao/admin/HailiaoAdminApplicationSmokeTest.java)

Focused unit test now available:
- [AuthControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/AuthControllerTest.java)
- [UserControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/UserControllerTest.java)
- [GroupControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/GroupControllerTest.java)
- [FriendControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/FriendControllerTest.java)
- [GroupJoinRequestControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/GroupJoinRequestControllerTest.java)
- [MessageControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/MessageControllerTest.java)
- [ConversationControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/ConversationControllerTest.java)
- [BlacklistControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/BlacklistControllerTest.java)
- [MessageExtControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/MessageExtControllerTest.java)
- [UserOnlineControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/UserOnlineControllerTest.java)
- [ReportControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/ReportControllerTest.java)
- [ContentAuditControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/ContentAuditControllerTest.java)
- [FileUploadControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/FileUploadControllerTest.java)
- [VideoCallControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/VideoCallControllerTest.java)
- [GroupMemberControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/GroupMemberControllerTest.java)
- [GroupRobotControllerTest.java](/E:/IM/ImServer/hailiao-api/src/test/java/com/hailiao/api/controller/GroupRobotControllerTest.java)
- [ConversationServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/ConversationServiceTest.java)
- [BlacklistServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/BlacklistServiceTest.java)
- [UserServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/UserServiceTest.java)
- [MessageServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/MessageServiceTest.java)
- [FriendServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/FriendServiceTest.java)
- [GroupJoinRequestServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/GroupJoinRequestServiceTest.java)
- [GroupMemberServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/GroupMemberServiceTest.java)
- [UserOnlineServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/UserOnlineServiceTest.java)
- [FileUploadServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/FileUploadServiceTest.java)
- [ReportServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/ReportServiceTest.java)
- [ContentAuditServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/ContentAuditServiceTest.java)
- [VideoCallServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/VideoCallServiceTest.java)
- [AdminUserServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/AdminUserServiceTest.java)
- [OperationLogServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/OperationLogServiceTest.java)
- [StatisticsServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/StatisticsServiceTest.java)
- [OrderServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/OrderServiceTest.java)
- [VipMemberServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/VipMemberServiceTest.java)
- [PrettyNumberServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/PrettyNumberServiceTest.java)
- [SystemConfigServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/SystemConfigServiceTest.java)
- [GroupChatServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/GroupChatServiceTest.java)
- [GroupRobotServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/GroupRobotServiceTest.java)
- [UserSessionServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/UserSessionServiceTest.java)
- [WebSocketNotificationServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/WebSocketNotificationServiceTest.java)
- [OssStorageServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/OssStorageServiceTest.java)
- [MessageCacheServiceTest.java](/E:/IM/ImServer/hailiao-common/src/test/java/com/hailiao/common/service/MessageCacheServiceTest.java)
- [UserManagementControllerTest.java](/E:/IM/ImServer/hailiao-admin/src/test/java/com/hailiao/admin/controller/UserManagementControllerTest.java)
- [AdminManageControllerTest.java](/E:/IM/ImServer/hailiao-admin/src/test/java/com/hailiao/admin/controller/AdminManageControllerTest.java)
- [AuthControllerTest.java](/E:/IM/ImServer/hailiao-admin/src/test/java/com/hailiao/admin/controller/AuthControllerTest.java)

Manual admin smoke path worth checking:
- log in to `hailiao-admin`
- perform one write action such as updating a config or banning a user
- verify:
  - `/admin/operation-log/list`
  - `/admin/operation-log/stats`
  - `/admin/operation-log/modules`
  - `/admin/operation-log/export`
  - `/admin/group/list`
  - `/admin/dashboard/stats`
  - `/admin/dashboard/realtime`
  - `/admin/statistics/system`
  - `/admin/statistics/messages`
  - `/admin/system-config/list`
  - `/admin/messages`
  - `/admin/user/list`
  - `/admin/user/stats`
  - `/admin/order/list`
  - `/admin/order/stats`
  - `/admin/vip/list`
  - `/admin/vip/stats`
  - `/admin/pretty-number/list`
  - `/admin/pretty-number/stats`
  - `/admin/report/list`
  - `/admin/content-audit/list`
  - labeled log fields such as `moduleLabel`, `operationTypeLabel`, and `statusLabel`
  - list summary fields such as `filteredTotal`, `successCount`, `failureCount`, and `moduleStats`
  - stats fields such as `moduleStats` and `dailyTrend`
  - dashboard/statistics plus system-config/messages and user/group/order/vip/pretty-number/report/content-audit list and stats fields such as labels, `summary`, and distribution blocks
  - `/admin/auth/context`
  - `/admin/auth/profile`
  - `/admin/auth/change-password`
  - `/admin/admin/export`
  - `/admin/admin/permission-preview`
  - `/admin/admin/{adminId}/permissions`
  - `/admin/admin/stats`
  - admin list/detail fields such as `statusLabel`, `roleDescription`, `permissionSummary`, `effectivePermissionCount`, `hasWildcardPermission`, `permissionRiskLevel`, and `permissionRiskLabel`
  - admin summary/stats fields such as `riskStats`

Recommended backend checks:
1. Set environment variables from [.env.example](/E:/IM/ImServer/.env.example).
2. Use the `prod` profile when you want safer runtime defaults.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File E:\IM\ImServer\scripts\verify-targeted.ps1
powershell -ExecutionPolicy Bypass -File E:\IM\ImServer\scripts\verify-full.ps1

# or run the individual commands below
mvn -q -pl hailiao-api -am -DskipTests compile
mvn -q -pl hailiao-admin -am -DskipTests compile
mvn -q -pl hailiao-common -am "-Dtest=ConversationServiceTest,BlacklistServiceTest,UserServiceTest,MessageServiceTest,FriendServiceTest,GroupJoinRequestServiceTest,GroupMemberServiceTest,UserOnlineServiceTest,FileUploadServiceTest,ReportServiceTest,ContentAuditServiceTest,VideoCallServiceTest,AdminUserServiceTest,OperationLogServiceTest,StatisticsServiceTest,OrderServiceTest,VipMemberServiceTest,PrettyNumberServiceTest,SystemConfigServiceTest,GroupChatServiceTest,GroupRobotServiceTest,UserSessionServiceTest,WebSocketNotificationServiceTest,OssStorageServiceTest,MessageCacheServiceTest" -DfailIfNoTests=false test
mvn -q -pl hailiao-api -am "-Dtest=AuthControllerTest,UserControllerTest,GroupControllerTest,FriendControllerTest,GroupJoinRequestControllerTest,MessageControllerTest,ConversationControllerTest,BlacklistControllerTest,MessageExtControllerTest,UserOnlineControllerTest,ReportControllerTest,ContentAuditControllerTest,FileUploadControllerTest,VideoCallControllerTest,GroupMemberControllerTest,GroupRobotControllerTest" -DfailIfNoTests=false test
mvn -q -pl hailiao-admin -am "-Dtest=AdminManageControllerTest,AuthControllerTest,OperationLogManageControllerTest,UserManagementControllerTest,GroupManageControllerTest,ReportManageControllerTest,ContentAuditManageControllerTest,UserManageControllerTest,OrderManageControllerTest,VipManageControllerTest,PrettyNumberManageControllerTest,DashboardControllerTest,StatisticsControllerTest,SystemConfigManageControllerTest,MessageMonitorControllerTest" -DfailIfNoTests=false test
```

Verified recently in the current environment:
- `powershell -ExecutionPolicy Bypass -File E:\IM\ImServer\scripts\verify-full.ps1`
- `mvn -q -pl hailiao-common -am "-Dtest=ConversationServiceTest,BlacklistServiceTest,UserServiceTest,MessageServiceTest,FriendServiceTest,GroupJoinRequestServiceTest,GroupMemberServiceTest,UserOnlineServiceTest,FileUploadServiceTest,ReportServiceTest,ContentAuditServiceTest,VideoCallServiceTest,AdminUserServiceTest,OperationLogServiceTest,StatisticsServiceTest,OrderServiceTest,VipMemberServiceTest,PrettyNumberServiceTest,SystemConfigServiceTest,GroupChatServiceTest,GroupRobotServiceTest,UserSessionServiceTest,WebSocketNotificationServiceTest,OssStorageServiceTest,MessageCacheServiceTest" -DfailIfNoTests=false test`
- `mvn -q -pl hailiao-api -am "-Dtest=AuthControllerTest,UserControllerTest,GroupControllerTest,FriendControllerTest,GroupJoinRequestControllerTest,MessageControllerTest,ConversationControllerTest,BlacklistControllerTest,MessageExtControllerTest,UserOnlineControllerTest,ReportControllerTest,ContentAuditControllerTest,FileUploadControllerTest,VideoCallControllerTest,GroupMemberControllerTest,GroupRobotControllerTest" -DfailIfNoTests=false test`
- targeted `hailiao-admin` controller test suites listed above

Recommended Flutter checks:

```powershell
cd E:\IM\ImServer\hailiao_flutter
flutter pub get
dart format -o none lib
dart analyze lib
powershell -ExecutionPolicy Bypass -File E:\IM\ImServer\scripts\verify-flutter-smoke.ps1
flutter test test/models/model_dto_test.dart
flutter test test/models test/providers test/screens
```

Current Flutter automated coverage includes:
- Model and DTO serialization tests under [hailiao_flutter/test/models](/E:/IM/ImServer/hailiao_flutter/test/models)
- Provider/state tests under [hailiao_flutter/test/providers](/E:/IM/ImServer/hailiao_flutter/test/providers)
- Screen smoke tests under [hailiao_flutter/test/screens](/E:/IM/ImServer/hailiao_flutter/test/screens)
- Shared Flutter test helpers under [hailiao_flutter/test/support](/E:/IM/ImServer/hailiao_flutter/test/support)

Current high-value Flutter screen smoke files include:
- [login_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/login_screen_test.dart)
- [register_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/register_screen_test.dart)
- [home_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_screen_test.dart)
- [home_group_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_group_flow_test.dart)
- [home_group_chat_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_group_chat_flow_test.dart)
- [home_chat_user_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_chat_user_flow_test.dart)
- [home_friend_user_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_friend_user_flow_test.dart)
- [home_friend_chat_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_friend_chat_flow_test.dart)
- [home_security_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_security_flow_test.dart)
- [home_report_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_report_flow_test.dart)
- [home_content_audit_flow_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/home_content_audit_flow_test.dart)
- [chat_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/chat_screen_test.dart)
- [security_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/security_screen_test.dart)
- [group_list_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/group_list_screen_test.dart)
- [group_detail_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/group_detail_screen_test.dart)
- [user_detail_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/user_detail_screen_test.dart)
- [report_list_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/report_list_screen_test.dart)
- [content_audit_list_screen_test.dart](/E:/IM/ImServer/hailiao_flutter/test/screens/content_audit_list_screen_test.dart)

Current Flutter support files include:
- [auth_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/auth_test_fakes.dart)
- [detail_screen_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/detail_screen_test_fakes.dart)
- [list_screen_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/list_screen_test_fakes.dart)
- [home_chat_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/home_chat_test_fakes.dart)
- [provider_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/provider_test_fakes.dart)
- [screen_test_helpers.dart](/E:/IM/ImServer/hailiao_flutter/test/support/screen_test_helpers.dart)

Current shared screen pump helpers include:
- `buildSignedInAuthProvider(...)`
- `buildDefaultScreenAuthProvider(...)`
- `buildHomeRoutes(...)`
- `buildHomeAuthProvider(...)`
- `buildChatMessageProvider(...)`
- `buildChatBlacklistProvider(...)`
- `FakeGroupFlowApi`
- `pumpAuthScreenApp(...)`
- `pumpReportScreenApp(...)`
- `pumpContentAuditScreenApp(...)`
- `pumpGroupListScreenApp(...)`
- `pumpHomeScreenApp(...)`
- `pumpHomeGroupFlowApp(...)`
- `pumpHomeGroupChatFlowApp(...)`
- `pumpHomeChatUserFlowApp(...)`
- `pumpHomeReportFlowApp(...)`
- `pumpHomeContentAuditFlowApp(...)`
- `pumpChatScreenApp(...)`
- `pumpGroupDetailScreenApp(...)`
- `pumpUserDetailScreenApp(...)`
- `buildTextRoute(...)`
- `buildTextRoutes(...)`

Current Flutter verification scripts:
- [verify-flutter-smoke.ps1](/E:/IM/ImServer/scripts/verify-flutter-smoke.ps1)
- [verify-flutter.ps1](/E:/IM/ImServer/scripts/verify-flutter.ps1)
- [FLUTTER_TESTING.md](/E:/IM/ImServer/FLUTTER_TESTING.md)

Practical Flutter note:
- Prefer adding new fake APIs, builders, and signed-in provider helpers to `hailiao_flutter/test/support` first, then reuse them from `test/providers` and `test/screens`.

Known blocker in the current environment:
- `dart format` and `dart analyze` have previously timed out before finishing.
- `flutter test test/models/model_dto_test.dart` also timed out in the current environment, so Flutter automated checks are present but not yet locally verified end-to-end here.
- `flutter test test/models test/providers test/screens` is now the intended Flutter regression entry, but it is also expected to time out in the current environment until the local toolchain/runtime issue is resolved.
- `verify-flutter-smoke.ps1` is intended to be the lightest Flutter entry point, but it may still time out in the current environment for the same toolchain reason.

Database verification:
1. Create the `hailiao` database.
2. Start the backend once with the configured environment variables.
3. Apply the migration scripts listed in [DATABASE_SETUP.md](/E:/IM/ImServer/DATABASE_SETUP.md).

Practical recommendation:
- Treat code review plus focused manual smoke testing as the current baseline until dedicated tests are added.
