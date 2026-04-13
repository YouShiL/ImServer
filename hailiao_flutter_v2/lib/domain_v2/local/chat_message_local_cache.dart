import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';

/// 会话级消息本地源抽象：后续可替换为 sqflite / drift / sqlite ffi 等跨平台实现，
/// 上层（[ChatCoordinator]）只依赖本接口。
abstract class ChatMessageLocalCache {
  /// 读取该会话最近缓存的一屏或若干条消息；未命中返回 `null` 或空列表由实现约定。
  Future<List<ChatMessage>?> getRecentMessages(String cacheKey);

  /// 覆盖写入最近消息列表（实现侧可按 [maxRetain] 截断保留最新若干条）。
  Future<void> putRecentMessages(
    String cacheKey,
    List<ChatMessage> messages, {
    int maxRetain = 120,
  });

  /// 将 [incoming] 与已存列表按 id 去重合并后写回（可选辅助；合并策略也可完全在 Coordinator 内完成）。
  Future<void> mergeRecentMessages(
    String cacheKey,
    List<ChatMessage> incoming, {
    int maxRetain = 120,
  });
}

/// 进程内内存实现：Android / iOS / Windows 共用同一 Dart 逻辑，无平台分支。
final class MemoryChatMessageLocalCache implements ChatMessageLocalCache {
  MemoryChatMessageLocalCache();

  final Map<String, List<ChatMessage>> _byKey = <String, List<ChatMessage>>{};

  @override
  Future<List<ChatMessage>?> getRecentMessages(String cacheKey) async {
    final List<ChatMessage>? list = _byKey[cacheKey];
    if (list == null || list.isEmpty) {
      return null;
    }
    return List<ChatMessage>.from(list);
  }

  @override
  Future<void> putRecentMessages(
    String cacheKey,
    List<ChatMessage> messages, {
    int maxRetain = 120,
  }) async {
    if (messages.isEmpty) {
      _byKey.remove(cacheKey);
      return;
    }
    final List<ChatMessage> sorted = List<ChatMessage>.from(messages);
    _sortByTime(sorted);
    final List<ChatMessage> kept = sorted.length <= maxRetain
        ? sorted
        : sorted.sublist(sorted.length - maxRetain);
    _byKey[cacheKey] = kept;
  }

  @override
  Future<void> mergeRecentMessages(
    String cacheKey,
    List<ChatMessage> incoming, {
    int maxRetain = 120,
  }) async {
    if (incoming.isEmpty) {
      return;
    }
    final List<ChatMessage>? existing = await getRecentMessages(cacheKey);
    final Map<String, ChatMessage> byId = <String, ChatMessage>{};
    if (existing != null) {
      for (final ChatMessage m in existing) {
        byId[m.id] = m;
      }
    }
    for (final ChatMessage m in incoming) {
      byId[m.id] = m;
    }
    final List<ChatMessage> merged = byId.values.toList();
    await putRecentMessages(cacheKey, merged, maxRetain: maxRetain);
  }

  void _sortByTime(List<ChatMessage> list) {
    list.sort((ChatMessage a, ChatMessage b) {
      final int aTime =
          DateTime.tryParse(a.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
      final int bTime =
          DateTime.tryParse(b.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
      return aTime.compareTo(bTime);
    });
  }
}

