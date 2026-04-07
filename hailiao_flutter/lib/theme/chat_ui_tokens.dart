import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';

class ChatUiTokens {
  ChatUiTokens._();

  static const Color pageBackground = UiTokens.backgroundGray;
  static const Color surface = CommonTokens.surfacePrimary;
  static const Color softSurface = CommonTokens.softSurface;
  static const Color elevatedSurface = CommonTokens.elevatedSurface;
  static const Color border = CommonTokens.borderColor;
  static const Color divider = CommonTokens.dividerColor;
  static const Color mutedText = CommonTokens.textSecondary;
  static const Color subtleText = CommonTokens.textTertiary;
  static const Color info = CommonTokens.info;
  static const Color warning = CommonTokens.warning;
  static const Color selected = Color(0xFFE8F0FF);
  static const Color highlight = Color(0xFFFFF6DD);

  /// 己方气泡：微信式浅绿底 + 深色正文。
  static const Color outgoingBubble = Color(0xFF95EC69);
  static const Color outgoingBubbleText = Color(0xFF111111);
  static const Color incomingBubble = Color(0xFFFFFFFF);
  /// 对方气泡正文（微信式近黑）。
  static const Color incomingBubbleText = Color(0xFF111111);
  static const Color incomingBubbleBorder = CommonTokens.borderColor;
  static const Color systemMessageBg = Color(0xFFF2F5F9);
  static const Color systemMessageText = CommonTokens.textTertiary;
  /// 绿气泡内时间、√ 等弱信息（半透明黑，贴近微信）。
  static const Color outgoingMetaText = Color(0x99000000);
  static const Color incomingMetaText = Color(0xFF9B9B9B);
  /// 绿气泡内 √ 图标略浅于时间字。
  static const Color outgoingCheckIconColor = Color(0x66000000);
  static const Color replyPanelIncoming = Color(0xFFF4F7FB);
  static const Color replyPanelOutgoing = Color(0xFFDCF4C9);
  static const Color replyAccentIncoming = Color(0xFFCAD4E3);
  static const Color replyAccentOutgoing = Color(0xFF7BC06A);
  static const Color bubbleFlagIncoming = Color(0xFFF3F6FA);
  static const Color bubbleFlagOutgoing = Color(0xFF6BB85A);
  static const Color fileCardIncoming = Color(0xFFF5F7FA);
  static const Color fileCardOutgoing = Color(0xFF82D45A);
  static const Color fileCardBorder = CommonTokens.borderColor;
  static const Color fileCardIconBackgroundIncoming = Color(0xFFE8EEF7);
  static const Color fileCardIconBackgroundOutgoing = Color(0xFF6BC450);
  static const Color fileCardIconIncoming = Color(0xFF5A6B84);
  static const Color fileCardIconOutgoing = Color(0xFFFFFFFF);
  static const Color audioCardIncoming = Color(0xFFF5F7FA);
  static const Color audioCardOutgoing = Color(0xFF82D45A);
  static const Color audioTrackIncoming = Color(0xFFCCD6E3);
  static const Color audioTrackOutgoing = Color(0xFFB8E8A8);
  static const Color mediaLabelBackground = Color(0xB3141A24);
  static const Color mediaLabelText = Colors.white;

  static const Color mediaHighlightSurface = Color(0xFFFFFBEB);
  static const Color mediaPeerSurface = Color(0xFFF3F5F8);
  static const Color mediaSelfSurface = Color(0xFF95EC69);
  static const Color mediaPlaceholderBackground = CommonTokens.softSurface;
  static const Color mediaPlaceholderIcon = CommonTokens.textTertiary;

  static const Color searchChipBackground = CommonTokens.surfacePrimary;
  static const Color searchChipBorder = CommonTokens.borderColor;
  static const Color searchChipText = CommonTokens.textSecondary;

