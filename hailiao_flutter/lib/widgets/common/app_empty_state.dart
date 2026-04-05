import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/common/empty_state_view.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.detail,
  });

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: icon,
      title: text,
      detail: detail,
    );
  }
}
