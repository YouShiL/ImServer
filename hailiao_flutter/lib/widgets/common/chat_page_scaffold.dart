import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/call_incoming_listener.dart';

/// 聊天页骨架：SafeArea(bottom: false) + Column([header], Expanded(body), [composer])。
/// 键盘随 [resizeToAvoidBottomInset] 整体上移，不用 Stack 浮层盖在列表上。
class ChatPageScaffold extends StatelessWidget {
  const ChatPageScaffold({
    super.key,
    this.header,
    required this.body,
    this.inputBar,
  });

  final Widget? header;
  final Widget body;
  final Widget? inputBar;

  @override
  Widget build(BuildContext context) {
    final List<Widget> headerChildren = header == null
        ? const <Widget>[]
        : <Widget>[header!];
    final List<Widget> footerChildren = inputBar == null
        ? const <Widget>[]
        : <Widget>[
            SafeArea(
              top: false,
              child: inputBar!,
            ),
          ];
    return CallIncomingListener(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: ChatUiTokens.pageBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              ...headerChildren,
              Expanded(child: body),
              ...footerChildren,
            ],
          ),
        ),
      ),
    );
  }
}
