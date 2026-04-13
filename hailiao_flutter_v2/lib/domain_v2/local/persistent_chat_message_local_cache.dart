import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/local/chat_message_cache_dto.dart';
import 'package:hailiao_flutter_v2/domain_v2/local/chat_message_local_cache.dart';
import 'package:hailiao_flutter_v2/domain_v2/local/drift/chat_local_database.dart';

/// Drift + SQLite 持久化实现；与平台无关，可替换为其他 [ChatMessageLocalCache]。
final class PersistentChatMessageLocalCache implements ChatMessageLocalCache {
  PersistentChatMessageLocalCache._();

  /// 进程内单例；首次访问任一异步方法时懒打开数据库。
  static final PersistentChatMessageLocalCache instance =
      PersistentChatMessageLocalCache._();

  ChatLocalDriftDatabase? _db;
  Future<void>? _openFuture;

  Future<ChatLocalDriftDatabase> _ensureDb() async {
    if (_db != null) {
      return _db!;
    }
    _openFuture ??= _openInner();
    await _openFuture;
    return _db!;
  }

  Future<void> _openInner() async {
    final ChatLocalDriftDatabase db =
        ChatLocalDriftDatabase(openChatLocalDbConnection());
    _db = db;
    if (kDebugMode) {
      debugPrint('[chat.localStore] init');
    }
  }

  @override
  Future<List<ChatMessage>?> getRecentMessages(String cacheKey) async {
    final ChatLocalDriftDatabase db = await _ensureDb();
    final List<ChatCachedMessageRow> rows =
        await (db.select(db.chatCachedMessages)
              ..where((t) => t.cacheKey.equals(cacheKey))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
            .get();
    if (rows.isEmpty) {
      if (kDebugMode) {
        debugPrint('[chat.localStore] query cacheKey=$cacheKey count=0');
      }
      return null;
    }
    final List<ChatMessage> out = <ChatMessage>[];
    for (final ChatCachedMessageRow r in rows) {
      try {
        out.add(ChatMessageCacheDto.decode(r.payloadJson));
      } catch (_) {
        // 单行损坏不阻塞整会话
      }
    }
    if (out.isEmpty) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('[chat.localStore] query cacheKey=$cacheKey count=${out.length}');
    }
    return out;
  }

  @override
  Future<void> putRecentMessages(
    String cacheKey,
    List<ChatMessage> messages, {
    int maxRetain = 120,
  }) async {
    final ChatLocalDriftDatabase db = await _ensureDb();
    if (messages.isEmpty) {
      await (db.delete(db.chatCachedMessages)
            ..where((t) => t.cacheKey.equals(cacheKey)))
          .go();
      if (kDebugMode) {
        debugPrint('[chat.localStore] upsert cacheKey=$cacheKey count=0 (cleared)');
      }
      return;
    }

    final List<ChatMessage> sorted = List<ChatMessage>.from(messages);
    sorted.sort(
      (ChatMessage a, ChatMessage b) => ChatMessageCacheDto.createdAtMillis(a)
          .compareTo(ChatMessageCacheDto.createdAtMillis(b)),
    );
    final List<ChatMessage> kept = sorted.length <= maxRetain
        ? sorted
        : sorted.sublist(sorted.length - maxRetain);

    await db.transaction(() async {
      await (db.delete(db.chatCachedMessages)
            ..where((t) => t.cacheKey.equals(cacheKey)))
          .go();
      for (final ChatMessage m in kept) {
        await db.into(db.chatCachedMessages).insert(
              ChatCachedMessagesCompanion.insert(
                cacheKey: cacheKey,
                messageId: m.id,
                payloadJson: ChatMessageCacheDto.encode(m),
                createdAtMs: ChatMessageCacheDto.createdAtMillis(m),
              ),
            );
      }
    });
    if (kDebugMode) {
      debugPrint(
        '[chat.localStore] upsert cacheKey=$cacheKey count=${kept.length}',
      );
      debugPrint('[chat.localStore] trim cacheKey=$cacheKey keep=$maxRetain');
    }
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
}

/// 全局默认缓存实现（Drift 持久化）；[ChatV2Page] / 测试可注入 [MemoryChatMessageLocalCache] 覆盖。
final ChatMessageLocalCache defaultChatMessageLocalCache =
    PersistentChatMessageLocalCache.instance;
