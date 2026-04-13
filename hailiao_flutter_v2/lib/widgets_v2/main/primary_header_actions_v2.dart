import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/primary_header_action_v2.dart';

class PrimaryHeaderActionsV2 extends StatelessWidget {
  const PrimaryHeaderActionsV2({
    super.key,
    required this.actions,
  });

  final List<PrimaryHeaderActionItemV2> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .map(
            (PrimaryHeaderActionItemV2 action) => PrimaryHeaderActionV2(
              icon: action.icon,
              tooltip: action.tooltip,
              onTap: action.onTap,
            ),
          )
          .toList(growable: false),
    );
  }
}

class PrimaryHeaderActionItemV2 {
  const PrimaryHeaderActionItemV2({
    required this.icon,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;
}
