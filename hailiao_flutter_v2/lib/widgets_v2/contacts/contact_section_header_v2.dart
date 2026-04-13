import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_section_header_v2.dart';

class ContactSectionHeaderV2 extends StatelessWidget {
  const ContactSectionHeaderV2({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return PrimarySectionHeaderV2(title: title);
  }
}
