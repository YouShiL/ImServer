import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class PrimarySectionHeaderV2 extends StatelessWidget {
  const PrimarySectionHeaderV2({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: ChatV2Tokens.pageBackground,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ChatV2Tokens.textSecondary,
        ),
      ),
    );
  }
}
