import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_section_header_v2.dart';

class ProfileSectionV2 extends StatelessWidget {
  const ProfileSectionV2({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null) ...<Widget>[
          PrimarySectionHeaderV2(title: title!),
        ],
        Container(
          color: ChatV2Tokens.surface,
          child: Column(children: children),
        ),
      ],
    );
  }
}
