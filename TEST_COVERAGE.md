# Test Coverage

Current automated test inventory:
- `hailiao-common`: 25 tests
- `hailiao-api`: 17 tests
- `hailiao-admin`: 16 tests
- `hailiao_flutter`: 26 test files

Current backend verification entry points:
- [verify-targeted.ps1](/E:/IM/ImServer/scripts/verify-targeted.ps1)
- [verify-full.ps1](/E:/IM/ImServer/scripts/verify-full.ps1)

Current Flutter verification entry point:
- [verify-flutter-smoke.ps1](/E:/IM/ImServer/scripts/verify-flutter-smoke.ps1)
- [verify-flutter.ps1](/E:/IM/ImServer/scripts/verify-flutter.ps1)
- [FLUTTER_TESTING.md](/E:/IM/ImServer/FLUTTER_TESTING.md)

Covered well right now

`hailiao-common`
- User, session, online status, blacklist
- Friend requests, group join requests, group members, group chat
- Message sending, message cache, file upload, OSS storage
- Reports, content audit, video calls
- Admin users, operation logs, statistics
- Orders, VIP, pretty numbers, system config
- Group robots, websocket notifications

`hailiao-api`
- Auth, user, friend, blacklist, conversation
- Message, message extensions, online status
- Group, group member, group join request, group robot
- Report, content audit, file upload, video call

`hailiao-admin`
- Auth and current-admin context
- Admin management and compatibility user-management route
- Dashboard, statistics, operation log
- User, group, report, content audit
- Order, VIP, pretty number
- System config, message monitor

`hailiao_flutter`
- Model serialization coverage for:
  - `LoginRequestDTO`
  - `RegisterRequestDTO`
  - `EmojiList`
  - `UserDTO`
  - `MessageDTO`
  - `ConversationDTO`
  - `GroupDTO`
  - `GroupMemberDTO`
  - `GroupJoinRequestDTO`
  - `FriendDTO`
  - `FriendRequestDTO`
  - `BlacklistDTO`
  - `ReportDTO`
  - `ContentAuditDTO`
  - `UserSessionDTO`
  - `FileUploadResultDTO`
  - `ResponseDTO`
  - `AuthResponseDTO`
- Provider/state coverage for:
  - `AuthProvider`
  - `BlacklistProvider`
  - `ContentAuditProvider`
  - `FriendProvider`
  - `GroupProvider`
  - `MessageProvider`
  - `ReportProvider`
- Shared Flutter test support now lives under:
  - [auth_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/auth_test_fakes.dart)
  - [detail_screen_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/detail_screen_test_fakes.dart)
  - [list_screen_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/list_screen_test_fakes.dart)
  - [home_chat_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/home_chat_test_fakes.dart)
  - [provider_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/provider_test_fakes.dart)
  - [screen_test_helpers.dart](/E:/IM/ImServer/hailiao_flutter/test/support/screen_test_helpers.dart)
- Shared Flutter route placeholder helpers now also live in:
  - `buildTextRoute(...)`
  - `buildTextRoutes(...)`
- Shared Flutter auth helpers now also include:
  - `buildSignedInAuthProvider(...)`
  - `buildDefaultScreenAuthProvider(...)`
- Shared home/chat screen helpers now also include:
  - `buildHomeRoutes(...)`
  - `buildHomeAuthProvider(...)`
  - `buildChatMessageProvider(...)`
  - `buildChatBlacklistProvider(...)`
- Shared cross-screen flow helpers now also include:
  - `FakeGroupFlowApi`
  - `pumpHomeGroupFlowApp(...)`
  - `pumpHomeGroupChatFlowApp(...)`
  - `pumpHomeChatUserFlowApp(...)`
  - `pumpHomeReportFlowApp(...)`
  - `pumpHomeContentAuditFlowApp(...)`
- Shared screen pump helpers currently cover:
  - `LoginScreen`
  - `RegisterScreen`
  - `SecurityScreen`
  - `ReportListScreen`
  - `ContentAuditListScreen`
  - `GroupListScreen`
  - `HomeScreen`
  - `ChatScreen`
  - `GroupDetailScreen`
  - `UserDetailScreen`

Main remaining gaps
- Flutter widget and screen tests have started, but coverage is still very limited.
- Flutter provider coverage has started, but only these providers are covered right now:
  - `AuthProvider`
  - `BlacklistProvider`
  - `ContentAuditProvider`
  - `FriendProvider`
  - `GroupProvider`
  - `MessageProvider`
  - `ReportProvider`
