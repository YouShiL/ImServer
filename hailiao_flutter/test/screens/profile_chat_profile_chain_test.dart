import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/im/im_event_bridge.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:provider/provider.dart';

import '../support/auth_test_fakes.dart';
import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/noop_chat_group_api.dart';
import '../support/screen_test_helpers.dart';

/// [FakeUserDetailApi] 仅覆盖指定 [userId]；其余回落到默认 Alice 数据。
class _UserDetailApiForChain extends FakeUserDetailApi {
  _UserDetailApiForChain({required this.userId, required this.user});

  final int userId;
  final UserDTO user;

  @override
  Future<ResponseDTO<UserDTO>> getUserById(int id) async {
    if (id == userId) {
      return ResponseDTO<UserDTO>(code: 200, message: 'ok', data: user);
    }
    return super.getUserById(id);
  }
}

Future<void> _pumpUserDetailChatUserDetailChainApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
  required BlacklistProvider blacklistProvider,
  required UserDetailApi userDetailApi,
  required Map<String, dynamic> userDetailArgs,
  required List<Object?> chatArgumentsSink,
  required List<Object?> secondUserDetailArgsSink,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider<BlacklistProvider>.value(
          value: blacklistProvider,
        ),
        ChangeNotifierProvider<GroupProvider>.value(
          value: GroupProvider(api: NoopChatGroupApi()),
        ),
        Provider<ImEventBridge>(
          create: (BuildContext context) => ImEventBridge(
            authProvider: context.read<AuthProvider>(),
            messageProvider: context.read<MessageProvider>(),
          ),
          dispose: (_, ImEventBridge b) => b.dispose(),
        ),
      ],
      child: MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/chat': (BuildContext context) {
            chatArgumentsSink.add(
              ModalRoute.of(context)?.settings.arguments,
            );
            return ChatScreen(api: FakeChatScreenApi());
          },
          '/user-detail': captureUserDetailArgumentsRoute(
            secondUserDetailArgsSink,
          ),
        },
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/') {
            return MaterialPageRoute<void>(
              settings: RouteSettings(
                name: '/',
                arguments: userDetailArgs,
              ),
              builder: (_) => UserDetailScreen(api: userDetailApi),
            );
          }
          return null;
        },
      ),
    ),
  );
}

