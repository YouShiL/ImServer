import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';

void main() {
  test('messageOrFallback uses fallback when raw empty', () {
    expect(
      FeedbackUxStrings.messageOrFallback('', FeedbackUxStrings.fallbackSaveFailed),
      FeedbackUxStrings.fallbackSaveFailed,
    );
    expect(
      FeedbackUxStrings.messageOrFallback('   ', FeedbackUxStrings.fallbackOperationFailed),
      FeedbackUxStrings.fallbackOperationFailed,
    );
    expect(
      FeedbackUxStrings.messageOrFallback(null, '自定义'),
      '自定义',
    );
  });

  test('messageOrFallback keeps non-empty server or provider text', () {
    expect(
      FeedbackUxStrings.messageOrFallback('账号异常', FeedbackUxStrings.fallbackSaveFailed),
      '账号异常',
    );
    expect(
      FeedbackUxStrings.messageOrFallback('  限流中  ', FeedbackUxStrings.fallbackSaveFailed),
      '限流中',
    );
  });

  test('danger / confirm dialog copy is stable', () {
    expect(FeedbackUxStrings.dialogTitleDeleteFriend, '删除好友');
    expect(FeedbackUxStrings.dialogActionDeleteFriend, '删除好友');
    expect(FeedbackUxStrings.dialogTitleRemoveMember, '移出成员');
    expect(FeedbackUxStrings.dialogActionRemoveFromGroup, '移出群组');
    expect(FeedbackUxStrings.dialogTitleRecallMessage, '撤回消息');
    expect(FeedbackUxStrings.dialogActionRecallMessage, '撤回消息');
    expect(FeedbackUxStrings.dialogActionTransferOwner, '转让群主');
  });

  test('success SnackBar copy for high-frequency flows', () {
    expect(FeedbackUxStrings.snackProfileSaved, '资料已保存');
    expect(FeedbackUxStrings.snackGroupCreated, '群聊已创建');
    expect(FeedbackUxStrings.snackGroupSettingsSaved, '群资料与设置已保存');
    expect(FeedbackUxStrings.snackFriendRequestSent, '好友申请已发送');
    expect(FeedbackUxStrings.snackQuitGroupDone, '已退出群组');
  });

  test('in-progress button labels use ellipsis …', () {
    expect(FeedbackUxStrings.buttonSavingInProgress, '保存中…');
    expect(FeedbackUxStrings.buttonCreatingInProgress, '创建中…');
    expect(FeedbackUxStrings.buttonSubmittingInProgress, '提交中…');
    expect(FeedbackUxStrings.buttonSendingInProgress, '发送中…');
    expect(FeedbackUxStrings.buttonAddingInProgress, '添加中…');
  });
}
