import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_list_item_v2.dart';

class ProfileActionTileV2 extends StatelessWidget {
  const ProfileActionTileV2({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return PrimaryListItemV2(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      showDivider: showDivider,
      leading: leading == null
          ? null
          : Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                leading,
                color: ChatV2Tokens.textSecondary,
              ),
            ),
      trailing: const Icon(
        Icons.chevron_right,
        color: ChatV2Tokens.textSecondary,
      ),
    );
  }
}
