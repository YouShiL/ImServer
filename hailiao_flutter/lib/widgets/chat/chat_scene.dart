/// 聊天展示场景：单聊 / 群聊共用同一套消息 UI，仅少量展示与 meta 规则不同。
enum ChatScene {
  single,
  group,
}

extension ChatSceneX on ChatScene {
  bool get isGroupChat => this == ChatScene.group;

  /// 与 [ConversationDTO.type]、聊天路由 `arguments['type']` 一致：1 单聊 / 2 群聊。
  int get conversationType => isGroupChat ? 2 : 1;
}

ChatScene chatSceneFromConversationType(int? type) =>
    type == 2 ? ChatScene.group : ChatScene.single;
