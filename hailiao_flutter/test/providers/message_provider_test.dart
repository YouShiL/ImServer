import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';

import '../support/provider_test_fakes.dart';

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
}
