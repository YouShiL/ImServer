import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_conv_source_log.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/conversation_summary.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/identity_resolver.dart';

/// 我方消息：与 [MessageSendState] 一一对应（展示层统一入口）。
/// 群聊同样使用本映射；若 SDK 未产生 [read]，将长期停留在「未读」，不伪造已读。
String? mineOutgoingStatusSuffix(MessageSendState state) {
  switch (state) {
    case MessageSendState.sending:
      return '发送中';
    case MessageSendState.failed:
      return '发送失败';
    case MessageSendState.read:
      return '已读';
    case MessageSendState.sent:
      return '未读';
  }
}

enum ChatV2BottomMode {
  idle,
  emoji,
  attach,
}

enum ChatV2MessageType {
  text,
  image,
  file,
  system,
}

class ChatV2HeaderViewModel {
  const ChatV2HeaderViewModel({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
}

class ConversationV2ViewModel {
  const ConversationV2ViewModel({
    this.conversationId,
    required this.targetId,
    required this.type,
    required this.title,
    this.serverConversationName,
    required this.lastMessage,
    required this.timeLabel,
    required this.isTop,
    required this.isMute,
    this.unreadCount = 0,
  });

  /// 同 [ConversationSummary.conversationId]（会话行 id）。
  final int? conversationId;

  /// 同 [ConversationSummary.targetId]；会话操作 API 一律使用此字段。
  final int targetId;
  final int type;
  final String title;

  /// 与 [ConversationSummary.serverConversationName] 对齐，供聊天页 AppBar 再解析。
  final String? serverConversationName;
  final String lastMessage;
  final String? timeLabel;
  final bool isTop;
  final bool isMute;
  final int unreadCount;
}

class ChatV2MessageViewModel {
  const ChatV2MessageViewModel({
    required this.id,
    required this.messageType,
    required this.isMine,
    this.senderName,
    this.text,
    this.plainText,
    this.imageUrl,
    this.timeLabel,
    required this.sendState,
    this.isGroupChat = false,
    this.showSenderNickname = false,
  });

  final String id;
  final ChatV2MessageType messageType;
  final bool isMine;
  final String? senderName;
  final String? text;

  /// 不含气泡状态后缀（如「已读」），用于复制等。
  final String? plainText;

  /// 图片消息时的资源地址（与 [ChatMessage.imageUrl] 一致）。
  final String? imageUrl;
  final String? timeLabel;

  /// 与 [ChatMessage.sendState] 一致；图片气泡用其展示发送中/失败等。
  final MessageSendState sendState;

  /// 与旧 [MessageBubblePresenter.shouldShowGroupSenderName] 一致：群聊对方且发送者相对上一条变化时展示昵称。
  final bool showSenderNickname;

  /// 当前会话是否群聊（用于 meta：群聊己方不展示已读/未读勾文案）。
  final bool isGroupChat;
}

class ChatV2ComposerViewModel {
  const ChatV2ComposerViewModel({
    required this.hintText,
    required this.inputText,
    required this.bottomMode,
  });

  final String hintText;
  final String inputText;
  final ChatV2BottomMode bottomMode;
}

List<ChatV2MessageViewModel> mapFromLegacy(
  List<MessageDTO> rawList,
  int? currentUserId, {
  required IdentityResolver identity,
}) {
  return rawList.map((MessageDTO msg) {
    final bool isMine = _isSameSenderAs(msg, currentUserId);
    final ChatV2MessageType type = switch (msg.msgType) {
      1 => ChatV2MessageType.text,
      _ => ChatV2MessageType.text,
    };

    final String content = msg.content ?? '';
    final int chatType =
        (msg.groupId != null && msg.groupId! > 0) ? 2 : 1;
    final int chatTargetId = chatType == 2
        ? msg.groupId!
        : _privatePeerTargetId(msg, currentUserId);
    final String? profileNick = msg.fromUserInfo?.nickname?.trim();
    return ChatV2MessageViewModel(
      id: (msg.id?.toString() ?? msg.clientMsgNo ?? msg.msgId ?? msg.createdAt ?? '')
              .trim()
              .isEmpty
          ? '${msg.hashCode}'
          : (msg.id?.toString() ?? msg.clientMsgNo ?? msg.msgId ?? msg.createdAt)!,
      messageType: type,
      isMine: isMine,
      senderName: identity.resolveDisplayNameForMessage(
        msg.fromUserId,
        chatType: chatType,
        chatTargetId: chatTargetId,
        profileNickname:
            profileNick != null && profileNick.isNotEmpty ? profileNick : null,
      ),
      text: content,
      plainText: content,
      imageUrl: null,
      timeLabel: msg.createdAt,
      sendState: MessageSendState.sent,
      isGroupChat: chatType == 2,
      showSenderNickname: false,
    );
  }).toList(growable: false);
}

bool _isSameSenderAs(MessageDTO msg, int? currentUserId) {
  if (currentUserId == null) {
    return false;
  }
  return msg.fromUserId == currentUserId;
}

int _privatePeerTargetId(MessageDTO msg, int? currentUserId) {
  final int? fromUserId = msg.fromUserId;
  final int? toUserId = msg.toUserId;
  if (currentUserId != null && fromUserId == currentUserId) {
    return toUserId ?? fromUserId ?? 0;
  }
  return fromUserId ?? toUserId ?? 0;
}

List<ConversationV2ViewModel> buildConversationList(
  List<MessageDTO> rawList,
  int? currentUserId, {
  required IdentityResolver identity,
}) {
  final Map<String, MessageDTO> lastMessageByConversation = <String, MessageDTO>{};

  for (final MessageDTO msg in rawList) {
    final _ConversationKey? key = _resolveConversationKey(msg, currentUserId);
    if (key == null) {
      continue;
    }
    final String mapKey = '${key.type}-${key.targetId}';
    final MessageDTO? existing = lastMessageByConversation[mapKey];
    if (existing == null ||
        _sortTimestamp(msg.createdAt) >= _sortTimestamp(existing.createdAt)) {
      lastMessageByConversation[mapKey] = msg;
    }
  }

  final List<ConversationV2ViewModel> output = lastMessageByConversation.entries
      .map((MapEntry<String, MessageDTO> entry) {
        final MessageDTO msg = entry.value;
        final _ConversationKey key =
            _resolveConversationKey(msg, currentUserId)!;
        return ConversationV2ViewModel(
          conversationId: null,
          targetId: key.targetId,
          type: key.type,
          title: _resolveConversationTitle(key, identity),
          lastMessage: (msg.content ?? '').trim().isEmpty
              ? '[暂无消息]'
              : (msg.content ?? '').trim(),
          timeLabel: msg.createdAt,
          isTop: false,
          isMute: false,
          unreadCount: 0,
        );
      })
      .toList(growable: false);

  output.sort((ConversationV2ViewModel a, ConversationV2ViewModel b) {
    return _sortTimestamp(b.timeLabel).compareTo(_sortTimestamp(a.timeLabel));
  });
  return output;
}

List<ConversationV2ViewModel> buildConversationListFromConversations(
  List<ConversationDTO> conversations, {
  required IdentityResolver identity,
}) {
  final List<ConversationV2ViewModel> output = conversations
      .where((ConversationDTO conversation) {
        return conversation.targetId != null &&
            conversation.targetId! > 0 &&
            conversation.isDeleted != true;
      })
      .map((ConversationDTO conversation) {
        final int targetId = conversation.targetId!;
        final int type = conversation.type ?? 1;
        final String title = identity.resolveTitle(
          targetId,
          type,
          serverConversationName: conversation.name,
        );
        final String draft = (conversation.draft ?? '').trim();
        final String lastMessage = draft.isNotEmpty
            ? '[草稿] $draft'
            : ((conversation.lastMessage ?? '').trim().isNotEmpty
                ? conversation.lastMessage!.trim()
                : '[暂无消息]');

        imConvSourceLog('build_vm_from_messageProvider_dto', <String, Object?>{
          'sourceModel': 'ConversationDTO->ConversationV2ViewModel',
          'sourceApi': 'legacy ConversationDTO list (non-V2 primary)',
          'conversationId': conversation.id?.toString() ?? 'null',
          'userId': conversation.userId?.toString() ?? 'null',
          'targetId': conversation.targetId?.toString() ?? 'null',
          'type': conversation.type?.toString() ?? 'null',
          'name': conversation.name ?? '-',
          'vm_targetId': targetId.toString(),
          'vm_type': type.toString(),
          'vm_title': title,
        });

        return ConversationV2ViewModel(
          conversationId: conversation.id,
          targetId: targetId,
          type: type,
          title: title,
          serverConversationName: conversation.name,
          lastMessage: lastMessage,
          timeLabel: conversation.lastMessageTime,
          isTop: conversation.isTop == true,
          isMute: conversation.isMute == true,
          unreadCount: conversation.unreadCount ?? 0,
        );
      })
      .toList(growable: false);

  output.sort((ConversationV2ViewModel a, ConversationV2ViewModel b) {
    final int topCompare = (b.isTop ? 1 : 0).compareTo(a.isTop ? 1 : 0);
    if (topCompare != 0) {
      return topCompare;
    }
    return _sortTimestamp(b.timeLabel).compareTo(_sortTimestamp(a.timeLabel));
  });
  return output;
}

List<ConversationV2ViewModel> mapConversationSummariesToViewModels(
  List<ConversationSummary> conversations, {
  IdentityResolver? identity,
}) {
  return conversations
      .map(
        (ConversationSummary conversation) {
          final String title = identity == null
              ? conversation.title
              : identity.resolveTitle(
                  conversation.targetId,
                  conversation.type,
                  serverConversationName: conversation.serverConversationName,
                );
          return ConversationV2ViewModel(
            conversationId: conversation.conversationId,
            targetId: conversation.targetId,
            type: conversation.type,
            title: title,
            serverConversationName: conversation.serverConversationName,
            lastMessage: conversation.lastMessage,
            timeLabel: conversation.lastMessageTime,
            isTop: conversation.isTop,
            isMute: conversation.isMuted,
            unreadCount: conversation.unreadCount,
          );
        },
      )
      .toList(growable: false);
}

bool _shouldShowGroupSenderNameV2(
  List<ChatMessage> messages,
  int index,
  int? chatType,
) {
  if (chatType != 2) {
    return false;
  }
  final ChatMessage m = messages[index];
  if (m.isMine) {
    return false;
  }
  if (index <= 0) {
    return true;
  }
  final ChatMessage prev = messages[index - 1];
  if (prev.isMine) {
    return true;
  }
  final int? a = m.senderId;
  final int? b = prev.senderId;
  if (a == null || b == null) {
    return true;
  }
  return a != b;
}

List<ChatV2MessageViewModel> mapChatMessagesToViewModels(
  List<ChatMessage> messages, {
  IdentityResolver? identity,
  int? chatType,
  int? chatTargetId,
}) {
  final List<ChatV2MessageViewModel> out = <ChatV2MessageViewModel>[];
  for (int i = 0; i < messages.length; i++) {
    final ChatMessage message = messages[i];
    final bool isImage = message.imageUrl != null;

    final String? senderLabel = identity != null &&
            chatType != null &&
            chatTargetId != null
        ? identity.resolveDisplayNameForMessage(
            message.senderId,
            chatType: chatType,
            chatTargetId: chatTargetId,
            profileNickname: message.senderProfileNickname,
          )
        : message.senderName;

    out.add(
      ChatV2MessageViewModel(
        id: message.id,
        messageType:
            isImage ? ChatV2MessageType.image : ChatV2MessageType.text,
        isMine: message.isMine,
        senderName: senderLabel,
        text: message.text,
        plainText: message.text,
        imageUrl: isImage ? message.imageUrl : null,
        timeLabel: message.createdAt,
        sendState: message.sendState,
        isGroupChat: chatType == 2,
        showSenderNickname: _shouldShowGroupSenderNameV2(messages, i, chatType),
      ),
    );
  }
  return out;
}

class _ConversationKey {
  const _ConversationKey({
    required this.targetId,
    required this.type,
  });

  final int targetId;
  final int type;
}

_ConversationKey? _resolveConversationKey(MessageDTO msg, int? currentUserId) {
  final int? groupId = msg.groupId;
  if (groupId != null && groupId > 0) {
    return _ConversationKey(targetId: groupId, type: 2);
  }

  final int? fromUserId = msg.fromUserId;
  final int? toUserId = msg.toUserId;
  if (fromUserId == null && toUserId == null) {
    return null;
  }

  final int targetId;
  if (currentUserId != null && fromUserId == currentUserId) {
    targetId = toUserId ?? fromUserId ?? 0;
  } else {
    targetId = fromUserId ?? toUserId ?? 0;
  }
  if (targetId == 0) {
    return null;
  }
  return _ConversationKey(targetId: targetId, type: 1);
}

String _resolveConversationTitle(
  _ConversationKey key,
  IdentityResolver identity,
) {
  return identity.resolveTitle(key.targetId, key.type);
}

int _sortTimestamp(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 0;
  }
  return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
}
