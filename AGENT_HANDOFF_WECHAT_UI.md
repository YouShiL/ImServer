# Agent 交接：Flutter IM「微信式」UI 重构

> 新会话中 `@AGENT_HANDOFF_WECHAT_UI.md` 或粘贴本文件继续。

## 硬性约束（必须遵守）

- **可改**：`lib/screens/**`、`lib/widgets/**`、`lib/theme/**`；**另可改** `lib/providers/message_provider.dart` **仅**会话列表排序/展示顺序。
- **禁止改**：`lib/models/**`、`lib/services/**`、`lib/main.dart`。
- **保持**：MessageProvider、FriendProvider、GroupProvider、AuthProvider、ImEventBridge；不新引入状态管理；不改业务链路/接口字段/路由语义。
- **已改为独立页**（禁止弹窗承载主流程）：添加好友、搜索群聊、聊天记录搜索、编辑群资料。
- **仍可用 dialog**：删除好友/退群/拉黑/撤回等轻确认。

## 会话列表排序（唯一规则）

`MessageProvider._sortConversations()`：**置顶 → 草稿 → 未读数 → lastMessageTime 降序**。`home_screen` 的 `_filteredConversations` 直接使用 `messageProvider.conversations`（不在 UI 层二次 sort）。勿恢复「手动排序菜单」。

## 已完成摘要

- **home_screen**：标题 + 右上角加号菜单（扫一扫/添加好友/创建群聊）；搜索 placeholder「搜索」；轻量横向筛选；`Navigator` → `AddFriendScreen` / `CreateGroupScreen`。
- **group_list**：搜索/建群 → `SearchGroupScreen` / `CreateGroupScreen`（以当前代码为准）。
- **group_detail**：编辑群资料 → `EditGroupProfileScreen`，保存后 `pop(true)` 刷新。
- **chat_screen**：`import chat_message_search_screen.dart`；搜索按钮 → `_openSearchPage()`；已删除仅服务于旧搜索弹窗的死代码。
- **独立页文件**：`add_friend_screen.dart`、`search_group_screen.dart`、`chat_message_search_screen.dart`、`edit_group_profile_screen.dart`、`create_group_screen.dart`；搜索支持：`widgets/chat/chat_message_search_support.dart`。
- **conversation_sort.dart**：已移除使用；排序以 Provider 为准。

## 未完成 / 建议下一优先级

1. **聊天**：`chat_message_bubble`、`chat_input_bar`、`chat_page_scaffold` 等 — 提高密度、弱 meta、输入栏 `[+][框][表情][发送]`、微信式 bottom sheet。
2. **好友 Tab**：申请区分区再扁平化，去掉厚卡感（`home_screen` 内 `_buildRequestSection` / `_buildRequestCard`）。
3. **群信息页**：`group_detail_screen` + `group_header_card` 等 — 白底分组列表、成员行紧贴、危险操作沉底。
4. **个人资料 / 编辑资料**：`user_detail_screen`、`edit_profile_screen` — 左标签右值列表、行项目式编辑、底栏保存。
5. **设置类**：`privacy_settings_screen`、`security_screen` — 去掉阴影大卡片，浅灰底 + 白列表 + 细分割线。
6. **组件统一**：新增或收敛 `ImSection` + 统一 `ImSettingsTile` / ListItem 高度；`ImSearchBar` 可考虑略低于 40 的微信搜索条感。
7. **死代码**：`widgets/chat/conversation_stats_panel.dart` 若无引用可删或接回需求。

## 新会话续作口令示例

> 读取 `AGENT_HANDOFF_WECHAT_UI.md`，在允许目录内继续微信式 UI，从「聊天气泡 + 输入栏」开始，不改 Provider 业务。

---

*最后更新：交接时由前序 Agent 根据仓库状态整理。*
