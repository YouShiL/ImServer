import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/common/wx_search_bar.dart';

/// 会话等场景统一搜索条：委托 [WxSearchBar]，保持既有入参。
class ImSearchBar extends StatelessWidget {
  const ImSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.showClear = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showClear;
  final bool enabled;

  static double get height => WxSearchBar.height;

  @override
  Widget build(BuildContext context) {
    return WxSearchBar(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onClear: onClear,
      showClear: showClear,
      enabled: enabled,
    );
  }
}
