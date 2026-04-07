import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';

import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

/// 扩展假 API：聊天内撤回/编辑走真实 [MessageProvider] 逻辑，列表会话仍可由
/// [getConversations] 返回滞后 [lastMessage]，依赖 Provider 内 refresh 纠偏。
class _HomePreviewSyncMessageApi extends FakeHomeMessageApi {
  _HomePreviewSyncMessageApi({
    required super.conversations,
    required super.privateMessages,
  });

  @override
  Future<ResponseDTO<String>> recallMessage(int messageId) async {
    return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
  }

  @override
  Future<ResponseDTO<MessageDTO>> editMessage(
    int messageId,
    String newContent,
  ) async {
    return ResponseDTO<MessageDTO>(
      code: 200,
      message: 'ok',
      data: MessageDTO(
        id: messageId,
        fromUserId: 1,
        toUserId: 2,
        content: newContent,
        msgType: 1,
        isEdited: true,
        status: 1,
        createdAt: '2026-04-05T12:00:00',
      ),
    );
  }
}

Future<void> _pumpHomeWithChatRoute(
  WidgetTester tester, {
  required MessageProvider messageProvider,
}) async {
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
    messageProvider: messageProvider,
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
}

Future<void> _openChatWithWorkFriend(WidgetTester tester) async {
  expect(find.textContaining('Work friend'), findsWidgets);
  await tester.tap(find.textContaining('Work friend').first);
  await tester.pumpAndSettle();
  expect(find.byType(ChatScreen), findsOneWidget);
}

void main() {
  testWidgets('撤回消息后返回首页，会话预览同步为「此消息已撤回」', (
    WidgetTester tester,
  ) async {
    const stalePreview = '列表滞后预览';
    const bubbleText = '点我撤回';

    final messageProvider = MessageProvider(
      api: _HomePreviewSyncMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Alice',
            lastMessage: stalePreview,
            lastMessageTime: '2026-04-05T11:00:00',
          ),
        ],
        privateMessages: <MessageDTO>[
          MessageDTO(
            id: 601,
            fromUserId: 1,
            toUserId: 2,
            content: bubbleText,
            msgType: 1,
            status: 1,
            createdAt: '2026-04-05T11:00:00',
          ),
        ],
      ),
    );

    await _pumpHomeWithChatRoute(tester, messageProvider: messageProvider);

    expect(find.text(stalePreview), findsOneWidget);

    await _openChatWithWorkFriend(tester);

    await tester.longPress(find.text(bubbleText));
    await tester.pumpAndSettle();

    final recallFinder = find.text('撤回消息');
    await tester.ensureVisible(recallFinder.first);
    await tester.pumpAndSettle();
    await tester.tap(recallFinder.first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('此消息已撤回'), findsWidgets);
    expect(find.text(stalePreview), findsNothing);
  });

  testWidgets('编辑消息发送后返回首页，会话预览同步为「已编辑 · 定稿」', (
    WidgetTester tester,
  ) async {
    const stalePreview = '列表滞后编辑预览';
    const original = '原稿';

    final messageProvider = MessageProvider(
      api: _HomePreviewSyncMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Alice',
            lastMessage: stalePreview,
            lastMessageTime: '2026-04-05T11:05:00',
          ),
        ],
        privateMessages: <MessageDTO>[
          MessageDTO(
            id: 602,
            fromUserId: 1,
            toUserId: 2,
            content: original,
            msgType: 1,
            status: 1,
            createdAt: '2026-04-05T11:05:00',
          ),
        ],
      ),
    );

    await _pumpHomeWithChatRoute(tester, messageProvider: messageProvider);

    expect(find.text(stalePreview), findsOneWidget);

    await _openChatWithWorkFriend(tester);

    await tester.longPress(find.text(original));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑消息').first);
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    expect(textField, findsWidgets);
    await tester.enterText(textField.first, '定稿');
    await tester.pump(const Duration(milliseconds: 50));

    final saveEdit = find.byIcon(Icons.check);
    await tester.ensureVisible(saveEdit);
    await tester.pumpAndSettle();
    await tester.tap(saveEdit);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('已编辑 · 定稿'), findsWidgets);
    expect(find.text(stalePreview), findsNothing);
  });
}
