import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';

class ConversationEmptyState extends StatelessWidget {
  const ConversationEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ConversationUiTokens.softSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 32,
                color: ConversationUiTokens.subtleText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (detail != null && detail!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: ConversationUiTokens.mutedText,
                ),
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}