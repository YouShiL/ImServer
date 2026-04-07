import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';

/// 产品级统一对话框：内边距 16、圆角 16；底部 [取消] [确认] 右对齐。
class ImDialog extends StatelessWidget {
  const ImDialog({
    super.key,
    required this.title,
    this.child,
    this.message,
    this.cancelLabel = '取消',
    this.confirmLabel = '确认',
    this.onCancel,
    this.onConfirm,
    this.confirmBusy = false,
    this.destructive = false,
  });

  final String title;
  final Widget? child;
  final String? message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool confirmBusy;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(ImDesignTokens.imDialogRadius),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        title,
        style: CommonTokens.title.copyWith(
          fontSize: 17,
          color: CommonTokens.textPrimary,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        ImDesignTokens.imDialogPadding,
        ImDesignTokens.imDialogPadding,
        ImDesignTokens.imDialogPadding,
        ImDesignTokens.spaceSm,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        ImDesignTokens.imDialogPadding,
        ImDesignTokens.spaceSm,
        ImDesignTokens.imDialogPadding,
        ImDesignTokens.spaceSm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        ImDesignTokens.imDialogPadding,
        ImDesignTokens.spaceSm,
        ImDesignTokens.imDialogPadding,
        ImDesignTokens.imDialogPadding,
      ),
      actionsAlignment: MainAxisAlignment.end,
      content: child ??
          (message != null
              ? Text(
                  message!,
                  style: CommonTokens.body.copyWith(
                    color: CommonTokens.textSecondary,
                  ),
                )
              : const SizedBox.shrink()),
      actions: <Widget>[
        TextButton(
          onPressed: confirmBusy ? null : onCancel,
          child: Text(
            cancelLabel,
            style: CommonTokens.body.copyWith(
              color: CommonTokens.textSecondary,
            ),
          ),
        ),
        FilledButton(
          style: destructive ? UiTokens.filledDanger() : UiTokens.filledPrimary(),
          onPressed: confirmBusy ? null : onConfirm,
          child: confirmBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(confirmLabel),
        ),
      ],
    );
  }
}