void main() {
  testWidgets(
    '资料(群成员式 userInfo 快照) → 发消息：/chat 入参 title 与顶栏 singleChatDisplayTitle 一致',
    (WidgetTester tester) async {
      const int peerId = 42;
      final UserDTO routeSnapshot = UserDTO(
        id: peerId,
        userId: 'u42',
        nickname: '群成员快照昵称',
        avatar: 'http://example.com/snap.png',
      );
      final UserDTO apiUser = UserDTO(
        id: peerId,
        userId: 'u42',
        nickname: '接口真名',
        signature: 'sig',
        region: 'HK',
        phone: '13800000000',
        showOnlineStatus: true,
        showLastOnline: true,
      );
      final FriendDTO friendRow = FriendDTO(
        id: 1,
        userId: 1,
        friendId: peerId,
        remark: '备注甲',
        friendUserInfo: UserDTO(
          id: peerId,
          userId: 'u42',
          nickname: '好友行昵称',
        ),
      );

      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(friends: <FriendDTO>[friendRow]),
      );
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );
      final messageProvider = buildChatMessageProvider(
        targetId: peerId,
        title: '会话列表名',
      );

      final List<Object?> chatArgs = <Object?>[];
      final List<Object?> detailAgain = <Object?>[];

      await _pumpUserDetailChatUserDetailChainApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        userDetailApi: _UserDetailApiForChain(userId: peerId, user: apiUser),
        userDetailArgs: <String, dynamic>{
          'userId': peerId,
          'user': routeSnapshot,
        },
        chatArgumentsSink: chatArgs,
        secondUserDetailArgsSink: detailAgain,
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('群成员快照昵称'), findsNothing);
      expect(find.text('接口真名'), findsWidgets);

      await tester.tap(find.text('发消息'));
      await tester.pumpAndSettle();

      expect(chatArgs, hasLength(1));
      final Map<String, dynamic> ca = chatArgs.single! as Map<String, dynamic>;
      expect(ca['targetId'], peerId);
      expect(ca['type'], 1);

      final String expectedTitle = ProfileDisplayTexts.singleChatDisplayTitle(
        peer: apiUser,
        friendRemark: friendRow.remark,
        nameFallback: null,
      );
      expect(ca['title'], expectedTitle);

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text(expectedTitle), findsWidgets);
    },
  );

  testWidgets(
    '资料(仅 nickname 快照) → 发消息：/chat 入参 title 随接口 peer；'
    '聊天顶栏在有 friendUserInfo 时与之解耦并优先好友行资料',
    (WidgetTester tester) async {
      const int peerId = 99;
      const String expectedApiNick = '接口真名99';
      final UserDTO apiUser = UserDTO(
        id: peerId,
        userId: 'u99',
        nickname: expectedApiNick,
        signature: 'sig',
        region: 'SH',
        phone: '13900000000',
        showOnlineStatus: true,
        showLastOnline: true,
      );
      final FriendDTO friendRow = FriendDTO(
        id: 2,
        userId: 1,
        friendId: peerId,
        remark: '',
        friendUserInfo: UserDTO(
          id: peerId,
          nickname: '仅快照昵称',
        ),
      );

      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(friends: <FriendDTO>[friendRow]),
      );
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );
      final messageProvider = buildChatMessageProvider(
        targetId: peerId,
        title: '会话列表名99',
      );

      final List<Object?> chatArgs = <Object?>[];
      final List<Object?> unusedDetail = <Object?>[];

      await _pumpUserDetailChatUserDetailChainApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        userDetailApi: _UserDetailApiForChain(userId: peerId, user: apiUser),
        userDetailArgs: <String, dynamic>{
          'userId': peerId,
          'user': UserDTO(id: peerId, nickname: '仅快照昵称'),
        },
        chatArgumentsSink: chatArgs,
        secondUserDetailArgsSink: unusedDetail,
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('仅快照昵称'), findsNothing);
      expect(find.text(expectedApiNick), findsWidgets);

      await tester.tap(find.text('发消息'));
      await tester.pumpAndSettle();

      final String routeTitle = ProfileDisplayTexts.singleChatDisplayTitle(
        peer: apiUser,
        friendRemark: friendRow.remark,
        nameFallback: null,
      );
      final String appBarFromFriendRow = ProfileDisplayTexts.displayName(
        friendRow.friendUserInfo!,
        friendRemark: friendRow.remark,
      );
      expect(chatArgs.single, isA<Map>());
      final Map<String, dynamic> ca = chatArgs.single! as Map<String, dynamic>;
      expect(ca['title'], routeTitle);
      expect(routeTitle, expectedApiNick);
      expect(find.text(appBarFromFriendRow), findsWidgets);
      expect(find.text('仅快照昵称'), findsWidgets);
    },
  );

  testWidgets(
    '资料 → 聊天 → 再进资料：第二次 /user-detail 携带 friendUserInfo 快照（与好友行一致）',
    (WidgetTester tester) async {
      const int peerId = 42;
      final UserDTO routeSnapshot = UserDTO(
        id: peerId,
        userId: 'u42',
        nickname: '群快照',
      );
      final UserDTO apiUser = UserDTO(
        id: peerId,
        userId: 'u42',
        nickname: '接口字段',
        signature: 'sig',
        region: 'HK',
        phone: '13800000000',
        showOnlineStatus: true,
        showLastOnline: true,
      );
      final UserDTO friendInfo = UserDTO(
        id: peerId,
        userId: 'u42',
        nickname: '好友行专用昵称',
        avatar: 'http://example.com/fr.png',
      );
      final FriendDTO friendRow = FriendDTO(
        id: 1,
        userId: 1,
        friendId: peerId,
        remark: '',
        friendUserInfo: friendInfo,
      );

      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(friends: <FriendDTO>[friendRow]),
      );
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );
      final messageProvider = buildChatMessageProvider(targetId: peerId);

      final List<Object?> chatArgs = <Object?>[];
      final List<Object?> detailAgain = <Object?>[];

      await _pumpUserDetailChatUserDetailChainApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        userDetailApi: _UserDetailApiForChain(userId: peerId, user: apiUser),
        userDetailArgs: <String, dynamic>{
          'userId': peerId,
          'user': routeSnapshot,
        },
        chatArgumentsSink: chatArgs,
        secondUserDetailArgsSink: detailAgain,
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('发消息'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info_outline).last);
      await tester.pumpAndSettle();

      expect(detailAgain, hasLength(1));
      final Map<String, dynamic> ua = detailAgain.single! as Map<String, dynamic>;
      expect(ua['userId'], peerId);
      expect(ua['user'], isA<UserDTO>());
      final UserDTO passed = ua['user'] as UserDTO;
      expect(passed.id, friendInfo.id);
      expect(passed.nickname, friendInfo.nickname);
      expect(passed.avatar, friendInfo.avatar);
    },
  );
}
