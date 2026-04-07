import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

Future<void> _pumpHomeWithChat(WidgetTester tester, MessageProvider mp) async {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.binding.setSurfaceSize(const Size(800, 1400));

  final authProvider = buildHomeAuthProvider();
  final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
  final blacklistProvider = buildChatBlacklistProvider();

  await friendProvider.loadFriends();

  await pumpHomeChatUserFlowApp(
    tester,
    authProvider: authProvider,
    friendProvider: friendProvider,
    messageProvider: mp,
    blacklistProvider: blacklistProvider,
    routes: <String, WidgetBuilder>{
      ...buildHomeRoutes(),
      '/chat': (_) => ChatScreen(api: FakeChatScreenApi()),
    },
    home: const HomeScreen(),
  );

  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

Future<void> _tapRowByPreview(WidgetTester tester, String previewSubstring) async {
  await tester.tap(find.textContaining(previewSubstring).first);
  await tester.pumpAndSettle();
  expect(find.byType(ChatScreen), findsOneWidget);
}

Future<void> _closeChat(WidgetTester tester) async {
  await Navigator.maybePop(tester.element(find.byType(ChatScreen)));
  await tester.pumpAndSettle();
  expect(find.byType(ChatScreen), findsNothing);
}

void main() {
  testWidgets('进入单聊后未读本地清零，返回首页角标消失', (
    WidgetTester tester,
  ) async {
    final mp = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Alice',
            lastMessage: '未读清零后仍见此行',
            lastMessageTime: '2026-03-31T12:00:00',
            unreadCount: 15,
          ),
        ],
        privateMessages: <MessageDTO>[buildPrivateMessage()],
      ),
    );

    await _pumpHomeWithChat(tester, mp);

    expect(find.text('15'), findsOneWidget);

    await _tapRowByPreview(tester, '未读清零后仍见此行');
    await _closeChat(tester);

    expect(find.text('15'), findsNothing);
    expect(find.textContaining('未读清零后仍见此行'), findsWidgets);
  });

  testWidgets('清空输入草稿后会话项恢复 lastMessage（同步清除 draft 字段）', (
    WidgetTester tester,
  ) async {
    final mp = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Alice',
            lastMessage: '恢复此 last 预览',
            lastMessageTime: '2026-03-31T12:00:00',
            unreadCount: 0,
            draft: '列表草稿残留',
          ),
        ],
        privateMessages: <MessageDTO>[buildPrivateMessage()],
      ),
    );

    await _pumpHomeWithChat(tester, mp);

    expect(find.textContaining('[草稿] 列表草稿残留'), findsWidgets);

    await _tapRowByPreview(tester, '列表草稿残留');

    final TextField field = tester.widget(find.byType(TextField));
    expect(field.controller?.text, '列表草稿残留');

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    await _closeChat(tester);

    expect(find.textContaining('[草稿]'), findsNothing);
    expect(find.textContaining('恢复此 last 预览'), findsWidgets);
  });

  testWidgets('会话列表草稿优先于 lastMessage 预览', (
    WidgetTester tester,
  ) async {
    final mp = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Alice',
            lastMessage: '仅当无草稿时见',
            lastMessageTime: '2026-03-31T12:00:00',
            unreadCount: 0,
            draft: null,
          ),
        ],
        privateMessages: <MessageDTO>[buildPrivateMessage()],
      ),
    );

    await _pumpHomeWithChat(tester, mp);

    Provider.of<MessageProvider>(
      tester.element(find.byType(HomeScreen)),
      listen: false,
    ).setDraft(2, 1, '内存优先草稿');

    await tester.pump();

    expect(find.textContaining('[草稿] 内存优先草稿'), findsOneWidget);
    expect(find.textContaining('仅当无草稿时见'), findsNothing);
  });

  testWidgets('草稿仍优先于撤回与已编辑形态的 lastMessage（同屏两条会话）', (
    WidgetTester tester,
  ) async {
    const draftRecall = '压住撤回行的草稿';
    const draftEdit = '压住已编辑行的草稿';

    final mp = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: '会话甲',
            lastMessage: '此消息已撤回',
            lastMessageTime: '2026-03-31T12:00:00',
            unreadCount: 0,
            draft: draftRecall,
          ),
          buildConversation(
            targetId: 3,
            type: 1,
            name: '会话乙',
            lastMessage: '已编辑 · 组合尾条',
            lastMessageTime: '2026-03-31T13:00:00',
            unreadCount: 0,
            draft: draftEdit,
          ),
        ],
        privateMessages: <MessageDTO>[buildPrivateMessage()],
      ),
    );

    await _pumpHomeWithChat(tester, mp);

    expect(find.textContaining('[草稿] $draftRecall'), findsOneWidget);
    expect(find.textContaining('[草稿] $draftEdit'), findsOneWidget);
    expect(find.textContaining('此消息已撤回'), findsNothing);
    expect(find.textContaining('已编辑 · 组合尾条'), findsNothing);
  });

  testWidgets('清空草稿后恢复撤回形态的 lastMessage 预览', (
    WidgetTester tester,
  ) async {
    const lastMsg = '此消息已撤回';
    const draftBody = '撤回清草稿前';

    final mp = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Alice',
            lastMessage: lastMsg,
            lastMessageTime: '2026-03-31T12:00:00',
            unreadCount: 0,
            draft: draftBody,
          ),
        ],
        privateMessages: <MessageDTO>[buildPrivateMessage()],
      ),
    );

    await _pumpHomeWithChat(tester, mp);

    await _tapRowByPreview(tester, draftBody);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await _closeChat(tester);

    expect(find.textContaining('[草稿]'), findsNothing);
    expect(find.textContaining(lastMsg), findsWidgets);
  });

  testWidgets('清空草稿后恢复已编辑形态的 lastMessage 预览', (
    WidgetTester tester,
  ) async {
    const lastMsg = '已编辑 · 恢复此行';
    const draftBody = '编辑清草稿前';

    final mp = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Alice',
            lastMessage: lastMsg,
            lastMessageTime: '2026-03-31T12:00:00',
            unreadCount: 0,
            draft: draftBody,
          ),
        ],
        privateMessages: <MessageDTO>[buildPrivateMessage()],
      ),
    );

    await _pumpHomeWithChat(tester, mp);

    await _tapRowByPreview(tester, draftBody);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await _closeChat(tester);

    expect(find.textContaining('[草稿]'), findsNothing);
    expect(find.textContaining(lastMsg), findsWidgets);
  });
}
