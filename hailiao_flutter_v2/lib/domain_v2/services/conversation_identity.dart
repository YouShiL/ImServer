import 'package:hailiao_flutter_v2/domain_v2/services/im_identity_log.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';
import 'package:wukongimfluttersdk/type/const.dart';
import 'package:wukongimfluttersdk/wkim.dart';

/// 会话实体标识，与 [ConversationSummary.targetId] / [ChatCoordinator.targetId] 一致：
/// - 单聊：对端用户 uid（数值）
/// - 群聊：群 channelId（与 [WKChannelType.group] 对应 type=2）
///
/// SDK 私聊里 [WKMsg.channelID] 有时会等于当前登录 uid（「频道指向自己」），
/// WuKong 在 [WKMessageManager.parsingMsg] / [WKSyncMsg.getWKMsg] 里会将其替换为 [WKMsg.fromUID]；
/// 若某条回调未经过该步骤，必须在映射前做相同归一，否则会把 [fromUID]（自己）误当成会话 target。
abstract final class ConversationIdentity {
  const ConversationIdentity._();

  /// 与会话缓存、活跃会话标记一致：`"$type-$targetId"`。
  static String cacheKey(int targetId, int type) => '$type-$targetId';

  /// 从 SDK 消息解析业务侧会话 targetId（私聊=对端，群聊=群 id）。
  static int? resolveSdkTargetId(WKMsg raw, {required int? currentUserId}) {
    final int? senderId = _parseIntLoose(raw.fromUID);
    if (raw.channelType == WKChannelType.group) {
      final int? r = _parseIntLoose(raw.channelID);
      imIdentityLog('resolveSdkTargetId_group', <String, Object?>{
        'senderId': senderId?.toString(),
        'selfUserId': currentUserId?.toString(),
        'channelId': raw.channelID,
        'channelType': raw.channelType.toString(),
        'resolvedTargetId': r?.toString() ?? 'null',
        'messageType': '2',
        'cacheKey': r != null ? cacheKey(r, 2) : '-',
        'clientId': '-',
        'serverId': '-',
      });
      return r;
    }

    String channelStr = raw.channelID;
    if (channelStr.isNotEmpty && raw.fromUID.isNotEmpty) {
      final String? selfUid = WKIM.shared.options.uid;
      if (selfUid != null && channelStr == selfUid) {
        channelStr = raw.fromUID;
      }
    }
    final int? channelId = _parseIntLoose(channelStr);
    final int? me =
        currentUserId ?? _parseIntLoose(WKIM.shared.options.uid);

    if (me == null) {
      final int? r = channelId ?? senderId;
      imIdentityLog('resolveSdkTargetId_personal_me_null', <String, Object?>{
        'senderId': senderId?.toString(),
        'selfUserId': 'null',
        'channelId': raw.channelID,
        'channelType': raw.channelType.toString(),
        'resolvedTargetId': r?.toString() ?? 'null',
        'messageType': '1',
        'cacheKey': r != null ? cacheKey(r, 1) : '-',
        'clientId': '-',
        'serverId': '-',
      });
      return r;
    }
    if (channelId == me && senderId != null) {
      imIdentityLog('resolveSdkTargetId_personal_channel_is_self', <String, Object?>{
        'senderId': senderId.toString(),
        'selfUserId': me.toString(),
        'channelId': raw.channelID,
        'channelType': raw.channelType.toString(),
        'resolvedTargetId': senderId.toString(),
        'messageType': '1',
        'cacheKey': cacheKey(senderId, 1),
        'clientId': '-',
        'serverId': '-',
      });
      return senderId;
    }
    if (senderId == me) {
      final int? r = channelId;
      imIdentityLog('resolveSdkTargetId_personal_sender_is_self', <String, Object?>{
        'senderId': senderId?.toString(),
        'selfUserId': me.toString(),
        'channelId': raw.channelID,
        'channelType': raw.channelType.toString(),
        'resolvedTargetId': r?.toString() ?? 'null',
        'messageType': '1',
        'cacheKey': r != null ? cacheKey(r, 1) : '-',
        'clientId': '-',
        'serverId': '-',
      });
      return channelId;
    }
    final int? r = senderId ?? channelId;
    imIdentityLog('resolveSdkTargetId_personal_default', <String, Object?>{
      'senderId': senderId?.toString(),
      'selfUserId': me.toString(),
      'channelId': raw.channelID,
      'channelType': raw.channelType.toString(),
      'resolvedTargetId': r?.toString() ?? 'null',
      'messageType': '1',
      'cacheKey': r != null ? cacheKey(r, 1) : '-',
      'clientId': '-',
      'serverId': '-',
    });
    return r;
  }

  static int? _parseIntLoose(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
