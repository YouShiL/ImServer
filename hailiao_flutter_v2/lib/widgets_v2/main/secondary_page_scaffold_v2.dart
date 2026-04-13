import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class SecondaryPageScaffoldV2 extends StatelessWidget {
  const SecondaryPageScaffoldV2({
    super.key,
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
    /// 为 `false` 时不在 body 底部加 SafeArea，避免与 IME + 底部输入条内 SafeArea 叠加重算导致键盘不上推。
    /// 聊天页等对键盘敏感场景可设为 `false`，由子组件自行处理底部安全区。
    this.safeAreaBottom = true,
    this.onTitleTap,
    this.titleLeading,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;
  final bool safeAreaBottom;
  final VoidCallback? onTitleTap;
  final Widget? titleLeading;

  Widget _buildTitle(BuildContext context) {
    final TextStyle style = ChatV2Tokens.headerTitle;
    final Widget text = Text(
      title,
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
    final Widget core = titleLeading == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              titleLeading!,
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 140,
                ),
                child: text,
              ),
            ],
          );
    if (onTitleTap == null) {
      return core;
    }
    return InkWell(
      onTap: onTitleTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: core,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: ChatV2Tokens.headerBackground,
        titleSpacing: 0,
        toolbarHeight: ChatV2Tokens.headerHeight + 6,
        title: _buildTitle(context),
        actions: actions.isEmpty
            ? const <Widget>[SizedBox(width: 12)]
            : <Widget>[
                ...actions,
                const SizedBox(width: 4),
              ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: ColoredBox(
        color: ChatV2Tokens.pageBackground,
        child: SafeArea(
          top: false,
          bottom: safeAreaBottom,
          child: child,
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
