// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_local_database.dart';

// ignore_for_file: type=lint
class $ChatCachedMessagesTable extends ChatCachedMessages
    with TableInfo<$ChatCachedMessagesTable, ChatCachedMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatCachedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    messageId,
    payloadJson,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_cached_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatCachedMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey, messageId};
  @override
  ChatCachedMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatCachedMessageRow(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $ChatCachedMessagesTable createAlias(String alias) {
    return $ChatCachedMessagesTable(attachedDatabase, alias);
  }
}

class ChatCachedMessageRow extends DataClass
    implements Insertable<ChatCachedMessageRow> {
  final String cacheKey;
  final String messageId;
  final String payloadJson;
  final int createdAtMs;
  const ChatCachedMessageRow({
    required this.cacheKey,
    required this.messageId,
    required this.payloadJson,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['message_id'] = Variable<String>(messageId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  ChatCachedMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatCachedMessagesCompanion(
      cacheKey: Value(cacheKey),
      messageId: Value(messageId),
      payloadJson: Value(payloadJson),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory ChatCachedMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatCachedMessageRow(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      messageId: serializer.fromJson<String>(json['messageId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'messageId': serializer.toJson<String>(messageId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  ChatCachedMessageRow copyWith({
    String? cacheKey,
    String? messageId,
    String? payloadJson,
    int? createdAtMs,
  }) => ChatCachedMessageRow(
    cacheKey: cacheKey ?? this.cacheKey,
    messageId: messageId ?? this.messageId,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  ChatCachedMessageRow copyWithCompanion(ChatCachedMessagesCompanion data) {
    return ChatCachedMessageRow(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatCachedMessageRow(')
          ..write('cacheKey: $cacheKey, ')
          ..write('messageId: $messageId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheKey, messageId, payloadJson, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatCachedMessageRow &&
          other.cacheKey == this.cacheKey &&
          other.messageId == this.messageId &&
          other.payloadJson == this.payloadJson &&
          other.createdAtMs == this.createdAtMs);
}

class ChatCachedMessagesCompanion
    extends UpdateCompanion<ChatCachedMessageRow> {
  final Value<String> cacheKey;
  final Value<String> messageId;
  final Value<String> payloadJson;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const ChatCachedMessagesCompanion({
    this.cacheKey = const Value.absent(),
    this.messageId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatCachedMessagesCompanion.insert({
    required String cacheKey,
    required String messageId,
    required String payloadJson,
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       messageId = Value(messageId),
       payloadJson = Value(payloadJson),
       createdAtMs = Value(createdAtMs);
  static Insertable<ChatCachedMessageRow> custom({
    Expression<String>? cacheKey,
    Expression<String>? messageId,
    Expression<String>? payloadJson,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (messageId != null) 'message_id': messageId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatCachedMessagesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? messageId,
    Value<String>? payloadJson,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return ChatCachedMessagesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      messageId: messageId ?? this.messageId,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatCachedMessagesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('messageId: $messageId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChatLocalDriftDatabase extends GeneratedDatabase {
  _$ChatLocalDriftDatabase(QueryExecutor e) : super(e);
  $ChatLocalDriftDatabaseManager get managers =>
      $ChatLocalDriftDatabaseManager(this);
  late final $ChatCachedMessagesTable chatCachedMessages =
      $ChatCachedMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [chatCachedMessages];
}

typedef $$ChatCachedMessagesTableCreateCompanionBuilder =
    ChatCachedMessagesCompanion Function({
      required String cacheKey,
      required String messageId,
      required String payloadJson,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$ChatCachedMessagesTableUpdateCompanionBuilder =
    ChatCachedMessagesCompanion Function({
      Value<String> cacheKey,
      Value<String> messageId,
      Value<String> payloadJson,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

class $$ChatCachedMessagesTableFilterComposer
    extends Composer<_$ChatLocalDriftDatabase, $ChatCachedMessagesTable> {
  $$ChatCachedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatCachedMessagesTableOrderingComposer
    extends Composer<_$ChatLocalDriftDatabase, $ChatCachedMessagesTable> {
  $$ChatCachedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatCachedMessagesTableAnnotationComposer
    extends Composer<_$ChatLocalDriftDatabase, $ChatCachedMessagesTable> {
  $$ChatCachedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$ChatCachedMessagesTableTableManager
    extends
        RootTableManager<
          _$ChatLocalDriftDatabase,
          $ChatCachedMessagesTable,
          ChatCachedMessageRow,
          $$ChatCachedMessagesTableFilterComposer,
          $$ChatCachedMessagesTableOrderingComposer,
          $$ChatCachedMessagesTableAnnotationComposer,
          $$ChatCachedMessagesTableCreateCompanionBuilder,
          $$ChatCachedMessagesTableUpdateCompanionBuilder,
          (
            ChatCachedMessageRow,
            BaseReferences<
              _$ChatLocalDriftDatabase,
              $ChatCachedMessagesTable,
              ChatCachedMessageRow
            >,
          ),
          ChatCachedMessageRow,
          PrefetchHooks Function()
        > {
  $$ChatCachedMessagesTableTableManager(
    _$ChatLocalDriftDatabase db,
    $ChatCachedMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatCachedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatCachedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatCachedMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatCachedMessagesCompanion(
                cacheKey: cacheKey,
                messageId: messageId,
                payloadJson: payloadJson,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String messageId,
                required String payloadJson,
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => ChatCachedMessagesCompanion.insert(
                cacheKey: cacheKey,
                messageId: messageId,
                payloadJson: payloadJson,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatCachedMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatLocalDriftDatabase,
      $ChatCachedMessagesTable,
      ChatCachedMessageRow,
      $$ChatCachedMessagesTableFilterComposer,
      $$ChatCachedMessagesTableOrderingComposer,
      $$ChatCachedMessagesTableAnnotationComposer,
      $$ChatCachedMessagesTableCreateCompanionBuilder,
      $$ChatCachedMessagesTableUpdateCompanionBuilder,
      (
        ChatCachedMessageRow,
        BaseReferences<
          _$ChatLocalDriftDatabase,
          $ChatCachedMessagesTable,
          ChatCachedMessageRow
        >,
      ),
      ChatCachedMessageRow,
      PrefetchHooks Function()
    >;

class $ChatLocalDriftDatabaseManager {
  final _$ChatLocalDriftDatabase _db;
  $ChatLocalDriftDatabaseManager(this._db);
  $$ChatCachedMessagesTableTableManager get chatCachedMessages =>
      $$ChatCachedMessagesTableTableManager(_db, _db.chatCachedMessages);
}
