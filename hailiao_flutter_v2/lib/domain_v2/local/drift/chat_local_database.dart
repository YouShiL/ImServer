import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'chat_local_database.g.dart';

/// 最近消息缓存表（非完整消息库）；按 cache_key 分区，每会话保留最近若干条。
@DataClassName('ChatCachedMessageRow')
class ChatCachedMessages extends Table {
  TextColumn get cacheKey => text().named('cache_key')();
  TextColumn get messageId => text().named('message_id')();
  TextColumn get payloadJson => text().named('payload_json')();
  IntColumn get createdAtMs => integer().named('created_at_ms')();

  @override
  Set<Column> get primaryKey => <Column>{
        cacheKey,
        messageId,
      };
}

@DriftDatabase(tables: <Type>[ChatCachedMessages])
class ChatLocalDriftDatabase extends _$ChatLocalDriftDatabase {
  ChatLocalDriftDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {},
      );
}

/// 跨平台打开 SQLite（Android / iOS / Windows / macOS / Linux）。
LazyDatabase openChatLocalDbConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationSupportDirectory();
    final File file = File(p.join(dir.path, 'hailiao_chat_message_cache.sqlite'));
    if (kDebugMode) {
      debugPrint('[chat.localStore] open path=${file.path}');
    }
    return NativeDatabase.createInBackground(file);
  });
}
