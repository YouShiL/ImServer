/// 己方消息送达标记展示语义（与 [MessageDTO.status] / 已读组合使用）。
enum ChatOutgoingReceipt {
  sending,
  failed,

  /// 单聊：已送达未读
  sentUnread,

  /// 单聊：已读
  read,
}
