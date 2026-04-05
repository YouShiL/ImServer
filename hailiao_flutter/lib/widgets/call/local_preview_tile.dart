import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class LocalPreviewTile extends StatelessWidget {
  const LocalPreviewTile({
    super.key,
    this.label = '你',
    this.cameraOff = false,
  });

  final String label;
  final bool cameraOff;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CallUiTokens.localPreviewWidth,
      height: CallUiTokens.localPreviewHeight,
      decoration: BoxDecoration(
        color: CallUiTokens.localPreviewBackground,
        borderRadius: BorderRadius.circular(CommonTokens.lgRadius),
        border: Border.all(color: CallUiTokens.localPreviewBorder),
        boxShadow: CallUiTokens.localPreviewShadow,
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CommonTokens.lgRadius),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF2A3950),
                      Color(0xFF171E29),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    cameraOff ? Icons.videocam_off_rounded : Icons.person_rounded,
                    color: Colors.white.withValues(alpha: 0.84),
                    size: cameraOff ? 28 : 40,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: CommonTokens.xs,
            right: CommonTokens.xs,
            bottom: CommonTokens.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CommonTokens.xs,
                vertical: CommonTokens.xxs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CallUiTokens.callWeakTextStyleOnDark.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
