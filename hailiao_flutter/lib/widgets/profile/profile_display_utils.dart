import 'package:characters/characters.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';

/// 资料卡 / 会话 / 好友行等展示文案与优先级（备注 > 昵称 > 用户号、群成员标题等）。
///
/// 虽落在 `widgets/profile/` 下，但被 [screens]、[providers]、[widgets] 多处引用，属于应用内
/// **展示策略**而非单一 Widget 实现；若迁至 `lib/utils/` 仅目录语义更贴切，会牵动大量 import，
/// 故当前路径刻意保留。头像是否走网络图见 `lib/utils/network_avatar_url.dart`。
final class ProfileDisplayTexts {
  ProfileDisplayTexts._();

  static const String unset = '未设置';

  /// 备注名 > 昵称 > 用户号（`userId`）> [unset]。
  /// [friendRemark] 为好友关系里的备注（trim 后非空优先）。
  static String displayName(UserDTO user, {String? friendRemark}) {
    final String r = (friendRemark ?? '').trim();
    if (r.isNotEmpty) {
      return r;
    }
    final String nick = (user.nickname ?? '').trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    final String uid = (user.userId ?? '').trim();
    if (uid.isNotEmpty) {
      return uid;
    }
    return unset;
  }

  /// 当仅有部分字段时（如群成员、`userInfo` 暂缺）。
  static String displayNameLoose({
    UserDTO? user,
    String? nicknameFallback,
    String? friendRemark,
  }) {
    if (user != null) {
      return displayName(user, friendRemark: friendRemark);
    }
    final String n = (nicknameFallback ?? '').trim();
    if (n.isNotEmpty) {
      return n;
    }
    return unset;
  }

  /// 单聊标题：有对方资料 [peer] 时为 **备注 > 昵称 > 用户号 > 未设置**；
  /// 仅有会话/路由快照时用 [nameFallback]（多为后端下发的昵称）。
  static String singleChatDisplayTitle({
    UserDTO? peer,
    String? friendRemark,
    String? nameFallback,
  }) {
    if (peer != null) {
      return displayName(peer, friendRemark: friendRemark);
    }
    return displayNameLoose(user: null, nicknameFallback: nameFallback);
  }

  /// 与列表标题 [title] 的首个 Unicode 字素一致（表情/部分 emoji 占一字素位）；空标题 → `?`。
  static String listAvatarInitial(String? title) {
    final String t = (title ?? '').trim();
    if (t.isEmpty) {
      return '?';
    }
    return t.characters.first.toUpperCase();
  }

  static String groupMemberTitle(GroupMemberDTO member) {
    return displayNameLoose(
      user: member.userInfo,
      nicknameFallback: member.nickname,
    );
  }

  /// 群成员角色：群主 / 管理员 / 普通成员（与成员列表角标、副文案同源）。
  static String groupMemberRoleLabel(int? role) {
    return switch (role) {
      1 => '群主',
      2 => '管理员',
      _ => '普通成员',
    };
  }

  /// 群成员列表副标题：禁言状态与用户号（角色由列表主行角标单独展示，避免重复）。
  static String groupMemberListSubtitle(GroupMemberDTO member) {
    final String? rawUid = _memberListUserIdRaw(member);
    final String account = accountIdLine(rawUid);
    return <String>[
      if (member.isMute == true) '已被禁言',
      '用户号：$account',
    ].join(' | ');
  }

  static String? _memberListUserIdRaw(GroupMemberDTO member) {
    final String fromInfo = (member.userInfo?.userId ?? '').trim();
    if (fromInfo.isNotEmpty) {
      return member.userInfo!.userId;
    }
    if (member.userId != null) {
      return '${member.userId}';
    }
    return null;
  }

  /// `userId` int 场景下去资料页的快照（例如入群申请）：有 [userInfo] 用其，否则仅 [UserDTO.id]。
  static UserDTO? userDetailSnapshotFromApplicant({
    required int? userId,
    UserDTO? userInfo,
  }) {
    if (userId == null) {
      return null;
    }
    if (userInfo != null) {
      return userInfo;
    }
    return UserDTO(id: userId);
  }

  /// 入群申请列表主标题 / 操作反馈里的人名：有 [GroupJoinRequestDTO.userInfo] 时同 [displayName]；
  /// 否则用 [GroupJoinRequestDTO.userId] 数字串（与副标题在无展示用户号时的兜底一致）。
  static String joinRequestApplicantTitle(GroupJoinRequestDTO request) {
    final UserDTO? info = request.userInfo;
    if (info != null) {
      return displayName(info);
    }
    if (request.userId != null) {
      return '${request.userId}';
    }
    return unset;
  }

  /// 入群申请列表副标题：用户号行 + 可选申请附言。
  static String joinRequestApplicantSubtitle({
    required UserDTO? userInfo,
    int? userIdFallback,
    String? message,
  }) {
    final String? raw = (userInfo?.userId ?? '').trim().isNotEmpty
        ? userInfo!.userId
        : (userIdFallback != null ? '$userIdFallback' : null);
    final String account = accountIdLine(raw);
    final String msg = (message ?? '').trim();
    return <String>[
      '用户号：$account',
      if (msg.isNotEmpty) msg,
    ].join(' | ');
  }

  /// 群成员进入 `/user-detail` 时的 [UserDTO] 快照：优先完整 [GroupMemberDTO.userInfo]；
  /// 否则用群内 [GroupMemberDTO.nickname] + [GroupMemberDTO.userId] 构造最简对象，与 [groupMemberTitle] 展示一致。
  /// [member.userId] 为空时返回 null（调用方不应再推资料页）。
  static UserDTO? userDetailSnapshotFromGroupMember(GroupMemberDTO member) {
    final int? id = member.userId;
    if (id == null) {
      return null;
    }
    final UserDTO? embedded = member.userInfo;
    if (embedded != null) {
      return embedded;
    }
    final String nick = (member.nickname ?? '').trim();
    if (nick.isNotEmpty) {
      return UserDTO(id: id, nickname: nick);
    }
    return UserDTO(id: id);
  }

  /// `null`、空串、纯空白 → [emptyLabel]（默认 [unset]）。
  static String fieldValue(String? raw, {String emptyLabel = unset}) {
    final String t = (raw ?? '').trim();
    return t.isEmpty ? emptyLabel : t;
  }

  /// 账号行：无用户号时用 `-`，与资料「未设置」区分。
  static String accountIdLine(String? userId) {
    final String t = (userId ?? '').trim();
    return t.isEmpty ? '-' : t;
  }

  /// `1` 男，`2` 女；`null` / `0` / 其它 → [unset]。
  static String genderLabel(int? gender) {
    if (gender == 1) {
      return '男';
    }
    if (gender == 2) {
      return '女';
    }
    return unset;
  }

  /// 可展示的 `yyyy-MM-dd`；无法解析则返回空串（再由 [birthdayLabel] 转为未设置）。
  static String birthdayDisplayRaw(String? raw) {
    if (raw == null) {
      return '';
    }
    final String t = raw.trim();
    if (t.isEmpty) {
      return '';
    }
    if (t.length >= 10) {
      final String head = t.substring(0, 10);
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(head)) {
        return head;
      }
    }
    try {
      final DateTime d = DateTime.parse(t).toLocal();
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  static String birthdayLabel(String? raw) {
    final String n = birthdayDisplayRaw(raw);
    return n.isEmpty ? unset : n;
  }
}
