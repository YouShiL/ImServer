import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ProfileHeaderV2 extends StatelessWidget {
  const ProfileHeaderV2({
    super.key,
    required this.displayName,
    required this.subtitle,
  });

  final String displayName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChatV2Tokens.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFD7DBE0),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              displayName.isEmpty ? '?' : displayName.substring(0, 1),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: ChatV2Tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: ChatV2Tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ChatV2Tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.qr_code_2,
            color: ChatV2Tokens.textSecondary,
          ),
        ],
      ),
    );
  }
}
