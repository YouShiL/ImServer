# Flutter Testing Guide

This repository uses a lightweight layered Flutter testing structure under:
- [hailiao_flutter/test/models](/E:/IM/ImServer/hailiao_flutter/test/models)
- [hailiao_flutter/test/providers](/E:/IM/ImServer/hailiao_flutter/test/providers)
- [hailiao_flutter/test/screens](/E:/IM/ImServer/hailiao_flutter/test/screens)
- [hailiao_flutter/test/support](/E:/IM/ImServer/hailiao_flutter/test/support)

## Test Layers

### Models
- Use model tests for DTO serialization, generic response parsing, and small pure helpers.
- Keep them independent from providers, widgets, and services.

### Providers
- Prefer injecting an API abstraction instead of calling `ApiService` statically.
- Put reusable fake APIs in [provider_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/provider_test_fakes.dart) or another support file if the scope is screen-specific.
- Cover:
  - loading state updates
  - success state transitions
  - local list/state mutations
  - error propagation

### Screens
- Prefer lightweight smoke and interaction coverage.
- Reuse pump helpers from [screen_test_helpers.dart](/E:/IM/ImServer/hailiao_flutter/test/support/screen_test_helpers.dart).
- Reuse fake APIs/builders from `test/support` instead of declaring local `Fake*Api` classes inside each screen test.
- Prefer structural assertions such as icons, dialogs, fields, and route targets over brittle long Chinese text matches.

## Shared Support Files

### Auth Support
- [auth_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/auth_test_fakes.dart)
- Common helpers:
  - `FakeAuthApi`
  - `FakeAuthStorage`
  - `FakeDeviceInfoProvider`
  - `buildSignedInAuthProvider(...)`
  - `buildDefaultScreenAuthProvider(...)`

### Home And Chat Support
- [home_chat_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/home_chat_test_fakes.dart)
- Common helpers:
  - `FakeHomeFriendApi`
  - `FakeHomeMessageApi`
  - `FakeChatBlacklistApi`
  - `FakeChatScreenApi`
  - `buildHomeRoutes(...)`
  - `buildHomeAuthProvider(...)`
  - `buildChatMessageProvider(...)`
  - `buildChatBlacklistProvider(...)`
  - `buildConversation(...)`
  - `buildPrivateMessage(...)`
  - `buildFriend(...)`
  - `buildFriendRequest(...)`

### Detail Screen Support
- [detail_screen_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/detail_screen_test_fakes.dart)
- Common helpers:
  - `FakeGroupDetailApi`
  - `FakeGroupDetailGroupApi`
  - `FakeGroupFlowApi`
  - `FakeUserDetailApi`
  - `FakeUserDetailFriendApi`
  - `FakeUserDetailBlacklistApi`

### List Screen Support
- [list_screen_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/list_screen_test_fakes.dart)
- Common helpers:
  - `FakeReportListApi`
  - `FakeContentAuditListApi`
  - `FakeGroupListApi`
  - `buildReportProvider(...)`
  - `buildContentAuditProvider(...)`
  - `buildGroupListProvider(...)`
  - `buildJoinRequest(...)`
  - `buildGroup(...)`

### Provider Support
- [provider_test_fakes.dart](/E:/IM/ImServer/hailiao_flutter/test/support/provider_test_fakes.dart)
- Common helpers:
  - `FakeBlacklistApi`
  - `FakeFriendApi`
  - `FakeGroupApi`
  - `FakeReportApi`
  - `FakeContentAuditApi`
  - `FakeMessageApi`

### Pump And Route Support
- [screen_test_helpers.dart](/E:/IM/ImServer/hailiao_flutter/test/support/screen_test_helpers.dart)
- Common helpers:
  - `buildTextRoute(...)`
  - `buildTextRoutes(...)`
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

## Conventions

1. Prefer adding support helpers before writing a second similar fake or pump wrapper.
2. Keep screen tests focused on:
   - first render
   - one important interaction
   - one route/dialog assertion
3. When a flow spans more than one screen, prefer adding a dedicated flow-style screen test instead of overloading a single-screen smoke test.
   Current examples include home-to-group-detail, home-to-group-chat, home-to-user-detail, home-friend-to-chat, and home-to-security flows.
4. Prefer `buildTextRoutes(...)` for placeholder routes.
5. Use Unicode-safe strings if you must assert Chinese empty states directly.
6. Avoid copying provider setup blocks across multiple tests if a builder can express the same intent.
7. For multi-screen user paths, prefer a dedicated flow test such as home-to-group, home-to-chat, or home-to-profile-detail.

## Current Limitation

Flutter toolchain commands have timed out in the current environment, so the repository contains Flutter tests and scripts, but local end-to-end Flutter verification has not been confirmed here yet.