  static final TextStyle chatHeaderTitleText = CommonTokens.body.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );
  static final TextStyle chatHeaderSubtitleText =
      CommonTokens.caption.copyWith(
    fontSize: 12,
    color: CommonTokens.textTertiary,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );
  static const TextStyle forwardChipTextStyle = CommonTokens.caption;
  static const TextStyle replyPreviewTextStyle = CommonTokens.bodySmall;

  /// 时间 + √ 行：字号 / 图标 / 时间与勾间距（紧凑 meta 行）。
  static const double metaFontSize = 10.5;
  static const double metaIconSize = 13;
  static const double metaTimeReceiptGap = 1;

  /// 单行短文本 + inline meta 同排：正文与时间/√ 间距（约 3~4dp，紧凑可读）。
  static const double outgoingSingleLineBodyToMetaGap = 2;

  /// 单行同排在 [ChatOutgoingTextBubbleBody] 内模拟「更紧气泡左右 padding」：
  /// 相对 [outgoingTextBubblePadding] 左右各吃进约 2（12→10、10→8）。
  static const double outgoingSingleLineInlineBleedLeft = 2;
  static const double outgoingSingleLineInlineBleedRight = 2;

  /// 判定「单行可与 meta 同排」时的 meta 宽度上限（紧凑时间+勾经验值），
  /// 避免沿用 [chatOutgoingInlineMetaReserveWidth] 导致误判走 Stack 全宽。
  static const double outgoingSingleLineInlineMetaWidthBudget = 34;

  /// 正文气泡（非系统）字号与行高，贴近微信。
  static const double messageTextFontSize = 17;
  static const double messageTextHeight = 1.32;

  /// 己方文本与 inline meta 同排时，为尾侧 meta 预留宽度（时间 + 间距 + 勾）。
  static const double chatOutgoingInlineMetaReserveWidth = 40;

  static final TextStyle messageMetaTextStyle = CommonTokens.caption.copyWith(
    fontSize: metaFontSize,
    color: incomingMetaText,
    height: 1.05,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle fileTitleTextStyle = CommonTokens.body;
  static const TextStyle fileSubtitleTextStyle = CommonTokens.caption;
  static const TextStyle audioTitleTextStyle = CommonTokens.body;
  static const TextStyle audioSubtitleTextStyle = CommonTokens.caption;
  static const TextStyle systemMessageTextStyle = CommonTokens.bodySmall;

  /// 群聊发送者昵称（弱于正文；区别于时间分隔与系统提示）。
  static final TextStyle groupSenderNameTextStyle =
      CommonTokens.caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: subtleText,
  );

  /// 昵称底边与气泡顶部的间距。
  static const double groupSenderNameToBubbleGap = 3;

  /// 昵称相对内容左缘微内收（仅群聊昵称行）。
  static const double groupSenderNameLeftInset = 2;

  /// 时间分隔条上下留白。
  static const double timelineSeparatorVerticalPadding = 16;

  static const Color timeSeparatorText = CommonTokens.textTertiary;
  static const Color timeSeparatorBackground = Color(0xFFF1F4F8);
  static const Color timeSeparatorLine = CommonTokens.dividerColor;
  static const Color timeSeparatorBorder = CommonTokens.borderColor;
  static final TextStyle timeSeparatorTextStyle =
      CommonTokens.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: Color(0xFFBDBDBD),
  );

  static const Color headerContextText = CommonTokens.textTertiary;
  static const Color headerStatusOnline = CommonTokens.success;
  static const Color headerStatusIdle = Color(0xFF9AA6B6);
  static const Color headerContextChipBackground = Color(0xFFF1F4F8);
  static const Color headerContextChipText = CommonTokens.textSecondary;

  static const Color statusBannerBackground = Color(0xFFF8FAFD);
  static const Color statusBannerBorder = CommonTokens.borderColor;
  static const Color statusBannerTitle = CommonTokens.textPrimary;
  static const Color statusBannerSubtitle = CommonTokens.textSecondary;
  static const Color statusBannerIcon = Color(0xFF728197);
  static const Color statusBannerInfoBackground = Color(0xFFF4F7FC);
  static const Color statusBannerInfoBorder = Color(0xFFDDE6F4);
  static const Color statusBannerInfoIcon = CommonTokens.info;
  static const Color statusBannerWarningBackground = Color(0xFFFFF7EB);
  static const Color statusBannerWarningBorder = Color(0xFFF4D9A8);
  static const Color statusBannerWarningIcon = Color(0xFFB7791F);
  static const Color statusBannerSuccessBackground = Color(0xFFF1FAF5);
  static const Color statusBannerSuccessBorder = Color(0xFFCDE8D7);
  static const Color statusBannerSuccessIcon = CommonTokens.success;

  static const TextStyle headerContextTextStyle = CommonTokens.caption;
  static const TextStyle statusBannerTitleTextStyle = CommonTokens.bodySmall;
  static const TextStyle statusBannerSubtitleTextStyle = CommonTokens.caption;

  static const Color inputBarBackground = Color(0xFFF5F6F8);
  static const Color inputBarBorder = CommonTokens.lineSubtle;
  /// 输入框填充（微信式浅灰、无描边感）。
  static const Color inputFieldFill = Color(0xFFF5F5F5);
  static const Color inputFieldBackground = inputFieldFill;
  static const Color inputFieldBorder = Color(0x00000000);
  static const Color inputFieldHintText = CommonTokens.textTertiary;
  static const Color inputActionBackground = CommonTokens.surfacePrimary;
  static const Color inputActionBorder = CommonTokens.borderColor;
  static const Color inputActionIcon = CommonTokens.textSecondary;
  /// 有输入时：微信式发送绿。
  static const Color sendButtonBackground = Color(0xFF07C160);
  static const Color sendButtonDisabledBackground = Color(0xFFE8E8E8);
  static const Color sendButtonIcon = Colors.white;
  static const Color sendButtonDisabledIcon = Color(0xFF9E9E9E);

  static const double radiusXs = ImDesignTokens.radiusSm;
  static const double radiusSm = ImDesignTokens.radiusSm;
  static const double radiusMd = ImDesignTokens.radiusMd;
  static const double radiusLg = ImDesignTokens.radiusLg;
  static const double mediaRadius = radiusSm;
  static const double mediaRadiusMd = radiusMd;
  static const double messageContentGap = CommonTokens.xs;
  static const double replyAccentWidth = 3;
  static const double forwardChipBottomGap = CommonTokens.xs;

  /// 页水平边距（聊天列表左右与页面节奏统一用此值）。
  static const double pageHorizontalPadding = 12;

  /// 文本气泡内边距（长文更紧凑）。
  static const EdgeInsets outgoingTextBubblePadding =
      EdgeInsets.fromLTRB(12, 8, 10, 8);
  static const EdgeInsets incomingTextBubblePadding =
      EdgeInsets.fromLTRB(12, 8, 12, 8);
  static const EdgeInsets mediaBubblePadding = EdgeInsets.all(3);
  /// 图片消息右下角时间/状态叠字区（Telegram 式半透明底）。
  static const EdgeInsets imageMessageOverlayMetaPadding =
      EdgeInsets.symmetric(horizontal: 6, vertical: 3);
  static const double imageMessageOverlayBackgroundRadius = 8;
  static const EdgeInsets fileAudioBubblePadding =
      EdgeInsets.fromLTRB(10, 8, 10, 8);
  /// notice / 未显式分类时的兜底。
  static const EdgeInsets bubbleDefaultFallbackPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 8);
  /// 正文与 Meta 行间距（弱尾信息，略分开主内容）。
  static const double bubbleContentToMetaGap = 6;
  static const double bubbleMaxWidthFactor = 0.72;
  /// 二屏上限，避免超宽；常规手机以 [bubbleMaxWidthFactor] 为准。
  static const double bubbleMaxWidth = 560;
  /// 短气泡最小宽度（避免过小难以点击）。
  static const double outgoingBubbleMinWidth = 36;
  static const double incomingBubbleMinWidth = 34;
  static const double bubbleFooterGap = 2;
  /// 微信式大圆角 + 尾侧小圆角。
  static const double bubbleRadiusMain = 16;
  static const double bubbleRadiusTail = 6;
  static const double imageMessageMaxWidth = 200;
  static const double imageMessageMinWidth = 148;
  static const double imageMessageMaxHeight = 220;
  static const double videoMessageHeight = 132;
  static const double fileCardMinWidth = 196;
  static const double audioCardMinWidth = 168;
  /// 消息行纵向间距（单条与单条之间）。
  static const double messageRowVerticalPadding = 7;
  /// 头像与气泡的间距（单聊/群聊对方侧）。
  static const double messageRowHorizontalGap = 6;
  /// 己方消息：气泡与右侧头像间距。
  static const double messageRowOutgoingAvatarGap = 6;
  static const double messageAvatarSize = 36;
  static const double inputActionSize = ImDesignTokens.heightInput;
  /// 与主发送控件最小高度对齐（部分组件仍用方形触控区域）。
  static const double sendButtonSize = ImDesignTokens.heightButton;
  static const double composerHorizontalGap = ImDesignTokens.spaceSm;
  /// 与 [pageBackground] 同色（不引用 [pageBackground]，避免个别编译/常量顺序导致的异常）。
  /// 与聊天底色同系，避免顶栏「白切块」。
  static const Color chatAppBarBackground = pageBackground;
  static const double inputFieldMaxLines = 4;
  static const double inputFieldMinHeight = 38;
  static const double inputFieldRadius = 18;
  static const double sendButtonBorderRadius = 18;
  static const double mediaAttachSheetRadius = 14;
  static const Color mediaAttachSheetBackground = CommonTokens.surfacePrimary;
  static const Color mediaAttachSheetHandle = Color(0xFFE1E4E8);
  static const Color mediaAttachIconWell = Color(0xFFF5F6F8);
  static const Color mediaAttachIcon = Color(0xFF3D3D3D);
  static const double inputBarMaxWidth = 900;
  static const double messageContentMaxWidth = 900;
  static const double headerMaxWidth = 920;
  static const double statusBannerMaxWidth = 900;
  static const double topSectionSpacing = CommonTokens.sm;
  static const double messageListTopSpacing = CommonTokens.xs;
  static const double messageListBottomSpacing = CommonTokens.sm;

  /// 聊天顶栏高度（微信式偏紧凑）。
  static const double appBarToolbarHeight = 46;

  static const Color currentUserAvatarBackground = CommonTokens.brandSoft;
  static const Color currentUserAvatarBorder = Color(0xFFD6E0FF);
  static const Color currentUserAvatarIcon = CommonTokens.brandBlue;
  static const Color peerAvatarBackground = Color(0xFFF1F4F8);
  static const Color peerAvatarBorder = CommonTokens.borderColor;
  static const Color peerAvatarIcon = Color(0xFF6B7686);

  static const List<BoxShadow> surfaceShadow = CommonTokens.shadowNone;
}
