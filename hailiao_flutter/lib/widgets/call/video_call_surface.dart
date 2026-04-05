import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class VideoCallSurface extends StatelessWidget {
  const VideoCallSurface({
    super.key,
    required this.title,
    this.subtitle,
    this.status,
    this.icon = Icons.videocam_outlined,
  });

  final String title;
  final String? subtitle;
  final String? status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CallUiTokens.videoTileBackground,
        borderRadius: BorderRadius.circular(CommonTokens.xlRadius),
        border: Border.all(color: CallUiTokens.videoTileBorder),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CommonTokens.xlRadius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF182232),
                    Color(0xFF101721),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CommonTokens.xlRadius),
                gradient: const RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: <Color>[
                    CallUiTokens.videoTileInnerGlow,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(CommonTokens.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: CommonTokens.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: CallUiTokens.callTitleTextOnDark,
                  ),
                  if (status != null && status!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: CommonTokens.xs),
                    Text(
                      status!,
                      style: CallUiTokens.callStatusTextStyle.copyWith(
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                  ],
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: CommonTokens.xs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: CallUiTokens.callWeakTextStyleOnDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