- Flutter screen/widget smoke coverage has started for:
  - `LoginScreen`
  - `RegisterScreen`
  - `ReportListScreen`
  - `ContentAuditListScreen`
  - `SecurityScreen`
  - `HomeScreen`
  - `ChatScreen`
  - `GroupListScreen`
  - `GroupDetailScreen`
  - `UserDetailScreen`
- Flutter screen interaction coverage now also includes lightweight route/dialog paths for:
  - `HomeScreen` profile/group entry navigation, profile/message/friend route persistence, profile report/audit-route persistence, logout navigation, conversation action sheet open/close, top/mute/delete action feedback, top/mute enable-disable feedback, top/mute state transition rendering, top reorder rendering, top/mute filter rendering, top/mute/delete post-action tab/route persistence, untop/unmute-to-filter-empty rendering, delete-to-empty rendering, delete-empty tab/route persistence, friend-request accept/reject feedback, friend-request-to-empty rendering, friend-request-to-friend-list rendering, friend-request post-action tab/route persistence, empty conversation/friend states, friend-request-only rendering, and friend-only rendering
  - `SecurityScreen` device session, current/other-session revoke handling, other-session removal rendering, terminate-to-current-session rendering, current-session logout navigation, terminate button enable/disable state with helper text, terminate/device-lock actions, terminate/revoke-device route persistence, device-lock feedback/state transition, and empty-state rendering
  - `ChatScreen` info/search/emoji interactions, info route persistence, search dialog close path, empty-search close-to-chat persistence, search-close draft persistence, media-sheet open/close, media-sheet close-to-chat persistence, media/audio close draft persistence, audio-dialog open/close, audio-dialog close-to-chat persistence, audio-path validation feedback with retry-and-reopen action, audio retry state restore, missing-file retry state restore, empty-message rendering, and empty-search-result feedback
  - `GroupListScreen` group-detail route persistence, search/create entry dialogs, create validation/success feedback, create-to-detail route persistence, create-refresh persistence, create-to-search/create-close persistence, create-dialog reset after success, search-dialog reset after close, search/create dialog close paths, search/create-close-to-list persistence, empty-state rendering, join-request-only rendering, group-only rendering, withdraw-request feedback, withdrawn-state refresh persistence, withdrawn-state route persistence, withdrawn-state search/create-close persistence, withdraw-to-group-list rendering, and withdraw-with-empty-group-section rendering
  - `GroupDetailScreen` chat/report entry actions, chat route persistence, report dialog close-to-detail persistence, report-success route/dialog persistence, non-member join-state rendering, join-request dialog, join-dialog close-to-detail persistence, join-submit feedback, join-submit keeps non-member actions, join-submit route/dialog persistence, refresh action, and join-submit-to-refresh state persistence
  - `UserDetailScreen` chat/report/blacklist entry actions, chat route persistence, report dialog success feedback, report-success route/dialog persistence, report/blacklist dialog close-to-detail persistence, blocked-state rendering, unblock dialog, unblock-dialog close-to-blocked-state persistence, unblock feedback, unblock-to-normal-action rendering, unblock route/dialog persistence, and blocked main-action guard
- Flutter cross-screen flow coverage now includes:
  - `HomeScreen -> GroupListScreen -> GroupDetailScreen`
  - `HomeScreen -> GroupListScreen -> GroupDetailScreen -> ChatScreen`
  - `HomeScreen -> ChatScreen -> UserDetailScreen`
  - `HomeScreen -> FriendTab -> UserDetailScreen`
  - `HomeScreen -> FriendTab -> UserDetailScreen -> ChatScreen`
  - `HomeScreen -> SecurityScreen`
  - `HomeScreen -> ReportListScreen`
  - `HomeScreen -> ContentAuditListScreen`
- Audit/profile flow branches now also include:
  - report list loaded state and empty state from home profile
  - content audit list loaded state and empty state from home profile
  - security screen session-management flows, including current-session logout navigation and logout-to-login persistence
- No backend integration tests with a real database, Redis, or HTTP stack beyond controller-slice coverage.
- No end-to-end multi-module scenario tests such as login -> send message -> audit/report -> admin review.
- No load or performance verification in-repo yet.
- No explicit coverage metrics report is generated yet.

Recommended next test steps
1. Add a small `hailiao-api` integration smoke suite with mocked security and in-memory persistence for the highest-value user flows.
2. Add one backend end-to-end scenario for friend request, private message, and audit/report linkage.
3. Continue expanding Flutter screen interaction coverage beyond smoke level for home, chat, and group detail.
4. Keep moving duplicated Flutter test doubles into `test/support` so new widget/provider tests stay small and consistent.
