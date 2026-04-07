import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 列表时间轴分隔：与气泡/系统消息视觉体系分离，统一用 [ChatUiTokens.timeSeparatorTextStyle]。
class ChatTimeSeparator extends StatelessWidget {
  const ChatTimeSeparator({
    super.key,
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ChatUiTokens.timelineSeparatorVerticalPadding,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              textAlign: TextAlign.center,
              style: ChatUiTokens.timeSeparatorTextStyle,
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
