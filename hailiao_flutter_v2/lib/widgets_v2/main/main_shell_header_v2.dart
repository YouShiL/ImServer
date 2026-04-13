import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class MainShellHeaderV2 extends StatelessWidget {
  const MainShellHeaderV2({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ChatV2Tokens.headerHeight + 14,
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 8),
      decoration: const BoxDecoration(
        color: ChatV2Tokens.headerBackground,
        border: Border(
          bottom: BorderSide(color: ChatV2Tokens.divider),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: ChatV2Tokens.headerTitle,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
