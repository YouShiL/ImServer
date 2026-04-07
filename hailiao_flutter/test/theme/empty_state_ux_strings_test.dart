import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';

void main() {
  test('EmptyStateUxStrings 会话/聊天/群列表口径', () {
    expect(EmptyStateUxStrings.conversationListEmptyTitle, '暂无会话');
    expect(
      EmptyStateUxStrings.conversationFilterEmptyTitle,
      '当前筛选下暂无内容',
    );
    expect(EmptyStateUxStrings.chatNoMessagesDetail, '发一条消息，开启这段对话');
    expect(EmptyStateUxStrings.groupListEmptyTitle, '暂无群组');
    expect(
      EmptyStateUxStrings.groupPendingJoinRequestsEmptyTitle,
      '暂无入群申请',
    );
    expect(
      EmptyStateUxStrings.groupPendingJoinRequestsEmptyDetail,
      contains('入群请求'),
    );
    expect(EmptyStateUxStrings.groupInfoNotLoadedTitle, '未加载到相关信息');
    expect(
      EmptyStateUxStrings.userTargetMissingMessage,
      '未加载到用户信息，请返回上一页后重试。',
    );
  });
}
