import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/call/call_control_button.dart';

class CallControlAction {
  const CallControlAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.destructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool destructive;
  final bool enabled;
}

class CallControlBar extends StatelessWidget {
  const CallControlBar({
    super.key,
    required this.actions,
    this.dark = false,
  });

  final List<CallControlAction> actions;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double spacing = compact
            ? CallUiTokens.controlBarSpacing - 4
            : CallUiTokens.controlBarSpacing;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (CallControlAction action) => CallControlButton(
                  icon: action.icon,
                  label: action.label,
                  onTap: action.onTap,
                  active: action.active,
                  destructive: action.destructive,
                  enabled: action.enabled && action.onTap != null,
                  dark: dark,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
