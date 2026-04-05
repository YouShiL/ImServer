import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

class ChatSelectionSummaryBar extends StatelessWidget {
  const ChatSelectionSummaryBar({
    super.key,
    required this.selectedCount,
    required this.summaryText,
  });

  final int selectedCount;
  final String summaryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        border: Border(bottom: BorderSide(color: Color(0xFFBFDBFE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '已选择 $selectedCount 条',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summaryText,
            style: const TextStyle(
              fontSize: 12,
              color: ChatUiTokens.info,
            ),
          ),
        ],
      ),
    );
  }
}
