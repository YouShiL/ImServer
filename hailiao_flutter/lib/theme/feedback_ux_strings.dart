/// 表单提交、SnackBar、确认弹窗等操作反馈口径（UTF-8）。
///
/// 与 [SearchUxStrings] 分工：前者偏「搜索入口」；本类偏「保存/提交/危险确认/结果提示」。
final class FeedbackUxStrings {
  FeedbackUxStrings._();

  // --- 通用动作 ---
  static const String actionCancel = '取消';

  // --- 提交按钮（进行中统一用 Unicode 省略号 …）---
  static const String buttonSave = '保存';
  static const String buttonSavingInProgress = '保存中…';

  static const String buttonCreate = '创建';
  static const String buttonCreatingInProgress = '创建中…';

  static const String buttonSubmit = '提交';
  static const String buttonSubmittingInProgress = '提交中…';

  static const String buttonSendRequest = '发送申请';
  static const String buttonSendingInProgress = '发送中…';

  static const String buttonConfirmAddMember = '确认添加';
  static const String buttonAddingInProgress = '添加中…';

  // --- SnackBar：成功（短句）---
  static const String snackProfileSaved = '资料已保存';
  static const String snackGroupCreated = '群聊已创建';
  static const String snackGroupSettingsSaved = '群资料与设置已保存';

  static const String snackFriendRequestSent = '好友申请已发送';
  static const String snackMemberAdded = '成员已添加';
  static const String snackQuitGroupDone = '已退出群组';
  static const String snackDeletedFriend = '已删除好友';
  static const String snackBlocked = '已加入黑名单';
  static const String snackUnblocked = '已解除黑名单';

  static const String snackRecallMessageOk = '已撤回该消息';

  // --- SnackBar / 行内：失败兜底（无有效服务端/Provider 文案时）---
  static const String fallbackSaveFailed = '保存失败，请稍后重试';
  static const String fallbackOperationFailed = '操作失败，请稍后重试';
  static const String fallbackSendFriendRequestFailed = '发送好友申请失败';
  static const String fallbackQuitGroupFailed = '退出群组失败';
  static const String fallbackDeleteFriendFailed = '删除好友失败';
  static const String fallbackRecallFailed = '撤回失败，请稍后重试';

  static const String snackImagePickFailed = '选择图片失败，请重试';

  /// 本地校验或其它非 HTTP 错误提示（头像上传等可单独传 [fallback]）。
  static String messageOrFallback(String? raw, String fallback) {
    final String t = (raw ?? '').trim();
    return t.isEmpty ? fallback : t;
  }

  // --- 危险确认弹窗：标题 / 主按钮（与正文一起在页面内组合）---
  static const String dialogTitleRecallMessage = '撤回消息';
  static const String dialogBodyRecallMessage =
      '撤回后，双方会话中将显示为已撤回。';
  static const String dialogActionRecallMessage = '撤回消息';

  static const String dialogTitleRemoveMember = '移出成员';
  static const String dialogActionRemoveFromGroup = '移出群组';

  static const String dialogTitleTransferOwner = '转让群主';
  static const String dialogActionTransferOwner = '转让群主';

  static const String dialogTitleQuitGroup = '退出群组';
  static const String dialogActionQuitGroup = '退出群组';

  static const String dialogTitleDeleteFriend = '删除好友';
  static const String dialogActionDeleteFriend = '删除好友';

  static const String dialogTitleAddBlacklist = '加入黑名单';
  static const String dialogTitleRemoveBlacklist = '解除黑名单';
  static const String dialogActionAddBlacklist = '加入黑名单';
  static const String dialogActionRemoveBlacklist = '解除黑名单';
}
