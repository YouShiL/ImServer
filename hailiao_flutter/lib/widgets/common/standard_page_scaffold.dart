import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_page_scaffold.dart';

class StandardPageScaffold extends StatelessWidget {
  const StandardPageScaffold({
    super.key,
    this.header,
    this.searchBar,
    required this.body,
    this.bottom,
    this.padding,
    this.backgroundColor,
  });

  final Widget? header;
  final Widget? searchBar;
  final Widget body;
  final Widget? bottom;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      backgroundColor: backgroundColor ?? CommonTokens.pageBackground,
      padding: padding ?? EdgeInsets.zero,
      bottom: bottom,
      child: Column(
        children: <Widget>[
          if (header != null) header!,
          if (searchBar != null) ...<Widget>[
            const SizedBox(height: CommonTokens.space12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CommonTokens.space16,
              ),
              child: searchBar!,
            ),
          ],
          const SizedBox(height: CommonTokens.space12),
          Expanded(child: body),
        ],
      ),
    );
  }
}
