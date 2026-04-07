import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_page_scaffold.dart';
import 'package:hailiao_flutter/widgets/common/app_surface.dart';

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.hero,
    required this.child,
    this.footer,
    this.wrapChildInSurface = true,
  });

  final Widget hero;
  final Widget child;
  final Widget? footer;

  /// 为 false 时表单区不再包一层白卡片（登录页等轻量 IM 场景）。
  final bool wrapChildInSurface;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      backgroundColor: AuthUiTokens.pageBackground,
      padding: const EdgeInsets.symmetric(horizontal: CommonTokens.space24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AuthUiTokens.formShellMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: CommonTokens.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: wrapChildInSurface
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: <Widget>[
                        hero,
                        SizedBox(
                          height: wrapChildInSurface
                              ? CommonTokens.xl
                              : CommonTokens.space20,
                        ),
                        if (wrapChildInSurface)
                          AppSurface(
                            backgroundColor: AuthUiTokens.surface,
                            borderRadius: AuthUiTokens.cardRadius,
                            padding: const EdgeInsets.all(CommonTokens.space24),
                            child: child,
                          )
                        else
                          child,
                        if (footer != null) ...<Widget>[
                          const SizedBox(height: CommonTokens.lg),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
