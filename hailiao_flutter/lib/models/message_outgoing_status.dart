/// 出站 [MessageDTO.status] 约定（与 [MessageBubblePresenter]、REST/IM 回执对齐）。
///
/// **私聊已读**不占用 `status`，使用 [MessageDTO.isRead]：仅当 `status == sent` 且己方消息
/// `isRead == true` 时 UI 显示双勾「已读」。
abstract final class MessageOutgoingStatus {
  static const int sending = 0;
  static const int sent = 1;
  static const int failed = 2;
}
