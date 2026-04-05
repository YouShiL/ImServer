import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class CallUiTokens {
  CallUiTokens._();

  static const Color audioCallBackground = Color(0xFFF3F6FD);
  static const Color audioCallAccent = Color(0xFFE7EEFF);
  static const Color audioCallHalo = Color(0x66DCE7FF);
  static const Color videoCallBackground = Color(0xFF0E141D);
  static const Color videoCallOverlayBackground = Color(0x8C111A27);
  static const Color callSurface = Color(0xFFFFFFFF);
  static const Color callSoftSurface = Color(0xFFF7F9FC);
  static const Color callSoftBorder = Color(0x1FFFFFFF);
  static const Color callSoftBorderLight = Color(0xFFE3EAF4);
  static const Color callTextPrimary = CommonTokens.textPrimary;
  static const Color callTextOnDark = Colors.white;
  static const Color callSubtitleText = CommonTokens.textSecondary;
  static const Color callWeakText = CommonTokens.textTertiary;
  static const Color callStatusText = CommonTokens.brandBlue;
  static const Color callDurationText = CommonTokens.textSecondary;

  static const Color controlButtonBackground = Color(0x16FFFFFF);
  static const Color controlButtonBackgroundLight = Color(0xFFF7F9FC);
  static const Color controlButtonActiveBackground = Color(0xFFE8F0FF);
  static const Color controlButtonMutedBackground = Color(0xFFFDEDEE);
  static const Color controlButtonBorder = Color(0x22FFFFFF);
  static const Color controlButtonBorderLight = CommonTokens.borderColor;
  static const Color controlButtonActiveBorder = Color(0xFFCBD9FF);
  static const Color controlButtonMutedBorder = Color(0xFFF5C4CA);
  static const Color endCallButtonBackground = Color(0xFFE04F5F);
  static const Color controlIconColor = Colors.white;
  static const Color controlIconColorLight = CommonTokens.textPrimary;
  static const Color endCallIconColor = Colors.white;

  static const Color videoTileBackground = Color(0xFF172131);
  static const Color videoTileBorder = Color(0x24FFFFFF);
  static const Color videoTileInnerGlow = Color(0x0FFFFFFF);
  static const Color localPreviewBackground = Color(0xFF212D3F);
  static const Color localPreviewBorder = Color(0x33FFFFFF);
  static const Color avatarRing = Color(0xFFFFFFFF);

  static const TextStyle callTitleText = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: CommonTokens.textPrimary,
    height: 1.18,
    letterSpacing: 0.1,
  );

  static const TextStyle callTitleTextOnDark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle callSubtitleTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: CommonTokens.textSecondary,
    height: 1.4,
  );

  static const TextStyle callStatusTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: CommonTokens.brandBlue,
    height: 1.25,
  );

  static const TextStyle callDurationTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: CommonTokens.textSecondary,
    height: 1.3,
  );

  static const TextStyle callWeakTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: CommonTokens.textTertiary,
    height: 1.35,
  );

  static const TextStyle callWeakTextStyleOnDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xCCFFFFFF),
    height: 1.35,
  );

  static const double callPageMaxWidth = 860;
  static const double controlBarSpacing = CommonTokens.md;
  static const double avatarSize = 118;
  static const double localPreviewWidth = 116;
  static const double localPreviewHeight = 162;
  static const double headerSpacing = CommonTokens.md;
  static const double statusSpacing = CommonTokens.xs;
  static const double pagePadding = CommonTokens.xl;
  static const double controlButtonSize = 64;
  static const double smallControlButtonSize = 56;
  static const double bottomControlPadding = CommonTokens.xl;
  static const double controlLabelGap = 10;
  static const double videoTopOverlayPadding = CommonTokens.md;
  static const double audioPanelMaxWidth = 440;

  static const List<BoxShadow> audioCardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x14081117),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> localPreviewShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x2A081117),
      blurRadius: 24,
      offset: Offset(0, 14),
    ),
  ];
}
