import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';

import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

/// 可删好友、改备注；[getFriends] 返回列表快照，供首轮 [loadFriends] 使用。
class _MutableRelationFriendApi implements FriendApi {
  _MutableRelationFriendApi(List<FriendDTO> friends)
      : _friends = List<FriendDTO>.from(friends);

  List<FriendDTO> _friends;

  @override
  Future<ResponseDTO<String>> acceptFriendRequest(int requestId) async =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> addFriend(
    int friendId,
    String remark, {
    String? message,
  }) async =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> deleteFriend(int friendId) async {
    _friends.removeWhere((f) => f.friendId == friendId);
    return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
  }

  @override
  Future<ResponseDTO<List<FriendDTO>>> getFriends() async {
    return ResponseDTO<List<FriendDTO>>(
      code: 200,
      message: 'ok',
      data: List<FriendDTO>.from(_friends),
    );
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getReceivedFriendRequests() async {
    return ResponseDTO<List<FriendRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <FriendRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getSentFriendRequests() async {
    return ResponseDTO<List<FriendRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <FriendRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<String>> rejectFriendRequest(int requestId) async =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<FriendDTO>> updateFriendRemark(
    int friendId,
    String remark,
  ) async {
    final int i = _friends.indexWhere((f) => f.friendId == friendId);
    if (i < 0) {
      return ResponseDTO<FriendDTO>(code: 404, message: 'nf', data: null);
    }
    final FriendDTO old = _friends[i];
    final FriendDTO next = FriendDTO(
      id: old.id,
      userId: old.userId,
      friendId: old.friendId,
      remark: remark.trim(),
      groupName: old.groupName,
      status: old.status,
      createdAt: old.createdAt,
      updatedAt: old.updatedAt,
      friendUserInfo: old.friendUserInfo,
    );
    _friends[i] = next;
    return ResponseDTO<FriendDTO>(code: 200, message: 'ok', data: next);
  }
}

class _MutableBlacklistApi implements BlacklistApi {
  _MutableBlacklistApi([Iterable<int>? initial]) {
    if (initial != null) {
      _blocked.addAll(initial);
    }
  }

  final Set<int> _blocked = <int>{};

  @override
  Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId) async {
    _blocked.add(blockedUserId);
    return ResponseDTO<BlacklistDTO>(
      code: 200,
      message: 'ok',
      data: BlacklistDTO(blockedUserId: blockedUserId),
    );
  }

  @override
  Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist() async {
    return ResponseDTO<List<BlacklistDTO>>(
      code: 200,
      message: 'ok',
      data: _blocked
          .map((int id) => BlacklistDTO(blockedUserId: id))
          .toList(),
    );
  }

  @override
  Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId) async {
    _blocked.remove(blockedUserId);
    return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
  }
}

FriendDTO _sampleFriend({required String remark}) => FriendDTO(
      id: 1,
      userId: 1,
      friendId: 2,
      remark: remark,
      friendUserInfo: UserDTO(id: 2, userId: 'u2', nickname: 'PeerNick'),
    );

void main() {
  testWidgets('删除好友后会话列表标题从备注回落到会话名', (WidgetTester tester) async {
    const String convName = 'ConvSnapTitle';
    const String remark = 'RemarkBeforeDelete';
    final FriendProvider friendProvider = FriendProvider(
      api: _MutableRelationFriendApi(<FriendDTO>[_sampleFriend(remark: remark)]),
    );
    final MessageProvider messageProvider = buildChatMessageProvider(
      title: convName,
      targetId: 2,
    );

    await pumpHomeChatUserFlowApp(
      tester,
      authProvider: buildHomeAuthProvider(),
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      blacklistProvider: BlacklistProvider(api: FakeChatBlacklistApi()),
      home: const HomeScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text(remark), findsOneWidget);

    await friendProvider.deleteFriend(2);
    await tester.pumpAndSettle();

    expect(find.text(convName), findsOneWidget);
    expect(find.text(remark), findsNothing);
  });

  testWidgets('删除好友后聊天顶栏标题回落到会话快照名', (WidgetTester tester) async {
    const String convName = 'ConvForAppBar';
    const String remark = 'RemarkChatBar';
    final FriendProvider friendProvider = FriendProvider(
      api: _MutableRelationFriendApi(<FriendDTO>[_sampleFriend(remark: remark)]),
    );
    final MessageProvider messageProvider = buildChatMessageProvider(
      title: convName,
      targetId: 2,
    );
    await friendProvider.loadFriends();
    await messageProvider.loadConversations();

    await pumpChatScreenApp(
      tester,
      authProvider: buildHomeAuthProvider(),
      messageProvider: messageProvider,
      blacklistProvider: BlacklistProvider(api: FakeChatBlacklistApi()),
      friendProvider: friendProvider,
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      arguments: <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': convName,
      },
    );
    await tester.pumpAndSettle();

    expect(find.text(remark), findsWidgets);

    await friendProvider.deleteFriend(2);
    await tester.pumpAndSettle();

    expect(find.text(convName), findsWidgets);
    expect(find.text(remark), findsNothing);
  });

