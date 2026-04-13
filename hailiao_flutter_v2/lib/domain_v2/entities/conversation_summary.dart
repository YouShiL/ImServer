class ConversationSummary {
  const ConversationSummary({
    this.conversationId,
    required this.targetId,
    required this.type,
    required this.title,
    this.serverConversationName,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.draftText,
    this.isTop = false,
    this.isMuted = false,
  });

  /// 会话表行主键 [ConversationDTO.id]；仅用于展示或与列表 DTO 对齐，**不得**作为 `/api/conversation/{id}` 路径参数（该路径实为 targetId）。
  final int? conversationId;

  /// 业务会话对象 id：私聊为对端 [User.id]，群聊为 [GroupChat.id]；与 [ConversationIdentity.cacheKey]、置顶/静音/删除 API 一致。
  final int targetId;
  final int type;
  final String title;

  /// 服务端会话名（[ConversationDTO.name]），供 [IdentityResolver] 在好友数据晚到时仍能回退展示。
  final String? serverConversationName;
  final String lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final String? draftText;
  final bool isTop;
  final bool isMuted;

  ConversationSummary copyWith({
    int? conversationId,
    int? targetId,
    int? type,
    String? title,
    Object? serverConversationName = _sentinel,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    Object? draftText = _sentinel,
    bool? isTop,
    bool? isMuted,
  }) {
    return ConversationSummary(
      conversationId: conversationId ?? this.conversationId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      title: title ?? this.title,
      serverConversationName: identical(serverConversationName, _sentinel)
          ? this.serverConversationName
          : serverConversationName as String?,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      draftText: identical(draftText, _sentinel) ? this.draftText : draftText as String?,
      isTop: isTop ?? this.isTop,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  static const Object _sentinel = Object();
}
