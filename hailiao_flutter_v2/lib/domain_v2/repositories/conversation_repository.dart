import 'dart:async';

import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/conversation_summary.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';

abstract class ConversationRepository {
  Future<List<ConversationSummary>> loadConversations();
  Stream<ConversationSummary> watchConversationSummaries();
  Future<ConversationSummary> updateConversationSetting(
    int targetId, {
    required int type,
    bool? isTop,
    bool? isMuted,
  });
  Future<void> deleteConversation(int targetId, {required int type});
  void upsertPreviewFromMessage(
    ChatMessage message, {
    String? title,
    bool clearDraft = false,
  });
  void markConversationActive(int targetId, int type);
  void clearConversationActive(int targetId, int type);
  void clearUnread(int targetId, int type);
  bool isConversationActive(int targetId, int type);
  List<ConversationSummary> getCachedConversations();
}

class ApiConversationRepository implements ConversationRepository {
  ApiConversationRepository({
    required ImMessageMapper mapper,
  }) : _mapper = mapper;

  final ImMessageMapper _mapper;

  static final StreamController<ConversationSummary> _updates =
      StreamController<ConversationSummary>.broadcast();
  static final Map<String, ConversationSummary> _cache =
      <String, ConversationSummary>{};
  static String? _activeConversationKey;

  static void resetSessionState() {
    _cache.clear();
    _activeConversationKey = null;
  }

  @override
  Future<List<ConversationSummary>> loadConversations() async {
    final response = await ApiService.getConversations();
    if (!response.isSuccess || response.data == null) {
      throw Exception(
        response.message.isNotEmpty ? response.message : '加载会话失败',
      );
    }

    final List<ConversationSummary> summaries = response.data!
        .where((dto) => dto.targetId != null && dto.isDeleted != true)
        .map(_mapper.mapConversation)
        .toList(growable: false);

    _cache.clear();
    for (final ConversationSummary summary in summaries) {
      _cache[_key(summary.targetId, summary.type)] = summary;
    }
    return _sortConversations(_cache.values.toList(growable: false));
  }

  @override
  Stream<ConversationSummary> watchConversationSummaries() => _updates.stream;

  @override
  Future<ConversationSummary> updateConversationSetting(
    int targetId, {
    required int type,
    bool? isTop,
    bool? isMuted,
  }) async {
    final ConversationSummary? existing = _cache[_key(targetId, type)];
    final int conversationId = existing?.conversationId ?? targetId;
    final Map<String, dynamic> payload = <String, dynamic>{'type': type};
    if (isTop != null) {
      payload['isTop'] = isTop;
    }
    if (isMuted != null) {
      payload['isMute'] = isMuted;
    }

    final response = await ApiService.updateConversation(conversationId, payload);
    if (!response.isSuccess || response.data == null) {
      throw Exception(
        response.message.isNotEmpty ? response.message : '更新会话设置失败',
      );
    }

    final ConversationSummary updated = _mapper.mapConversation(response.data!);
    _cache[_key(updated.targetId, updated.type)] = updated;
    _updates.add(updated);
    return updated;
  }

  @override
  Future<void> deleteConversation(int targetId, {required int type}) async {
    final ConversationSummary? existing = _cache[_key(targetId, type)];
    final int conversationId = existing?.conversationId ?? targetId;
    final response = await ApiService.deleteConversation(
      conversationId,
      type: type,
    );
    if (!response.isSuccess) {
      throw Exception(
        response.message.isNotEmpty ? response.message : '删除会话失败',
      );
    }
    _cache.remove(_key(targetId, type));
  }

  @override
  void upsertPreviewFromMessage(
    ChatMessage message, {
    String? title,
    bool clearDraft = false,
  }) {
    final String cacheKey = _key(message.targetId, message.type);
    final ConversationSummary? existing = _cache[cacheKey];
    final String resolvedTitle;
    if ((title ?? '').trim().isNotEmpty) {
      resolvedTitle = title!.trim();
    } else if ((existing?.title ?? '').trim().isNotEmpty) {
      resolvedTitle = existing!.title;
    } else if ((message.senderName ?? '').trim().isNotEmpty) {
      resolvedTitle = message.senderName!.trim();
    } else {
      resolvedTitle =
          message.type == 2 ? '群聊 ${message.targetId}' : '用户 ${message.targetId}';
    }

    final bool isActive = isConversationActive(message.targetId, message.type);
    final bool shouldIncrementUnread = !message.isMine && !isActive;
    final ConversationSummary updated = (existing ??
            ConversationSummary(
              targetId: message.targetId,
              type: message.type,
              title: resolvedTitle,
              lastMessage: message.text,
              lastMessageTime: message.createdAt,
            ))
        .copyWith(
          title: resolvedTitle,
          lastMessage: message.text,
          lastMessageTime: message.createdAt,
          unreadCount: shouldIncrementUnread
              ? (existing?.unreadCount ?? 0) + 1
              : 0,
          draftText: clearDraft ? '' : existing?.draftText,
        );

    _cache[cacheKey] = updated;
    _updates.add(updated);
  }

  @override
  void markConversationActive(int targetId, int type) {
    _activeConversationKey = _key(targetId, type);
    clearUnread(targetId, type);
  }

  @override
  void clearConversationActive(int targetId, int type) {
    final String key = _key(targetId, type);
    if (_activeConversationKey == key) {
      _activeConversationKey = null;
    }
  }

  @override
  void clearUnread(int targetId, int type) {
    final String key = _key(targetId, type);
    final ConversationSummary? existing = _cache[key];
    if (existing == null) {
      return;
    }
    final ConversationSummary updated = existing.copyWith(unreadCount: 0);
    _cache[key] = updated;
    _updates.add(updated);
  }

  @override
  bool isConversationActive(int targetId, int type) {
    return _activeConversationKey == _key(targetId, type);
  }

  @override
  List<ConversationSummary> getCachedConversations() {
    return _sortConversations(_cache.values.toList(growable: false));
  }

  static String _key(int targetId, int type) => '$type-$targetId';

  static List<ConversationSummary> _sortConversations(
    List<ConversationSummary> values,
  ) {
    values.sort((a, b) {
      final int topCompare = (b.isTop ? 1 : 0).compareTo(a.isTop ? 1 : 0);
      if (topCompare != 0) {
        return topCompare;
      }
      final int aTime =
          DateTime.tryParse(a.lastMessageTime ?? '')?.millisecondsSinceEpoch ?? 0;
      final int bTime =
          DateTime.tryParse(b.lastMessageTime ?? '')?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return values;
  }
}
