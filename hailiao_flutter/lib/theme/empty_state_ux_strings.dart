/// 列表页、聊天空消息、资料与群详情等场景的共用空态文案（UTF-8）。
///
/// 与 [SearchUxStrings] 分工：后者偏「搜索入口/HTTP 搜索失败回退」；本类偏「无数据 /
/// 筛选空列表 / 对象未就绪」等展示层口径。
final class EmptyStateUxStrings {
  EmptyStateUxStrings._();

  // --- 首页会话列表 ---

  static const String conversationListEmptyTitle = '暂无会话';
  static const String conversationListEmptyDetail =
      '去添加好友或开始聊天';

  /// 有数据，但当前筛选 Chip 下无一行（且搜索框为空）。
  static const String conversationFilterEmptyTitle = '当前筛选下暂无内容';
  static const String conversationFilterEmptyDetail = '试试切换筛选条件';

  /// 有数据，关键词过滤后无匹配；主标题请与 [SearchUxStrings.emptyNoResults] 一致。
  static const String conversationSearchNoMatchDetail =
      '试试更换关键词或清空搜索';

  // --- 聊天页 ---

  static const String chatNoMessagesTitle = '开始聊天';
  static const String chatNoMessagesDetail = '发一条消息，开启这段对话';

  // --- 群列表 ---

  static const String groupListEmptyTitle = '暂无群组';
  static const String groupListEmptyDetail =
      '你创建或加入的群聊会显示在这里';

  static const String groupMyJoinRequestsEmptyTitle = '暂无入群申请';
  static const String groupMyJoinRequestsEmptyDetail =
      '提交后的审核进度会显示在这里';

  // --- 群详情（管理员区块等） ---

  static const String groupPendingJoinRequestsEmptyTitle = '暂无入群申请';
  static const String groupPendingJoinRequestsEmptyDetail =
      '有新的入群请求时会显示在这里';

  static const String groupMembersEmptyTitle = '暂无成员';
  static const String groupMembersEmptyDetail =
      '成员列表加载成功后会显示在这里';

  /// 详情已拉取但 [GroupDTO] 仍不可用等边界。
  static const String groupInfoNotLoadedTitle = '未加载到相关信息';
  static const String groupInfoNotLoadedDetail = '请下拉刷新或稍后重试';

  static const String groupTargetMissingMessage =
      '未加载到群组信息，请返回上一页后重试。';

  // --- 用户资料 ---

  static const String userTargetMissingMessage =
      '未加载到用户信息，请返回上一页后重试。';

  static const String userProfileNotLoadedTitle = '未加载到用户资料';
  static const String userProfileNotLoadedDetail =
      '请稍后重试，或返回上一页重新进入。';
}
