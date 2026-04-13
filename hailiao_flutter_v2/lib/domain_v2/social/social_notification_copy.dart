import 'dart:convert';

import 'package:hailiao_flutter/models/user_notification_dto.dart';

/// Social 通知展示文案与状态副标题（集中映射，避免散落在各组件）。
class SocialNotificationCopy {
  SocialNotificationCopy._();

  /// 待处理类（pending 角标）；未来若 [group_invite_received] 需「确认加入」，可再纳入并分流 UI。
  static const Set<String> pendingEntryTypes = <String>{
    'friend_request_received',
    'group_join_request_received',
  };

  /// 结果/邀请类：点击即应 `handled`，不参与 pending，与 [pendingEntryTypes] 互斥。
  static const Set<String> outcomeTypes = <String>{
    'friend_request_accepted',
    'friend_request_rejected',
    'group_join_request_approved',
    'group_join_request_rejected',
    'group_invite_received',
  };

  static Map<String, dynamic>? parsePayload(String? raw) {
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

  static int? intFromPayload(dynamic v) {
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

  /// 列表主标题（按 type 统一）。
  static String titleFor(UserNotificationDTO n) {
    switch (n.type) {
      case 'friend_request_received':
        return '好友申请';
      case 'friend_request_accepted':
        return '好友申请已通过';
      case 'friend_request_rejected':
        return '好友申请未通过';
      case 'group_join_request_received':
        return '入群申请';
      case 'group_join_request_approved':
        return '入群申请已通过';
      case 'group_join_request_rejected':
        return '入群申请未通过';
      case 'group_invite_received':
        return '群邀请';
      default:
        final String? t = n.title?.trim();
        return t != null && t.isNotEmpty ? t : '通知';
    }
  }

  /// 列表副文案（按 type 统一；无 payload 时回退服务端 body）。
  static String bodyFor(UserNotificationDTO n) {
    switch (n.type) {
      case 'friend_request_received':
        return _trimOr(n.body, '有人请求添加你为好友');
      case 'friend_request_accepted':
      case 'friend_request_rejected':
        return _trimOr(n.body, '好友申请处理结果');
      case 'group_join_request_received':
        return _trimOr(n.body, '有人申请加入群聊');
      case 'group_join_request_approved':
      case 'group_join_request_rejected':
        return _trimOr(n.body, '你的入群申请已有结果');
      case 'group_invite_received':
        return _trimOr(n.body, '你收到一条群邀请');
      default:
        return _trimOr(n.body, '');
    }
  }

  static String _trimOr(String? v, String fallback) {
    final String t = (v ?? '').trim();
    return t.isNotEmpty ? t : fallback;
  }

  /// 已处理 / 已过期副行（「待处理」在列表上用 Chip 展示，避免与 unread 红点混淆）。
  static String? statusLine(String? status) {
    if (status == 'handled') {
      return '已处理';
    }
    if (status == 'expired') {
      return '已过期';
    }
    return null;
  }
}
