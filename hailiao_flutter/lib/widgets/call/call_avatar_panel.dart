import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class CallAvatarPanel extends StatelessWidget {
  const CallAvatarPanel({
    super.key,
    required this.name,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final String trimmed = name.trim();
    final String initial = trimmed.isEmpty ? '嗨' : trimmed.substring(0, 1);
    return Container(
      width: CallUiTokens.avatarSize + 44,
      height: CallUiTokens.avatarSize + 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: <Color>[
            Color(0x99FFFFFF),
            Color(0x33FFFFFF),
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: CallUiTokens.audioCallHalo,
            blurRadius: 38,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CallUiTokens.audioCallAccent,
          border: Border.all(color: CallUiTokens.avatarRing, width: 6),
        ),
        child: CircleAvatar(
          radius: CallUiTokens.avatarSize / 2,
          backgroundColor: CommonTokens.brandSoft,
          backgroundImage: avatarUrl != null && avatarUrl!.trim().isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null || avatarUrl!.trim().isEmpty
              ? Text(
                  initial,
                  style: CommonTokens.headline.copyWith(
                    color: CommonTokens.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
