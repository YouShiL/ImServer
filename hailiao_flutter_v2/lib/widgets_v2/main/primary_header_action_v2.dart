import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class PrimaryHeaderActionV2 extends StatelessWidget {
  const PrimaryHeaderActionV2({
    super.key,
    required this.icon,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap ?? () {},
      splashRadius: 18,
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: ChatV2Tokens.textPrimary,
      ),
    );
  }
}
