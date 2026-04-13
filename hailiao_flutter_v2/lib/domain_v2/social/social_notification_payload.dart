import 'dart:convert';

/// 与后端 `UserNotificationService` 写入的社交通知 payload JSON 对齐。
///
/// 核心定位字段（Long，与库表主键一致）：
/// - [friendRequestId]、[joinRequestId]：单据
/// - [userId]：`User.id`
/// - [groupId]：`GroupChat.id`
/// - [operatorUserId]：审批人 / 邀请人 `User.id`
///
/// 兼容旧键：`fromUserId` / `toUserId` / `inviterUserId` 仅作解析回退，不参与新写入。
abstract final class SocialNotificationPayload {
  SocialNotificationPayload._();

  static const String keyFriendRequestId = 'friendRequestId';
  static const String keyJoinRequestId = 'joinRequestId';
  static const String keyUserId = 'userId';
  static const String keyGroupId = 'groupId';
  static const String keyOperatorUserId = 'operatorUserId';

  static Map<String, dynamic>? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final Object? o = jsonDecode(raw);
      if (o is Map<String, dynamic>) {
        return o;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static int? _int(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return int.tryParse(v.toString());
  }

  /// 好友申请结果等：对方用户主键。优先 [keyUserId]，其次历史 `toUserId` / `fromUserId`。
  static int? userIdForPeer(Map<String, dynamic>? p) {
    if (p == null) {
      return null;
    }
    return _int(p[keyUserId]) ??
        _int(p['toUserId']) ??
        _int(p['fromUserId']);
  }

  /// 入群 / 邀请 / 结果：群主键。仅认 [keyGroupId]（Long）。
  static int? groupChatId(Map<String, dynamic>? p) {
    if (p == null) {
      return null;
    }
    return _int(p[keyGroupId]);
  }

  /// 审批人 / 邀请人。优先 [keyOperatorUserId]，其次历史 `inviterUserId`。
  static int? operatorUserId(Map<String, dynamic>? p) {
    if (p == null) {
      return null;
    }
    return _int(p[keyOperatorUserId]) ?? _int(p['inviterUserId']);
  }
}
