import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_bubble_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_file_content_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_image_content_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_system_content_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_text_content_v2.dart';

class ChatMessageItemV2 extends StatelessWidget {
  const ChatMessageItemV2({
    super.key,
    required this.message,
  });

  final ChatV2MessageViewModel message;

  @override
  Widget build(BuildContext context) {
    if (message.messageType == ChatV2MessageType.system) {
      return ChatMessageSystemContentV2(text: message.text ?? '');
    }

    final Widget avatar = Container(
      width: ChatV2Tokens.avatarSize,
      height: ChatV2Tokens.avatarSize,
      decoration: BoxDecoration(
        color: message.isMine ? const Color(0xFFB7E4C7) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        message.isMine ? '我' : 'Ta',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    final Widget bubble = Flexible(
      child: Column(
        crossAxisAlignment:
            message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          if (!message.isMine && (message.senderName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.senderName!,
                style: ChatV2Tokens.headerSubtitle,
              ),
            ),
          ChatMessageBubbleV2(
            isMine: message.isMine,
            child: _buildContent(),
          ),
        ],
      ),
    );

    final List<Widget> children = message.isMine
        ? <Widget>[
            const Spacer(),
            bubble,
            const SizedBox(width: 8),
            avatar,
          ]
        : <Widget>[
            avatar,
            const SizedBox(width: 8),
            bubble,
            const Spacer(),
          ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildContent() {
    switch (message.messageType) {
      case ChatV2MessageType.text:
        return ChatMessageTextContentV2(text: message.text ?? '');
      case ChatV2MessageType.image:
        return ChatMessageImageContentV2(
          imageUrl: message.imageUrl ?? '',
          sendState: message.sendState,
          isMine: message.isMine,
        );
      case ChatV2MessageType.file:
        return ChatMessageFileContentV2(fileName: message.text ?? 'File');
      case ChatV2MessageType.system:
        return ChatMessageSystemContentV2(text: message.text ?? '');
    }
  }
}
