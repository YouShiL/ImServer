import 'package:flutter/material.dart';

/// 输入条下方的表情 / 附件等面板容器：统一 [AnimatedSize] 与纵向布局，避免散落在页面。
class ChatInputPanelHost extends StatelessWidget {
  const ChatInputPanelHost({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
  });

  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