  testWidgets('拉黑后输入区禁用并展示拉黑 Banner', (WidgetTester tester) async {
    final FriendProvider friendProvider = FriendProvider(
      api: _MutableRelationFriendApi(<FriendDTO>[_sampleFriend(remark: 'r')]),
    );
    final MessageProvider messageProvider = buildChatMessageProvider(targetId: 2);
    await friendProvider.loadFriends();
    await messageProvider.loadConversations();

    final BlacklistProvider blacklistProvider = BlacklistProvider(
      api: _MutableBlacklistApi(<int>{2}),
    );
    await blacklistProvider.loadBlacklist();

    await pumpChatScreenApp(
      tester,
      authProvider: buildHomeAuthProvider(),
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      friendProvider: friendProvider,
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      arguments: <String, dynamic>{'targetId': 2, 'type': 1, 'title': 't'},
    );
    await tester.pumpAndSettle();

    expect(find.text('无法发送消息'), findsOneWidget);
    expect(find.textContaining('你已拉黑该用户'), findsOneWidget);
    final TextField field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.enabled, isFalse);
  });

  testWidgets('解除拉黑后输入区恢复可用', (WidgetTester tester) async {
    final FriendProvider friendProvider = FriendProvider(
      api: _MutableRelationFriendApi(<FriendDTO>[_sampleFriend(remark: 'r')]),
    );
    final MessageProvider messageProvider = buildChatMessageProvider(targetId: 2);
    await friendProvider.loadFriends();
    await messageProvider.loadConversations();

    final BlacklistProvider blacklistProvider = BlacklistProvider(
      api: _MutableBlacklistApi(<int>{2}),
    );
    await blacklistProvider.loadBlacklist();

    await pumpChatScreenApp(
      tester,
      authProvider: buildHomeAuthProvider(),
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      friendProvider: friendProvider,
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      arguments: <String, dynamic>{'targetId': 2, 'type': 1, 'title': 't'},
    );
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField).last).enabled, isFalse);

    await blacklistProvider.removeFromBlacklist(2);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField).last).enabled, isTrue);
    expect(find.text('无法发送消息'), findsNothing);
  });

  testWidgets('修改备注后会话列表、聊天顶栏与资料卡标题同步', (WidgetTester tester) async {
    const String convName = 'ConvRemarkSync';
    const String r1 = 'RemarkOne';
    const String r2 = 'RemarkTwo';
    final FriendProvider friendProvider = FriendProvider(
      api: _MutableRelationFriendApi(<FriendDTO>[_sampleFriend(remark: r1)]),
    );
    final MessageProvider messageProvider = buildChatMessageProvider(
      title: convName,
      targetId: 2,
    );

    await pumpHomeChatUserFlowApp(
      tester,
      authProvider: buildHomeAuthProvider(),
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      blacklistProvider: BlacklistProvider(api: FakeChatBlacklistApi()),
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(includeUserDetail: true),
        '/chat': (_) => ChatScreen(api: FakeChatScreenApi()),
        '/user-detail': (_) => UserDetailScreen(api: FakeUserDetailApi()),
      },
      home: const HomeScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text(r1), findsOneWidget);

    await tester.tap(find.text(r1));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text(r1), findsWidgets);

    await friendProvider.updateFriendRemark(2, r2);
    await tester.pumpAndSettle();

    expect(find.text(r2), findsWidgets);
    expect(find.text(r1), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline).last);
    await tester.pumpAndSettle();
    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(find.text(r2), findsWidgets);
    expect(find.text(r1), findsNothing);
  });
}
