import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';

import '../support/provider_test_fakes.dart';

MessageProvider _providerForPreviewTests() {
  final api = FakeMessageApi()
    ..getConversationsHandler = () async => ResponseDTO<List<ConversationDTO>>(
          code: 200,
          message: 'ok',
          data: <ConversationDTO>[],
        );
  return MessageProvider(api: api);
}

void _upsertPrivateOutgoing(
  MessageProvider provider,
  MessageDTO message, {
  int selfUserId = 100,
}) {
  provider.upsertConversationFromMessage(
    message,
    currentUserId: selfUserId,
    increaseUnread: false,
  );
}

String _lastMessageForPeer(MessageProvider provider, int peerUserId) {
  return provider.conversations
      .firstWhere((c) => c.targetId == peerUserId)
      .lastMessage!;
}

void main() {
  group('MessageProvider', () {
    test('loadConversations should populate and sort conversations', () async {
      final api = FakeMessageApi()
        ..getConversationsHandler = () async => ResponseDTO<List<ConversationDTO>>(
              code: 200,
              message: 'ok',
              data: <ConversationDTO>[
                buildConversation(
                  targetId: 2,
                  type: 1,
                  name: 'Unread chat',
                  lastMessageTime: '2026-03-30T10:00:00',
                  unreadCount: 3,
                ),
                buildConversation(
                  targetId: 1,
                  type: 1,
                  name: 'Pinned chat',
                  lastMessageTime: '2026-03-29T10:00:00',
                  isTop: true,
                ),
              ],
            );
      final provider = MessageProvider(api: api);

      await provider.loadConversations();

      expect(provider.conversations.length, 2);
      expect(provider.conversations.first.targetId, 1);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadPrivateMessages 第1页将服务端按时间降序的分页结果整理为升序', () async {
      const peerId = 7;
      final api = FakeMessageApi();
      api.getConversationsHandler = () async {
        return ResponseDTO<List<ConversationDTO>>(
          code: 200,
          message: 'ok',
          data: <ConversationDTO>[],
        );
      };
      api.getPrivateMessagesHandler =
          (int toUserId, int page, int size) async {
        expect(toUserId, peerId);
        return ResponseDTO<List<MessageDTO>>(
          code: 200,
          message: 'ok',
          data: <MessageDTO>[
            MessageDTO(
              id: 20,
              fromUserId: 1,
              toUserId: peerId,
              content: 'new',
              msgType: 1,
              status: 1,
              createdAt: '2026-04-05T14:00:00',
            ),
            MessageDTO(
              id: 10,
              fromUserId: 1,
              toUserId: peerId,
              content: 'old',
              msgType: 1,
              status: 1,
              createdAt: '2026-04-05T12:00:00',
            ),
          ],
        );
      };
      final provider = MessageProvider(api: api);
      await provider.loadPrivateMessages(peerId, 1, 20);
      expect(provider.messages.map((m) => m.id).toList(), <int>[10, 20]);
    });

    test('retainEphemeralMessagesForChat 与 loadPrivateMessages 保留本会话发送失败本地行', () async {
      const peerId = 20;
      const selfId = 100;
      final api = FakeMessageApi();
      api.getConversationsHandler = () async {
        return ResponseDTO<List<ConversationDTO>>(
          code: 200,
          message: 'ok',
          data: <ConversationDTO>[],
        );
      };
      api.getPrivateMessagesHandler =
          (int toUserId, int page, int size) async {
        expect(toUserId, peerId);
        expect(page, 1);
        return ResponseDTO<List<MessageDTO>>(
          code: 200,
          message: 'ok',
          data: <MessageDTO>[
            MessageDTO(
              id: 1,
              fromUserId: selfId,
              toUserId: peerId,
              content: 'server hello',
              msgType: 1,
              status: 1,
              createdAt: '2026-04-05T10:00:00',
            ),
          ],
        );
      };
      final provider = MessageProvider(api: api);

      provider.receiveIncomingMessage(
        MessageDTO(
          id: -99,
          fromUserId: selfId,
          toUserId: 99,
          content: 'other chat pending',
          msgType: 1,
          status: 2,
          createdAt: '2026-04-05T11:00:00',
        ),
        currentUserId: selfId,
      );
      final failedLocalId = provider.addOptimisticTextMessage(
        targetId: peerId,
        type: 1,
        content: 'failed text',
        fromUserId: selfId,
      );
      provider.markOutgoingTextSendFailed(failedLocalId);

      provider.retainEphemeralMessagesForChat(peerId, 1);
      expect(provider.messages.any((m) => m.toUserId == 99), isFalse);
      expect(
        provider.messages.where((m) => m.id == failedLocalId).length,
        1,
      );

      await provider.loadPrivateMessages(peerId, 1, 20);
      final failedRows =
          provider.messages.where((m) => m.id == failedLocalId).toList();
      expect(failedRows.length, 1);
      expect(failedRows.single.status, 2);
      expect(provider.messages.any((m) => m.id == 1), isTrue);
      expect(provider.messages.length, 2);
    });

    test('setDraft should move drafted conversation ahead of unread conversation', () async {
      final api = FakeMessageApi()
        ..getConversationsHandler = () async => ResponseDTO<List<ConversationDTO>>(
              code: 200,
              message: 'ok',
              data: <ConversationDTO>[
                buildConversation(
                  targetId: 10,
                  type: 1,
                  name: 'Normal chat',
                  lastMessageTime: '2026-03-29T10:00:00',
                ),
                buildConversation(
                  targetId: 11,
                  type: 1,
                  name: 'Unread chat',
                  lastMessageTime: '2026-03-30T10:00:00',
                  unreadCount: 2,
                ),
              ],
            );
      final provider = MessageProvider(api: api);

      await provider.loadConversations();
      provider.setDraft(10, 1, 'draft message');

      expect(provider.getDraft(10, 1), 'draft message');
      expect(provider.conversations.first.targetId, 10);
    });

    test('updateConversationSetting should update local top and mute state', () async {
      final api = FakeMessageApi();
      api.getConversationsHandler = () async => ResponseDTO<List<ConversationDTO>>(
            code: 200,
            message: 'ok',
            data: <ConversationDTO>[
              buildConversation(
                targetId: 7,
                type: 1,
                name: 'Test chat',
                lastMessageTime: '2026-03-30T10:00:00',
              ),
            ],
          );
      api.updateConversationHandler =
          (int conversationId, Map<String, dynamic> data) async {
        return ResponseDTO<ConversationDTO>(
          code: 200,
          message: 'ok',
          data: buildConversation(
            targetId: conversationId,
            type: data['type'] as int,
            isTop: data['isTop'] as bool? ?? false,
            isMute: data['isMute'] as bool? ?? false,
          ),
        );
      };
      final provider = MessageProvider(api: api);

      await provider.loadConversations();
      final result = await provider.updateConversationSetting(
        7,
        type: 1,
        isTop: true,
        isMute: true,
      );

      expect(result, isTrue);
      expect(provider.conversations.first.isTop, isTrue);
      expect(provider.conversations.first.isMute, isTrue);
    });

    test('deleteConversation should remove matching conversation locally', () async {
      final api = FakeMessageApi();
      api.getConversationsHandler = () async => ResponseDTO<List<ConversationDTO>>(
            code: 200,
            message: 'ok',
            data: <ConversationDTO>[
              buildConversation(targetId: 8, type: 1, name: 'A'),
              buildConversation(targetId: 9, type: 1, name: 'B'),
            ],
          );
      api.deleteConversationHandler =
          (int conversationId, {required int type}) async {
        return ResponseDTO<String>(code: 200, message: 'ok', data: 'deleted');
      };
      final provider = MessageProvider(api: api);

      await provider.loadConversations();
      final result = await provider.deleteConversation(8, type: 1);

      expect(result, isTrue);
      expect(provider.conversations.length, 1);
      expect(provider.conversations.first.targetId, 9);
    });

    test('loadConversations should expose api error message on failure', () async {
      final api = FakeMessageApi()
        ..getConversationsHandler = () async => ResponseDTO<List<ConversationDTO>>(
              code: 500,
              message: 'load failed',
              data: null,
            );
      final provider = MessageProvider(api: api);

      await provider.loadConversations();

      expect(provider.conversations, isEmpty);
      expect(provider.error, 'load failed');
      expect(provider.isLoading, isFalse);
    });
  });

  group('MessageProvider conversation list preview (lastMessage)', () {
    const selfId = 100;
    const peerId = 200;

    test('撤回消息预览为「此消息已撤回」', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '原内容',
          msgType: 1,
          isRecalled: true,
          createdAt: '2026-04-05T10:00:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '此消息已撤回');
    });

    test('已编辑文本预览为「已编辑 · {content}」', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '最新正文',
          msgType: 1,
          isEdited: true,
          status: 1,
          createdAt: '2026-04-05T10:01:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '已编辑 · 最新正文');
    });

    test('空文本占位为「[消息]」', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '   ',
          msgType: 1,
          status: 1,
          createdAt: '2026-04-05T10:02:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '[消息]');
    });

    test('发送中文本预览带「[发送中]」包裹', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '稍等',
          msgType: 1,
          status: 0,
          createdAt: '2026-04-05T10:03:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '[发送中] 稍等');
    });

    test('发送失败文本预览带「[发送失败]」包裹', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '重试前',
          msgType: 1,
          status: 2,
          createdAt: '2026-04-05T10:04:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '[发送失败] 重试前');
    });

    test('组合：已编辑 + 发送中 → 先已编辑前缀再整体发送中包裹', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '草稿',
          msgType: 1,
          isEdited: true,
          status: 0,
          createdAt: '2026-04-05T10:05:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '[发送中] 已编辑 · 草稿');
    });

    test('组合：已编辑 + 发送失败 → 先已编辑前缀再整体发送失败包裹', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '没发出去',
          msgType: 1,
          isEdited: true,
          status: 2,
          createdAt: '2026-04-05T10:06:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '[发送失败] 已编辑 · 没发出去');
    });

    test('媒体发送中预览仍包裹类型标签（[图片]）', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '/tmp/a.png',
          msgType: 2,
          status: 0,
          createdAt: '2026-04-05T10:07:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '[发送中] [图片]');
    });

    test('媒体发送失败预览为「[发送失败] [图片]」', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '/tmp/b.png',
          msgType: 2,
          status: 2,
          createdAt: '2026-04-05T10:08:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '[发送失败] [图片]');
    });

    test('撤回优先于发送失败等状态，预览仍为「此消息已撤回」', () {
      final provider = _providerForPreviewTests();
      _upsertPrivateOutgoing(
        provider,
        MessageDTO(
          fromUserId: selfId,
          toUserId: peerId,
          content: '矛盾字段',
          msgType: 1,
          isRecalled: true,
          status: 2,
          createdAt: '2026-04-05T10:09:00',
        ),
        selfUserId: selfId,
      );
      expect(_lastMessageForPeer(provider, peerId), '此消息已撤回');
    });

    test('recallMessage 在会话接口 lastMessage 滞后时仍刷新为「此消息已撤回」', () async {
      const msgId = 501;
      final api = FakeMessageApi();
      api.getPrivateMessagesHandler =
          (int toUserId, int page, int size) async {
        expect(toUserId, peerId);
        expect(page, 1);
        expect(size, 20);
        return ResponseDTO<List<MessageDTO>>(
          code: 200,
          message: 'ok',
          data: <MessageDTO>[
            MessageDTO(
              id: msgId,
              fromUserId: selfId,
              toUserId: peerId,
              content: '将撤回',
              msgType: 1,
              status: 1,
              createdAt: '2026-04-05T11:00:00',
            ),
          ],
        );
      };
      api.getConversationsHandler = () async {
        return ResponseDTO<List<ConversationDTO>>(
          code: 200,
          message: 'ok',
          data: <ConversationDTO>[
            ConversationDTO(
              id: peerId,
              userId: 1,
              targetId: peerId,
              type: 1,
              name: 'Peer',
              lastMessage: '接口仍是旧文案',
              lastMessageTime: '2026-04-05T11:00:00',
            ),
          ],
        );
      };
      api.recallMessageHandler = (_) async {
        return ResponseDTO<String>(
          code: 200,
          message: 'ok',
          data: 'ok',
        );
      };
      final provider = MessageProvider(api: api);

      await provider.loadPrivateMessages(peerId, 1, 20);
      await provider.loadConversations();
      expect(
        provider.conversations.firstWhere((c) => c.targetId == peerId).lastMessage,
        '接口仍是旧文案',
      );

      final ok = await provider.recallMessage(msgId);
      expect(ok, isTrue);
      expect(
        provider.conversations.firstWhere((c) => c.targetId == peerId).lastMessage,
        '此消息已撤回',
      );
    });

    test('editMessage 在会话接口 lastMessage 滞后时仍刷新为「已编辑 · 新内容」', () async {
      const msgId = 502;
      final api = FakeMessageApi();
      api.getPrivateMessagesHandler =
          (int toUserId, int page, int size) async {
        expect(toUserId, peerId);
        expect(page, 1);
        expect(size, 20);
        return ResponseDTO<List<MessageDTO>>(
          code: 200,
          message: 'ok',
          data: <MessageDTO>[
            MessageDTO(
              id: msgId,
              fromUserId: selfId,
              toUserId: peerId,
              content: '旧正文',
              msgType: 1,
              status: 1,
              createdAt: '2026-04-05T11:30:00',
            ),
          ],
        );
      };
      api.getConversationsHandler = () async {
        return ResponseDTO<List<ConversationDTO>>(
          code: 200,
          message: 'ok',
          data: <ConversationDTO>[
            ConversationDTO(
              id: peerId,
              userId: 1,
              targetId: peerId,
              type: 1,
              name: 'Peer',
              lastMessage: '接口仍是旧文案',
              lastMessageTime: '2026-04-05T11:30:00',
            ),
          ],
        );
      };
      api.editMessageHandler = (messageId, newContent) async {
        expect(messageId, msgId);
        expect(newContent, '新内容');
        return ResponseDTO<MessageDTO>(
          code: 200,
          message: 'ok',
          data: MessageDTO(
            id: messageId,
            fromUserId: selfId,
            toUserId: peerId,
            content: newContent,
            msgType: 1,
            isEdited: true,
            status: 1,
            createdAt: '2026-04-05T11:30:00',
          ),
        );
      };
      final provider = MessageProvider(api: api);

      await provider.loadPrivateMessages(peerId, 1, 20);
      await provider.loadConversations();
      expect(
        provider.conversations.firstWhere((c) => c.targetId == peerId).lastMessage,
        '接口仍是旧文案',
      );

      final ok = await provider.editMessage(msgId, '新内容');
      expect(ok, isTrue);
      expect(
        provider.conversations.firstWhere((c) => c.targetId == peerId).lastMessage,
        '已编辑 · 新内容',
      );
    });
  });

  group('MessageProvider replyMessage', () {
    test('replyMessage merges replyToMsgId when API omits it', () async {
      final api = FakeMessageApi()
        ..getConversationsHandler = () async {
          return ResponseDTO<List<ConversationDTO>>(
            code: 200,
            message: 'ok',
            data: <ConversationDTO>[],
          );
        }
        ..replyMessageHandler = ({
          required int replyToMsgId,
          int? toUserId,
          int? groupId,
          required String content,
          int msgType = 1,
        }) async {
          expect(replyToMsgId, 55);
          return ResponseDTO<MessageDTO>(
            code: 200,
            message: 'ok',
            data: MessageDTO(
              id: 9001,
              fromUserId: 1,
              toUserId: 2,
              content: content,
              msgType: 1,
              status: 1,
              createdAt: '2026-04-05T12:00:00',
            ),
          );
        };
      final provider = MessageProvider(api: api);
      await provider.loadConversations();

      final ok = await provider.replyMessage(
        replyToMsgId: 55,
        toUserId: 2,
        content: '答复',
      );

      expect(ok, isTrue);
      expect(provider.messages.length, 1);
      expect(provider.messages.single.replyToMsgId, 55);
      expect(provider.messages.single.id, 9001);
    });

    test('replyMessage replaces optimistic row and preserves replyToMsgId', () async {
      final api = FakeMessageApi()
        ..getConversationsHandler = () async {
          return ResponseDTO<List<ConversationDTO>>(
            code: 200,
            message: 'ok',
            data: <ConversationDTO>[],
          );
        }
        ..replyMessageHandler = ({
          required int replyToMsgId,
          int? toUserId,
          int? groupId,
          required String content,
          int msgType = 1,
        }) async {
          return ResponseDTO<MessageDTO>(
            code: 200,
            message: 'ok',
            data: MessageDTO(
              id: 9002,
              fromUserId: 1,
              toUserId: 2,
              content: content,
              msgType: 1,
              status: 1,
              replyToMsgId: replyToMsgId,
              createdAt: '2026-04-05T12:00:01',
            ),
          );
        };
      final provider = MessageProvider(api: api);
      await provider.loadConversations();

      final localId = provider.addOptimisticTextMessage(
        targetId: 2,
        type: 1,
        content: '答复',
        fromUserId: 1,
        replyToMsgId: 55,
      );
      expect(localId, lessThan(0));
      expect(provider.messages.single.replyToMsgId, 55);
      expect(provider.messages.single.status, 0);

      final ok = await provider.replyMessage(
        replyToMsgId: 55,
        toUserId: 2,
        content: '答复',
        optimisticLocalId: localId,
      );

      expect(ok, isTrue);
      expect(provider.messages.length, 1);
      expect(provider.messages.single.id, 9002);
      expect(provider.messages.single.replyToMsgId, 55);
    });

    test('replyMessage API 失败时乐观消息仍保留 replyToMsgId', () async {
      final api = FakeMessageApi()
        ..getConversationsHandler = () async {
          return ResponseDTO<List<ConversationDTO>>(
            code: 200,
            message: 'ok',
            data: <ConversationDTO>[],
          );
        }
        ..replyMessageHandler = ({
          required int replyToMsgId,
          int? toUserId,
          int? groupId,
          required String content,
          int msgType = 1,
        }) async {
          return ResponseDTO<MessageDTO>(
            code: 500,
            message: 'network',
            data: null,
          );
        };
      final provider = MessageProvider(api: api);
      await provider.loadConversations();

      final localId = provider.addOptimisticTextMessage(
        targetId: 2,
        type: 1,
        content: '答复',
        fromUserId: 1,
        replyToMsgId: 55,
      );
      final ok = await provider.replyMessage(
        replyToMsgId: 55,
        toUserId: 2,
        content: '答复',
        optimisticLocalId: localId,
      );

      expect(ok, isFalse);
      expect(provider.messages.length, 1);
      expect(provider.messages.single.replyToMsgId, 55);
      expect(provider.messages.single.status, 2);
      expect(provider.messages.single.id, localId);
    });

    test('replyMessage 失败后重试成功仍携带 replyToMsgId 并原地替换为服务端 id', () async {
      var n = 0;
      final api = FakeMessageApi()
        ..getConversationsHandler = () async {
          return ResponseDTO<List<ConversationDTO>>(
            code: 200,
            message: 'ok',
            data: <ConversationDTO>[],
          );
        }
        ..replyMessageHandler = ({
          required int replyToMsgId,
          int? toUserId,
          int? groupId,
          required String content,
          int msgType = 1,
        }) async {
          n++;
          if (n == 1) {
            return ResponseDTO<MessageDTO>(
              code: 500,
              message: 'fail',
              data: null,
            );
          }
          return ResponseDTO<MessageDTO>(
            code: 200,
            message: 'ok',
            data: MessageDTO(
              id: 8080,
              fromUserId: 1,
              toUserId: 2,
              content: content,
              msgType: 1,
              status: 1,
              replyToMsgId: replyToMsgId,
              createdAt: '2026-04-06T12:01:00',
            ),
          );
        };
      final provider = MessageProvider(api: api);
      await provider.loadConversations();

      final localId = provider.addOptimisticTextMessage(
        targetId: 2,
        type: 1,
        content: '答复正文',
        fromUserId: 1,
        replyToMsgId: 55,
      );
      expect(
        await provider.replyMessage(
          replyToMsgId: 55,
          toUserId: 2,
          content: '答复正文',
          optimisticLocalId: localId,
        ),
        isFalse,
      );

      final text = provider.prepareRetryFailedTextMessage(
        messageId: localId,
        targetId: 2,
        type: 1,
        fromUserId: 1,
      );
      expect(text, '答复正文');
      expect(
        await provider.replyMessage(
          replyToMsgId: 55,
          toUserId: 2,
          content: text!,
          optimisticLocalId: localId,
        ),
        isTrue,
      );

      expect(provider.messages.length, 1);
      expect(provider.messages.single.id, 8080);
      expect(provider.messages.single.replyToMsgId, 55);
      expect(provider.messages.single.status, 1);
      expect(n, 2);
    });
  });
}
