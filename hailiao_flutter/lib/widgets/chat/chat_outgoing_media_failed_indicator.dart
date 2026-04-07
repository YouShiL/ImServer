import 'package:flutter/material.dart';

/// 微信式：己方图片/视频发送失败时，气泡左侧小红圈「!」，点击重试。
class ChatOutgoingMediaFailedIndicator extends StatelessWidget {
  const ChatOutgoingMediaFailedIndicator({super.key, required this.onTap});

  final VoidCallback onTap;

  /// 接近微信失败标记的红色。
  static const Color _failRed = Color(0xFFFA5151);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _failRed,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
