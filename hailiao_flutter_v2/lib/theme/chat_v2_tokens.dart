import 'package:flutter/material.dart';

abstract final class ChatV2Tokens {
  static const Color pageBackground = Color(0xFFEDEDED);
  static const Color headerBackground = Color(0xFFF7F7F7);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFD7D7D7);
  static const Color accent = Color(0xFF07C160);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF808080);
  static const Color tipsBackground = Color(0x00000000);
  static const Color incomingBubble = Colors.white;
  static const Color outgoingBubble = Color(0xFF95EC69);

  static const double headerHeight = 46;
  static const double horizontalPadding = 12;
  static const double messageGap = 12;
  static const double avatarSize = 36;
  /// 与旧 [ChatUiTokens.messageRowHorizontalGap] 对齐：头像与气泡列间距。
  static const double messageRowHorizontalGap = 8;
  /// 己方气泡与右侧头像间距（略大于左侧）。
  static const double messageRowOutgoingAvatarGap = 8;
  static const double messageRowVerticalPadding = 4;
  /// 微信式略窄气泡（约 0.62~0.68 屏宽）。
  static const double bubbleMaxWidthFactor = 0.65;
  static const double bubbleMaxWidth = 260;
  static const double bubbleFooterGap = 4;
  /// 主圆角与「小尾巴」圆角（己方右下角 / 对方左下角更小）。
  static const double bubbleRadiusMain = 12;
  static const double bubbleRadiusTail = 5;
  static const double bubblePaddingH = 11;
  static const double bubblePaddingV = 7;
  static const double metaFontSize = 11;
  static const Color outgoingMetaText = Color(0x99000000);
  static const Color incomingMetaText = Color(0xFF9B9B9B);
  static const double listBottomSpacing = 8;
  static const double inputBarMinHeight = 54;
  static const double panelHeight = 220;
  static const double inputActionSize = 28;

  static const TextStyle headerTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  /// 群聊对方昵称：小号灰色辅助信息，不抢视觉。
  static TextStyle get groupChatSenderName => TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: Colors.grey.shade600,
      );

  static const TextStyle messageText = TextStyle(
    fontSize: 16,
    height: 1.35,
    color: textPrimary,
  );

  static const TextStyle tipsText = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );
}
