import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/group_dto.dart';

/// 统一 IM 展示名与会话标题解析（好友备注 / 昵称 / 群成员 / 群名），避免在业务层散落 `senderName` 与 `用户 $id`。
class IdentityResolver {
  IdentityResolver({
    List<FriendDTO> Function()? getFriends,
    List<GroupDTO> Function()? getGroups,
    String? Function(int groupId, int userId)? getGroupMemberDisplayName,
  })  : _getFriends = getFriends ?? _emptyFriends,
        _getGroups = getGroups ?? _emptyGroups,
        _getGroupMemberDisplayName = getGroupMemberDisplayName;

  static List<FriendDTO> _emptyFriends() => const <FriendDTO>[];
  static List<GroupDTO> _emptyGroups() => const <GroupDTO>[];

  final List<FriendDTO> Function() _getFriends;
  final List<GroupDTO> Function() _getGroups;
  final String? Function(int groupId, int userId)? _getGroupMemberDisplayName;

  FriendDTO? _friendForUserId(int userId) {
    for (final FriendDTO f in _getFriends()) {
      if (f.friendUserId == userId) {
        return f;
      }
    }
    return null;
  }

  GroupDTO? _groupForId(int groupId) {
    for (final GroupDTO g in _getGroups()) {
      if (g.id == groupId) {
        return g;
      }
    }
    return null;
  }

  /// 会话列表 / AppBar：
  /// - 私聊：Friend.remark > 好友昵称 > 服务端会话名 > `用户 {id}`（好友关系优先于占位会话名）。
  /// - 群聊：服务端名 > GroupDTO.groupName > `群聊 {id}`。
  String resolveTitle(
    int targetId,
    int type, {
    String? serverConversationName,
  }) {
    if (type == 2) {
      final String server = (serverConversationName ?? '').trim();
      if (server.isNotEmpty) {
        return server;
      }
      final GroupDTO? g = _groupForId(targetId);
      final String name = (g?.groupName ?? '').trim();
      if (name.isNotEmpty) {
        return name;
      }
      return _groupFallbackTitle(targetId);
    }
    final FriendDTO? f = _friendForUserId(targetId);
    if (f != null) {
      final String remark = (f.remark ?? '').trim();
      if (remark.isNotEmpty) {
        return remark;
      }
      final String nick = (f.friendUserInfo?.nickname ?? '').trim();
      if (nick.isNotEmpty) {
        return nick;
      }
    }
    final String server = (serverConversationName ?? '').trim();
    if (server.isNotEmpty) {
      return server;
    }
    return _privateFallbackLabel(targetId);
  }

  /// 消息气泡发送者展示：私聊与单聊链一致；群聊优先群成员昵称，再好友链，再资料昵称，最后兜底。
  String resolveDisplayNameForMessage(
    int? senderId, {
    required int chatType,
    required int chatTargetId,
    String? profileNickname,
  }) {
    if (senderId == null || senderId <= 0) {
      return _unknownSenderLabel();
    }
    if (chatType == 2) {
      final String? gm =
          _getGroupMemberDisplayName?.call(chatTargetId, senderId);
      final String g = (gm ?? '').trim();
      if (g.isNotEmpty) {
        return g;
      }
    }
    return _privateDisplayNameForUserId(
      senderId,
      profileNickname: profileNickname,
    );
  }

  /// Friend.remark > FriendUserInfo.nickname > 用户资料昵称 > 兜底。
  String _privateDisplayNameForUserId(
    int userId, {
    String? profileNickname,
  }) {
    final FriendDTO? f = _friendForUserId(userId);
    final String remark = (f?.remark ?? '').trim();
    if (remark.isNotEmpty) {
      return remark;
    }
    final String nick = (f?.friendUserInfo?.nickname ?? '').trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    final String profile = (profileNickname ?? '').trim();
    if (profile.isNotEmpty) {
      return profile;
    }
    return _privateFallbackLabel(userId);
  }

  String _groupFallbackTitle(int groupId) {
    return '群聊 $groupId';
  }

  String _privateFallbackLabel(int userId) {
    return '用户 $userId';
  }

  /// 与 [resolveTitle] 私聊末路一致；用于预览更新时避免用兜底名覆盖缓存里已有更好展示名。
  bool isPrivateFallbackTitle(String? title, int targetId) {
    return (title ?? '').trim() == _privateFallbackLabel(targetId);
  }

  String _unknownSenderLabel() {
    return '用户';
  }
}
