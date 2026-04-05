import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/call_incoming_listener.dart';

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
        backgroundColor: ChatUiTokens.pageBackground,
        body: SafeArea(
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
