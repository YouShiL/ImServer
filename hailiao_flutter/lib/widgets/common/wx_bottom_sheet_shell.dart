import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 弹出微信式底部面板（透明底、统一遮罩与外壳）；独立顶层函数，避免与 SDK `open` 符号冲突。
Future<T?> wxShowBottomSheetShell<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  bool showDragHandle = true,
  EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
  bool showCancelAction = false,
  String cancelText = '取消',
  VoidCallback? onCancel,
  bool isScrollControlled = false,
  bool useHorizontalMargin = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: WxBottomSheetShell.barrierColor,
    builder: (BuildContext sheetContext) {
      final double bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
      final double hMargin = useHorizontalMargin ? 8 : 0;
      final Widget shell = WxBottomSheetShell(
        title: title,
        showDragHandle: showDragHandle,
        contentPadding: contentPadding,
        showCancelAction: showCancelAction,
        cancelText: cancelText,
        onCancel: onCancel ??
            () {
              Navigator.pop(sheetContext);
            },
        child: child,
      );
      return Padding(
        padding: EdgeInsets.only(
          left: hMargin,
          right: hMargin,
          bottom: (useHorizontalMargin ? 8 : 0) + bottom,
        ),
        child: shell,
      );
    },
  );
}

/// 微信式底部面板外壳：透明背景、统一遮罩、圆角白底、拖手、安全区、可选标题与取消条。
class WxBottomSheetShell extends StatelessWidget {
  const WxBottomSheetShell({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.contentPadding = EdgeInsets.zero,
    this.showCancelAction = false,
    this.cancelText = '取消',
    this.onCancel,
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;
  final EdgeInsetsGeometry contentPadding;
  final bool showCancelAction;
  final String cancelText;
  final VoidCallback? onCancel;

  static Color get barrierColor => Colors.black.withValues(alpha: 0.38);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: ChatUiTokens.mediaAttachSheetBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ChatUiTokens.mediaAttachSheetRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showDragHandle) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ChatUiTokens.mediaAttachSheetHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (title != null && title!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title!.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: contentPadding,
                child: child,
              ),
            ],
          ),
        ),
        if (showCancelAction) ...<Widget>[
          const SizedBox(height: 8),
          Material(
            color: ChatUiTokens.mediaAttachSheetBackground,
            borderRadius: BorderRadius.circular(
              ChatUiTokens.mediaAttachSheetRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onCancel ?? () => Navigator.maybePop(context),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: Center(
                  child: Text(
                    cancelText,
                    style: CommonTokens.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: CommonTokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
