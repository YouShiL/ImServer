import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class PrimaryPageScaffoldV2 extends StatelessWidget {
  const PrimaryPageScaffoldV2({
    super.key,
    required this.child,
    this.topSpacing = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
  });

  final Widget child;
  final double topSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChatV2Tokens.pageBackground,
      child: Padding(
        padding: padding,
        child: Column(
          children: <Widget>[
            SizedBox(height: topSpacing),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
