import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_surface.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CommonTokens.space24),
        child: AppSurface(
          padding: const EdgeInsets.all(CommonTokens.space24),
          borderRadius: CommonTokens.radiusXl,
          backgroundColor: CommonTokens.surfaceMuted,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: CommonTokens.surfacePrimary,
                  borderRadius: BorderRadius.circular(CommonTokens.radiusLg),
                ),
                child: Icon(
                  icon,
                  color: CommonTokens.textTertiary,
                ),
              ),
              const SizedBox(height: CommonTokens.space16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: CommonTokens.section,
              ),
              if (detail != null && detail!.isNotEmpty) ...<Widget>[
                const SizedBox(height: CommonTokens.space8),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: CommonTokens.secondary,
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: CommonTokens.space16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
