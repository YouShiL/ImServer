import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_list_item_v2.dart';

class ContactListItemV2 extends StatelessWidget {
  const ContactListItemV2({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PrimaryListItemV2(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFD6DCE3),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title.isEmpty ? '?' : title.substring(0, 1),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ChatV2Tokens.textPrimary,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: ChatV2Tokens.textSecondary,
      ),
    );
  }
}
