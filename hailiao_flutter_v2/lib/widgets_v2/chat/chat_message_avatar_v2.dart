import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

/// 与旧 [ChatMessageAvatar] 一致：圆形占位 + 图标，不展示「我/Ta」文字。
class ChatMessageAvatarV2 extends StatelessWidget {
  const ChatMessageAvatarV2({
    super.key,
    required this.isMine,
  });

  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ChatV2Tokens.avatarSize,
      height: ChatV2Tokens.avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMine ? const Color(0xFFB7E4C7) : const Color(0xFFE5E7EB),
        border: Border.all(
          color: isMine ? const Color(0xFF8FD4A8) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Icon(
        isMine ? Icons.person : Icons.person_outline,
        size: 20,
        color: isMine ? const Color(0xFF166534) : const Color(0xFF64748B),
      ),
    );
  }
}
