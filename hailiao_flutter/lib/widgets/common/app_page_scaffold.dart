import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/call_incoming_listener.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.safeArea = true,
    this.bottom,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool safeArea;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: CommonTokens.space16),
            child: child,
          ),
        ),
        if (bottom case final Widget bottomWidget) bottomWidget,
      ],
    );

    return CallIncomingListener(
      child: Scaffold(
        backgroundColor: backgroundColor ?? CommonTokens.pageBackground,
        body: safeArea ? SafeArea(child: content) : content,
      ),
    );
  }
}
