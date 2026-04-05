import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_status_banner.dart';

class ChatBlockedBanner extends StatelessWidget {
  const ChatBlockedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatStatusBanner(
      icon: Icons.block_outlined,
      title: '当前无法发送消息',
      subtitle: '由于你已拉黑该用户，输入区仅保留浏览与查看能力。',
      tone: ChatStatusBannerTone.warning,
      compact: true,
    );
  }
}
