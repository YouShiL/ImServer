/// 会话列表、聊天搜索、加好友、搜群等入口共用的提示与空态文案（UTF-8）。
///
/// 状态分层（仅 UI 展示，不改协议）：
/// - **空输入校验**：各入口在发起请求前本地判断，使用 [errorKeywordRequired] /
///   [errorUserKeywordRequired] / [errorGroupIdRequired] 等。
/// - **无结果空态**：请求已成功（通常 code==200）但业务数据为空或无匹配时，使用
///   [emptyNoResults] 或与场景相关的 [emptyNoForwardMatch]、[emptyNoFilterMatch]。
/// - **失败态**：code!=200 时，若服务端 [message] trim 后非空，**原样展示**（保留业务含义）；
///   若为空或仅空白，回退 [errorSearchFailed]（见 [messageWhenSearchRequestFailed]）。
///   网络/解析异常等无法拿到响应体时，统一使用 [errorSearchFailed]。
final class SearchUxStrings {
  SearchUxStrings._();

  // --- 搜索框 placeholder / 引导 ---

  /// 首页会话列表（与 haystack：标题、备注、快照名、草稿、消息预览一致）。
  static const String hintConversationList = '搜索会话';

  /// 聊天页「搜索消息」对话框内输入框。
  static const String hintChatHistory = '搜索聊天记录';

  /// 聊天页转发目标 bottom sheet。
  static const String hintForwardTarget = '搜索会话或群名称';

  /// 群列表「按群号搜索」输入框。
  static const String hintGroupBusinessId = '输入群号';

  // --- 空态与说明 ---

  /// 尚未发起搜索时的占位说明（聊天消息搜索）。
  static const String idleEnterKeyword = '输入关键词开始搜索';

  /// 已搜索但无任何匹配记录（与 [_emptyNoResults] 区分：可混用同一用户可见文案）。
  static const String emptyNoResults = '未找到相关结果';

  /// 聊天消息搜索：本地筛选 chip 后无结果（主标题）。
  static const String emptyNoFilterMatch = '当前筛选下暂无内容';

  /// 聊天消息搜索：筛选 chip 后无结果的补充说明。
  static const String emptyNoFilterMatchDetail = '试试切换筛选条件';

  /// 转发目标 sheet 内过滤无结果。
  static const String emptyNoForwardMatch = '未找到相关会话';

  // --- 校验与错误 ---

  /// 关键词为空（通用短提示）。
  static const String errorKeywordRequired = '请输入关键词';

  static const String errorSearchFailed = '搜索失败，请稍后重试';

  /// 加好友 / 群内添加成员：关键词为空。
  static const String errorUserKeywordRequired = '请输入用户号或手机号';

  static const String errorUserSearchFirst = '请先搜索用户';

  static const String errorMemberSearchFirst = '请先搜索成员';

  static const String errorGroupIdRequired = '请输入群号';

  static String keywordHintForUserSearch(String searchType) {
    return searchType == 'phone' ? '输入手机号' : '输入用户号';
  }

  /// 搜索类 HTTP 已返回但 `isSuccess == false` 时用于一行错误提示。
  static String messageWhenSearchRequestFailed(String serverMessage) {
    final String t = serverMessage.trim();
    return t.isEmpty ? errorSearchFailed : t;
  }
}
